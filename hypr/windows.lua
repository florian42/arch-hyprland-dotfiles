-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/ for more

local dialogs = "^(.blueman-manager-wrapped|Impala|Wiremix|org.gnome.NautilusPreviewer|Omarchy|About)$"
local filePickerTitle = "^(Open.*Files?|Save.*Files?|All Files|Save)"

-- Suppress maximize events
hl.window_rule({ match = { class = ".*" }, suppress_event = "maximize" })

-- Force chromium into a tile to deal with --app bug
hl.window_rule({ match = { class = "^(Chromium)$" }, tile = true })

-- Float and center settings and previews
hl.window_rule({ match = { class = dialogs }, float = true, center = true })
hl.window_rule({
    match = { class = "^(.blueman-manager-wrapped|Impala|Wiremix|org.gnome.NautilusPreviewer|com.gabm.satty)$" },
    size  = { 800, 600 },
})
hl.window_rule({ match = { class = "Omarchy" }, size = { 590, 450 } })
hl.window_rule({ match = { class = "About" },   size = { 700, 470 } })

-- Float and center file pickers
hl.window_rule({
    match  = { class = "xdg-desktop-portal-gtk", title = filePickerTitle },
    float  = true,
    center = true,
})

-- Float Steam, fullscreen RetroArch
hl.window_rule({ match = { class = "steam" }, float = true })
hl.window_rule({ match = { class = "steam", title = "Steam" }, center = true })
hl.window_rule({ match = { class = "^(com.libretro.RetroArch)$" }, fullscreen = true })

-- Fullscreen screensaver
hl.window_rule({ match = { class = "Screensaver" }, fullscreen = true })

-- Just dash of opacity
hl.window_rule({ match = { class = ".*" }, opacity = "0.97 0.9" })
hl.window_rule({ match = { class = "^(Chromium|chromium|google-chrome|google-chrome-unstable)$" }, opacity = "1 0.97" })
hl.window_rule({ match = { initial_title = "^(youtube.com_/)$" }, opacity = "1 1" })
hl.window_rule({
    match   = { class = "^(zoom|vlc|mpv|org.kde.kdenlive|com.obsproject.Studio|com.github.PintaProject.Pinta|imv|org.gnome.NautilusPreviewer)$" },
    opacity = "1 1",
})
hl.window_rule({ match = { class = "^(com.libretro.RetroArch|steam)$" }, opacity = "1 1" })

-- Fix some dragging issues with XWayland
hl.window_rule({
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

-- Waybar (started by ~/.config/waybar/hyprbar.py): blur its translucent pill
-- and slide it in from the left when the hot corner reveals it.
hl.layer_rule({
    match        = { namespace = "^waybar$" },
    blur         = true,
    ignore_alpha = 0.3,
    animation    = "slide left",
})
