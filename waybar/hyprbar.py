#!/usr/bin/env python3
"""hyprbar: runs one waybar per monitor and drives it from Hyprland's IPC.

Autohide: every bar starts hidden (start_hidden). Resting the cursor in a
monitor's top-left corner shows that monitor's bar. Moving away hides it.
The config maps SIGUSR1 to "show" and SIGUSR2 to "hide", so each signal is
idempotent and the bar can't get out of sync the way a toggle can.

Workspaces: waybar 0.15's hyprland/workspaces sends legacy `dispatch workspace N`
commands, which a Lua-config Hyprland rejects, so clicks do nothing. This
process tracks workspace state from socket2 and writes one JSON file per
workspace. It then sends SIGRTMIN+WS_SIGNAL so the custom/wsN modules re-read
their file. Once a waybar release includes PR #5013, this half can go.

Peek: SIGUSR1 shows the focused monitor's bar for PEEK seconds, or hides it if it
is already shown. SUPER+W in hypr/keybinding.lua sends it.

Reload: SIGHUP restarts the bars. CSS reloads on its own.
Use the pid file rather than `pkill -f`, which would also hit an editor that has this file open:
    kill -HUP "$(cat "$XDG_RUNTIME_DIR/hyprbar/pid")"
"""

import fcntl
import json
import os
import selectors
import signal
import socket
import subprocess
import sys
import time
from pathlib import Path

CONFIG_DIR = Path.home() / ".config/waybar"
CONFIG = CONFIG_DIR / "config.jsonc"
STYLE = CONFIG_DIR / "style.css"
RUNTIME = Path(os.environ["XDG_RUNTIME_DIR"]) / "hyprbar"
HYPR = Path(os.environ["XDG_RUNTIME_DIR"]) / "hypr" / os.environ["HYPRLAND_INSTANCE_SIGNATURE"]

WS_COUNT = 6
WS_SIGNAL = 8           # must match "signal" of the custom/wsN modules

POLL = 0.08             # cursor sampling interval, seconds
CORNER = 8              # hot-corner size in logical px
BAR_ZONE = 64           # stays shown while the cursor is within this many px of the left edge
REVEAL_DWELL = 0.0      # how long to rest in the corner before showing
HIDE_DELAY = 0.5        # how long to stay away before hiding
PEEK = 4.0              # how long the shortcut shows the bar; hovering it keeps it open longer
SPAWN_GRACE = 1.5       # waybar dies on signals that arrive before it installs handlers
RESPAWN_EVERY = 5.0     # at most one restart per bar this often

WS_EVENTS = {
    "workspace", "workspacev2", "focusedmon", "focusedmonv2", "createworkspace",
    "createworkspacev2", "destroyworkspace", "destroyworkspacev2", "moveworkspace",
    "moveworkspacev2", "openwindow", "closewindow", "movewindow", "movewindowv2", "urgent",
}
MONITOR_EVENTS = {"monitoradded", "monitoraddedv2", "monitorremoved", "monitorremovedv2", "configreloaded"}


def hypr(cmd):
    """One request on Hyprland's command socket, without spawning hyprctl."""
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
        s.settimeout(1)
        s.connect(str(HYPR / ".socket.sock"))
        s.sendall(f"j/{cmd}".encode())
        chunks = []
        while data := s.recv(65536):
            chunks.append(data)
    return json.loads(b"".join(chunks))


def monitor_geometry():
    """name -> (x, y, w, h) in the logical coordinates that cursorpos uses."""
    geo = {}
    for m in hypr("monitors"):
        w, h = m["width"] / m["scale"], m["height"] / m["scale"]
        if m["transform"] % 2:
            w, h = h, w
        geo[m["name"]] = (m["x"], m["y"], w, h)
    return geo


def zone_of(cursor, geo):
    """Where the cursor is relative to this monitor's bar: corner, bar, or away."""
    x, y = cursor["x"] - geo[0], cursor["y"] - geo[1]
    if not (0 <= x < geo[2] and 0 <= y < geo[3]):
        return "away"
    if x <= CORNER and y <= CORNER:
        return "corner"
    if x <= BAR_ZONE:
        return "bar"
    return "away"


def want_visible(visible, zone, held):
    """Should the bar be shown? `held` is how long the cursor has been in `zone`.

    The corner reveals the bar, the bar's own strip keeps it open, and anywhere
    else hides it after a short delay. Leaving the strip only briefly, say on the
    way to a tooltip, doesn't make it flicker.
    """
    if zone == "corner":
        return visible or held >= REVEAL_DWELL
    if zone == "bar":
        return visible
    return visible and held < HIDE_DELAY


class Bar:
    def __init__(self, monitor):
        self.monitor = monitor
        self.proc = None
        self.started = 0.0
        self.visible = False
        self.ws_dirty = False
        self.peek_until = 0.0
        self.zone, self.zone_since = "away", time.monotonic()
        self.spawn()

    def spawn(self):
        cfg = RUNTIME / f"{self.monitor}.json"
        cfg.write_text(json.dumps({"include": [str(CONFIG)], "output": self.monitor}))
        self.proc = subprocess.Popen(["waybar", "-c", str(cfg), "-s", str(STYLE)],
                                     stdout=subprocess.DEVNULL)
        self.started = time.monotonic()
        self.visible = False
        self.ws_dirty = False

    def ready(self):
        return self.proc.poll() is None and time.monotonic() - self.started > SPAWN_GRACE

    def maintain(self):
        if self.proc.poll() is not None and time.monotonic() - self.started > RESPAWN_EVERY:
            print(f"hyprbar: waybar on {self.monitor} exited ({self.proc.returncode}), restarting",
                  file=sys.stderr)
            self.spawn()
        if self.ws_dirty and self.ready():
            self.proc.send_signal(signal.SIGRTMIN + WS_SIGNAL)
            self.ws_dirty = False

    def track(self, cursor, geo):
        zone = zone_of(cursor, geo)
        now = time.monotonic()
        if zone != self.zone:
            self.zone, self.zone_since = zone, now
        self.apply(want_visible(self.visible, zone, now - self.zone_since) or now < self.peek_until)

    def toggle_peek(self):
        if self.visible:
            self.peek_until = 0.0
            self.apply(False)
        else:
            self.peek_until = time.monotonic() + PEEK

    def apply(self, want):
        # Not ready yet: skip and let the next tick retry, since the state is level-triggered.
        if want != self.visible and self.ready():
            self.proc.send_signal(signal.SIGUSR1 if want else signal.SIGUSR2)
            self.visible = want

    def stop(self):
        self.proc.terminate()
        try:
            self.proc.wait(2)
        except subprocess.TimeoutExpired:
            self.proc.kill()


class Workspaces:
    def __init__(self):
        self.urgent = set()
        self.dir = RUNTIME / "ws"
        self.dir.mkdir(parents=True, exist_ok=True)

    def mark_urgent(self, address):
        for c in hypr("clients"):
            if c["address"] == f"0x{address}":
                self.urgent.add(c["workspace"]["id"])

    def write(self):
        monitors = hypr("monitors")
        windows = {w["id"]: w["windows"] for w in hypr("workspaces")}
        shown = {m["activeWorkspace"]["id"] for m in monitors}
        focused = next((m["activeWorkspace"]["id"] for m in monitors if m["focused"]), None)
        self.urgent -= shown
        for n in range(1, WS_COUNT + 1):
            classes = ["ws"]
            if n == focused:
                classes.append("active")
            elif n in shown:
                classes.append("visible")
            if windows.get(n):
                classes.append("occupied")
            if n in self.urgent:
                classes.append("urgent")
            count = windows.get(n, 0)
            state = {"text": str(n), "class": classes,
                     "tooltip": f"Workspace {n} · {count} window{'s' * (count != 1)}"}
            tmp = self.dir / f".{n}.tmp"
            tmp.write_text(json.dumps(state))
            tmp.replace(self.dir / f"{n}.json")  # atomic, so waybar never reads half a file


def main():
    RUNTIME.mkdir(parents=True, exist_ok=True)
    pidfile = open(RUNTIME / "pid", "a+")  # not "w": that would truncate a running instance's pid
    try:
        fcntl.flock(pidfile, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        sys.exit("hyprbar: already running")
    pidfile.truncate(0)
    pidfile.write(f"{os.getpid()}\n")
    pidfile.flush()

    running, restart, peek = True, False, False

    def on_term(*_):
        nonlocal running
        running = False

    def on_hup(*_):
        nonlocal restart
        restart = True

    def on_peek(*_):
        nonlocal peek
        peek = True

    signal.signal(signal.SIGTERM, on_term)
    signal.signal(signal.SIGINT, on_term)
    signal.signal(signal.SIGHUP, on_hup)
    signal.signal(signal.SIGUSR1, on_peek)

    events = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    events.connect(str(HYPR / ".socket2.sock"))
    events.setblocking(False)
    sel = selectors.DefaultSelector()
    sel.register(events, selectors.EVENT_READ)

    ws = Workspaces()
    ws.write()  # before spawning, so the modules' first read finds a file
    geo = monitor_geometry()
    bars = {name: Bar(name) for name in geo}
    buf = b""
    geo_checked = time.monotonic()

    try:
        while running:
            ws_changed = monitors_changed = False
            if sel.select(POLL):
                data = events.recv(65536)
                if not data:
                    break  # Hyprland is gone
                buf += data
                *lines, buf = buf.split(b"\n")
                for line in lines:
                    name, _, arg = line.decode(errors="replace").partition(">>")
                    if name == "urgent":
                        ws.mark_urgent(arg)
                    ws_changed |= name in WS_EVENTS or name in MONITOR_EVENTS
                    monitors_changed |= name in MONITOR_EVENTS

            if restart:
                restart = False
                for bar in bars.values():
                    bar.stop()
                bars = {name: Bar(name) for name in geo}

            # The periodic check catches scale and position changes, which raise no event.
            if monitors_changed or time.monotonic() - geo_checked > 5:
                geo, geo_checked = monitor_geometry(), time.monotonic()
                for name in bars.keys() - geo.keys():
                    bars.pop(name).stop()
                for name in geo.keys() - bars.keys():
                    bars[name] = Bar(name)

            if peek:
                peek = False
                focused = next((m["name"] for m in hypr("monitors") if m["focused"]), None)
                if focused in bars:
                    bars[focused].toggle_peek()

            if ws_changed:
                ws.write()
                for bar in bars.values():
                    bar.ws_dirty = True

            cursor = hypr("cursorpos")
            for name, bar in bars.items():
                bar.maintain()
                bar.track(cursor, geo[name])
    except (ConnectionError, FileNotFoundError, socket.timeout) as e:
        print(f"hyprbar: lost Hyprland IPC: {e}", file=sys.stderr)
        sys.exit(1)  # nonzero so hyprbar.service restarts us; a stall during a modeset is not Hyprland exiting
    finally:
        for bar in bars.values():
            bar.stop()


if __name__ == "__main__":
    main()
