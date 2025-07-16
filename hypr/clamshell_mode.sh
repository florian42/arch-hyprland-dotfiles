#!/bin/bash

# Clamshell mode script for Hyprland
# Handles laptop display on/off when lid is opened/closed

# Monitor identifiers
LAPTOP_MONITOR="eDP-1"
EXTERNAL_MONITOR="DP-2"

# Check if external monitor is connected
if ! hyprctl monitors | grep -q "$EXTERNAL_MONITOR"; then
    echo "External monitor $EXTERNAL_MONITOR not connected"
    exit 1
fi

# Function to enable clamshell mode (lid closed)
enable_clamshell() {
    echo "Enabling clamshell mode - disabling laptop display"
    
    # Disable laptop monitor
    hyprctl keyword monitor "$LAPTOP_MONITOR,disable"
    
    # Ensure external monitor is enabled and becomes primary
    hyprctl keyword monitor "$EXTERNAL_MONITOR,3840x2560@59.98,0x0,1.6"
    
    # Move all workspaces to external monitor
    for i in {1..10}; do
        hyprctl dispatch moveworkspacetomonitor "$i" "$EXTERNAL_MONITOR"
    done
    
    echo "Clamshell mode enabled"
}

# Function to disable clamshell mode (lid opened)
disable_clamshell() {
    echo "Disabling clamshell mode - enabling laptop display"
    
    # Re-enable laptop monitor
    hyprctl keyword monitor "$LAPTOP_MONITOR,1920x1080@60,0x0,1"
    
    # Reposition external monitor to the right
    hyprctl keyword monitor "$EXTERNAL_MONITOR,3840x2560@59.98,1920x0,1.6"
    
    echo "Clamshell mode disabled"
}

# Check lid state
LID_STATE=$(cat /proc/acpi/button/lid/LID/state 2>/dev/null || echo "unknown")

if [[ "$LID_STATE" == *"closed"* ]]; then
    enable_clamshell
else
    disable_clamshell
fi