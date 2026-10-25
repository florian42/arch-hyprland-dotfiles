local sessionEnv = table.concat(require("envs"), " ")

-- hyprland.start fires once per session, the equivalent of exec-once.
hl.on("hyprland.start", function()
    hl.exec_cmd("hypridle")
    -- noctalia: bar, notifications, launcher, wallpaper; the unit restarts it if it dies.
    -- It and every app it launches inherit the user manager's environment, so hand
    -- over the session's first (envs.lua; XDG_SESSION_ID lets it find its logind session).
    hl.exec_cmd("dbus-update-activation-environment --systemd " .. sessionEnv .. " && systemctl --user restart noctalia")
    hl.exec_cmd("easyeffects --service-mode --hide-window")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("blueman-applet")  -- BlueZ agent: authorizes device-initiated A2DP/HFP connections
    hl.exec_cmd([[wl-clip-persist --clipboard regular --all-mime-type-regex '^(?!x-kde-passwordManagerHint).+']])
    hl.exec_cmd("obsidian")
    hl.exec_cmd("wl-paste --watch cliphist store")
    hl.exec_cmd("/opt/1Password/1password --silent")
end)
