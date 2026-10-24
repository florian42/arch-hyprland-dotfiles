-- hyprland.start fires once per session, the equivalent of exec-once.
hl.on("hyprland.start", function()
    hl.exec_cmd("hypridle")
    hl.exec_cmd("systemctl --user restart hyprbar")  -- waybar supervisor; the unit restarts it if it dies
    hl.exec_cmd("mako")
    hl.exec_cmd("easyeffects --service-mode --hide-window")
    hl.exec_cmd("swaybg -i ~/Pictures/Wallpaper/3--Milad-Fakurian-Abstract-Purple-Blue.jpg -m fill")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("blueman-applet")  -- BlueZ agent: authorizes device-initiated A2DP/HFP connections
    hl.exec_cmd([[wl-clip-persist --clipboard regular --all-mime-type-regex '^(?!x-kde-passwordManagerHint).+']])
    hl.exec_cmd("obsidian")
    hl.exec_cmd("wl-paste --watch cliphist store")
    hl.exec_cmd("/opt/1Password/1password --silent")
end)
