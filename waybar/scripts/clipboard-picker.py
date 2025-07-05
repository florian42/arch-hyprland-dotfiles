#!/usr/bin/env python3

import json
import subprocess
import sys
from pathlib import Path

def main():
    """Clipboard history picker for clipse + wofi"""
    clipboard_file = Path.home() / ".config/clipse/clipboard_history.json"
    
    if not clipboard_file.exists():
        subprocess.run(["notify-send", "Clipboard", "No clipboard history found"])
        return
    
    try:
        with open(clipboard_file) as f:
            data = json.load(f)
            history = data.get("clipboardHistory", [])
    except (json.JSONDecodeError, FileNotFoundError):
        subprocess.run(["notify-send", "Clipboard", "Failed to read clipboard history"])
        return
    
    if not history:
        subprocess.run(["notify-send", "Clipboard", "Clipboard history is empty"])
        return
    
    # Format entries for wofi (limit to first 80 chars, replace newlines)
    entries = []
    for item in history[:20]:  # Limit to 20 most recent
        value = item.get("value", "").replace("\n", " ").strip()
        if value:
            entries.append(value[:80] + "..." if len(value) > 80 else value)
    
    if not entries:
        subprocess.run(["notify-send", "Clipboard", "No valid clipboard entries found"])
        return
    
    # Show in wofi
    try:
        result = subprocess.run(
            ["wofi", "--dmenu", "--prompt", "Clipboard History", "--lines", "10", "--width", "600"],
            input="\n".join(entries),
            text=True,
            capture_output=True
        )
        
        if result.returncode == 0 and result.stdout.strip():
            selected = result.stdout.strip()
            # Copy to clipboard
            subprocess.run(["wl-copy"], input=selected, text=True)
            subprocess.run(["notify-send", "Clipboard", "Copied to clipboard"])
            
    except subprocess.CalledProcessError:
        subprocess.run(["notify-send", "Clipboard", "Failed to open clipboard picker"])

if __name__ == "__main__":
    main()