#!/usr/bin/env python3

import json
import subprocess
import sys

def main():
    """Clipboard status script for waybar using clipse"""
    
    try:
        # Get current clipboard content
        result = subprocess.run(["clipse", "-p"], capture_output=True, text=True)
        current_content = result.stdout.strip()
        
        if current_content:
            # Get preview (first 50 chars)
            preview = current_content[:50].replace('\n', ' ')
            char_count = len(current_content)
            
            output = {
                "text": "󰅌",
                "class": "clipboard-active",
                "tooltip": f"Clipboard ({char_count} chars)\n{preview}..."
            }
        else:
            output = {
                "text": "󰅌", 
                "class": "clipboard-empty",
                "tooltip": "Clipboard is empty"
            }
            
        print(json.dumps(output))
        
    except subprocess.CalledProcessError:
        # Fallback if clipse fails
        output = {
            "text": "󰅌",
            "class": "clipboard-error", 
            "tooltip": "Clipboard unavailable"
        }
        print(json.dumps(output))

if __name__ == "__main__":
    main()