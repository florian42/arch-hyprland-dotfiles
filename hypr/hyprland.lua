-- Hyprland Lua config. Refer to the wiki for more information.
-- https://wiki.hypr.land/Configuring/Start/

require("envs")
require("autostart")
require("keybinding")
require("windows")


------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- Auto-detect and configure all monitors
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})

-- Positions are explicit: auto placement depends on which monitor arrived
-- first and sticks across reloads, so a panel disable/enable cycle swapped
-- the two sides.

-- Laptop panel (1920x1080, 310mm wide, ~157 PPI). auto picks 1.5 -> 1280x720
-- logical, which feels cramped. 1.25 -> 1536x864 logical. Clean stops for
-- this panel: 1.2 (1600x900), 1.25, 1.333 (1440x810), 1.5.
local panel = "eDP-1"
local function panelRule(disabled)
    return {
        output   = panel,
        mode     = "preferred",
        position = "0x0",
        scale    = 1.25,
        disabled = disabled, -- rules merge, so enabling needs an explicit false
    }
end

-- Huawei MateView (28.2", 3840x2560 3:2, ~163 PPI).
-- Integer scale 2 -> 1920x1280 logical, ~81 effective PPI. Hyprland only
-- accepts clean divisors here: the stops are 1.6, 1.667 and 2. x = the
-- panel's logical width (1920 / 1.25), so it sits right of the panel.
local mateview = "desc:Huawei Technologies Co. Inc. MateView"
hl.monitor({
    output   = mateview,
    mode     = "3840x2560@60",
    position = "1536x0",
    scale    = 2,
})

-- Workspace layout: six fixed workspaces, 1-3 on the laptop panel and 4-6 on
-- the MateView. persistent keeps each one alive while empty so the set
-- never drifts; default marks the one each monitor falls back to. While the
-- panel is out of the layout 1-3 move to the MateView too: a persistent
-- workspace ruled onto a disabled monitor is recreated on no monitor at all.
local function assignWorkspaces(panelOn)
    for i = 1, 6 do
        hl.workspace_rule({
            workspace  = tostring(i),
            monitor    = (i <= 3 and panelOn) and panel or mateview,
            default    = i == 4 or (i == 1 and panelOn),
            persistent = true,
        })
    end
end

local function applyPanel(disabled)
    hl.monitor(panelRule(disabled))
    assignWorkspaces(not disabled)
end

-- Clamshell. Lid closed with another screen connected: take the panel out of
-- the layout, so workspaces 1-3 move to that screen. Lid closed with nothing
-- else: keep the panel as a dark output so the session never has zero
-- monitors. logind ignores the lid (HandleLidSwitch*=ignore), so no suspend.
local function lidClosed()
    local f = io.open("/proc/acpi/button/lid/LID/state")
    if not f then return false end
    local closed = f:read("a"):find("closed") ~= nil
    f:close()
    return closed
end

local function enabledOutputs()
    local names = {}
    for _, m in ipairs(hl.get_monitors()) do names[m.name] = true end
    return names
end

local function panelShouldBeDisabled(outputs)
    if not lidClosed() then return false end
    for name in pairs(outputs) do
        if name ~= panel then return true end
    end
    return false
end

applyPanel(panelShouldBeDisabled(enabledOutputs()))

-- Level-triggered: every trigger recomputes the target state from the lid and
-- the connected outputs, so a missed or repeated event can't leave it wrong.
local function syncPanel()
    local outputs = enabledOutputs()
    local disable = panelShouldBeDisabled(outputs)
    if disable ~= not outputs[panel] then
        applyPanel(disable)
    end
    if not disable then
        hl.dispatch(hl.dsp.dpms({ monitor = panel, action = lidClosed() and "disable" or "enable" }))
    end
end

-- Deferred: dpms straight from a keybind is undefined behavior (see the
-- Dispatchers wiki page), and the lid state file needs a moment to update.
local function scheduleSyncPanel()
    hl.timer(syncPanel, { timeout = 500, type = "oneshot" })
end

hl.bind("switch:on:Lid Switch",  scheduleSyncPanel, { locked = true })
hl.bind("switch:off:Lid Switch", scheduleSyncPanel, { locked = true })
hl.on("monitor.added",   scheduleSyncPanel)
hl.on("monitor.removed", scheduleSyncPanel)


-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Refer to https://wiki.hypr.land/Configuring/Basics/Variables/
hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 0,

        border_size = 2, -- colors come from noctalia, see the end of this file

        -- Set to true enable resizing windows by clicking and dragging on borders and gaps
        resize_on_border = false,

        -- Please see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/ before you turn this on
        allow_tearing = false,

        layout = "dwindle",
    },

    decoration = {
        rounding       = 10,
        rounding_power = 2,

        -- Change transparency of focused and unfocused windows
        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = "rgba(1a1a1aee)",
        },

        blur = {
            enabled  = true,
            size     = 3,
            passes   = 1,
            vibrancy = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },

    -- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/ for more
    dwindle = {
        -- pseudotiling has no config option in modern Hyprland — toggle it at runtime with the `pseudo` dispatcher (mainMod + P)
        preserve_split = true, -- You probably want this
    },

    -- See https://wiki.hypr.land/Configuring/Layouts/Master-Layout/ for more
    master = {
        new_status = "master",
    },

    misc = {
        force_default_wallpaper = -1,    -- Set to 0 or 1 to disable the anime mascot wallpapers
        disable_hyprland_logo   = false, -- If true disables the random hyprland logo / anime girl background. :(
    },
})

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })

hl.animation({ leaf = "global",        enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.1,  bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })


---------------
---- INPUT ----
---------------

-- https://wiki.hypr.land/Configuring/Basics/Variables/#input
hl.config({
    input = {
        kb_layout  = "de,us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "ctrl:nocaps,grp:win_space_toggle",
        kb_rules   = "",

        follow_mouse = 1,

        sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.

        natural_scroll = true,
        touchpad = {
            natural_scroll = true,
        },
    },
})

hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})

-- Border and group colors for the current dark/light mode. noctalia rewrites
-- noctalia.lua (untracked) on every mode change, and Hyprland reloads on the
-- write. Its template appends this line unless it finds require("noctalia").
require("noctalia").apply_theme()
