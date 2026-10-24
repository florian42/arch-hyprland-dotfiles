-- See https://wiki.hypr.land/Configuring/Basics/Binds/

local terminal    = "ghostty"
local fileManager = "nautilus"
local menu        = "wofi --show drun"
local browser     = "firefox --new-window"

local mainMod = "SUPER" -- Sets "Windows" key as main modifier

hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + M", hl.dsp.exit())
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())           -- dwindle
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))     -- dwindle
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("makoctl dismiss --all"))
-- Peek at waybar for a few seconds; press again to hide it (see ~/.config/waybar/hyprbar.py)
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd([[kill -USR1 "$(cat "$XDG_RUNTIME_DIR/hyprbar/pid")"]]))

local directions = { left = "l", right = "r", up = "u", down = "d" }
for key, dir in pairs(directions) do
    -- Move focus with mainMod + arrow keys
    hl.bind(mainMod .. " + " .. key,                hl.dsp.focus({ direction = dir }))
    -- Focus monitor with mainMod + CTRL + arrow keys
    hl.bind(mainMod .. " + CTRL + " .. key,         hl.dsp.focus({ monitor = dir }))
    -- Move window to monitor with mainMod + SHIFT + CTRL + arrow keys
    hl.bind(mainMod .. " + SHIFT + CTRL + " .. key, hl.dsp.window.move({ monitor = dir }))
end

-- Switch workspaces with mainMod + [1-6]
-- Move active window to a workspace with mainMod + SHIFT + [1-6]
for i = 1, 6 do
    hl.bind(mainMod .. " + " .. i,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end

-- Special workspace (scratchpad)
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Screenshots: window / monitor / region
hl.bind(mainMod .. " + PRINT", hl.dsp.exec_cmd("hyprshot -m window"))
hl.bind("PRINT",               hl.dsp.exec_cmd("hyprshot -m output"))
hl.bind("SHIFT + PRINT",       hl.dsp.exec_cmd("hyprshot -m region"))

-- Clipboard history picker
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd("cliphist list | wofi --dmenu | cliphist decode | wl-copy"))

-- Laptop multimedia keys for volume and LCD brightness
local lockedRepeat = { locked = true, repeating = true }
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), lockedRepeat)
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      lockedRepeat)
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     lockedRepeat)
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   lockedRepeat)
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  lockedRepeat)
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  lockedRepeat)

-- Requires playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- Lid switch: turn the laptop panel off/on without suspending; the MateView
-- stays on so the lid can be closed while docked.
-- dpms is deferred through a timer because dispatching it straight from a
-- keybind is undefined behavior (see the Dispatchers wiki page).
local function setDisplayPower(action)
    hl.timer(function()
        hl.dispatch(hl.dsp.dpms({ monitor = "eDP-1", action = action }))
    end, { timeout = 500, type = "oneshot" })
end

hl.bind("switch:on:Lid Switch",  function() setDisplayPower("disable") end, { locked = true })
hl.bind("switch:off:Lid Switch", function() setDisplayPower("enable") end,  { locked = true })
