#!/bin/bash

# Create brightness options
OPTIONS="10%\n20%\n30%\n40%\n50%\n60%\n70%\n80%\n90%\n100%"

# Show wofi menu and get selection
CHOICE=$(echo -e "$OPTIONS" | wofi --dmenu --prompt "Brightness" --width 200 --height 300)

# If user made a selection, set brightness
if [ -n "$CHOICE" ]; then
    brightnessctl set "$CHOICE"
fi