-- Every variable set here, plus the session's own. Returned so autostart.lua
-- can hand them to the systemd user manager, which noctalia and the apps it
-- launches inherit from.
local names = { "WAYLAND_DISPLAY", "DISPLAY", "HYPRLAND_INSTANCE_SIGNATURE", "XDG_CURRENT_DESKTOP", "XDG_SESSION_ID" }

local function env(name, value)
    hl.env(name, value)
    names[#names + 1] = name
end

-- Cursor size
env("XCURSOR_SIZE", "24")
env("HYPRCURSOR_SIZE", "24")

-- Force all apps to use Wayland
env("GDK_BACKEND", "wayland,x11,*")
env("QT_QPA_PLATFORM", "wayland;xcb")
env("QT_QPA_PLATFORMTHEME", "qt6ct") -- palette from noctalia, see ~/.config/qt6ct/qt6ct.conf
env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
env("HYPRSHOT_DIR", "/home/flo/Pictures/Screenshots")

hl.config({
    xwayland = {
        force_zero_scaling = true,
    },
})

return names
