#!/bin/bash

# Keyboard Toggle Script for Waybar
# Toggles between German and English layouts

get_current_layout() {
    # Get current layout from hyprctl getoption
    hyprctl getoption input:kb_layout | grep "str:" | cut -d':' -f2 | xargs
}

toggle_layout() {
    current_layout=$(get_current_layout)
    
    if [[ "$current_layout" == "de" ]]; then
        hyprctl keyword input:kb_layout "us"
    else
        hyprctl keyword input:kb_layout "de"
    fi
}

get_status() {
    layout=$(get_current_layout)
    
    # Set layout indicator
    if [[ "$layout" == "de" ]]; then
        echo "⌨ DE"
    else
        echo "⌨ EN"
    fi
}

case "$1" in
    "toggle")
        toggle_layout
        ;;
    "status")
        get_status
        ;;
    *)
        get_status
        ;;
esac