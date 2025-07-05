#!/bin/bash

# Power menu using wofi
OPTIONS="⏻ Shutdown\n🔄 Reboot\n😴 Hybrid Sleep\n🔒 Lock"

CHOICE=$(echo -e "$OPTIONS" | wofi --dmenu --prompt "Power Menu" --width 200 --height 200)

case $CHOICE in
    "⏻ Shutdown")
        systemctl poweroff
        ;;
    "🔄 Reboot")
        systemctl reboot
        ;;
    "😴 Hybrid Sleep")
        systemctl hybrid-sleep
        ;;
    "🔒 Lock")
        loginctl lock-session
        ;;
esac