#!/bin/bash

# Get current brightness percentage
BRIGHTNESS=$(brightnessctl -m | cut -d, -f4 | sed 's/%//')

# Choose icon based on brightness level
if [ "$BRIGHTNESS" -lt 30 ]; then
    ICON="󰃞"
elif [ "$BRIGHTNESS" -lt 70 ]; then
    ICON="󰃟"
else
    ICON="󰃠"
fi

echo "$ICON"