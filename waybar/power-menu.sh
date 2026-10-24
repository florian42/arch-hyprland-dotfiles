#!/usr/bin/env bash
# Power menu for the bar's ⏻ button. wofi runs as its own layer surface, so it
# stays up when the bar autohides. A waybar GtkMenu popup would vanish with it.
# No hibernate entry: the only swap is zram, and an image can't be resumed from RAM.

choice=$(printf '%s\n' "󰌾  Lock" "󰤄  Suspend" "󰜉  Reboot" "󰐥  Shut down" |
    wofi --dmenu --prompt "Power" --width 260 --height 250 --cache-file /dev/null) || exit 0

case $choice in
    *Lock)      loginctl lock-session ;;
    *Suspend)   systemctl suspend ;;
    *Reboot)    systemctl reboot ;;
    *"Shut down") systemctl poweroff ;;
esac
