# Arch Linux Hyprland Dotfiles

Modern Arch Linux dotfiles featuring Hyprland window manager with enhanced Waybar, clipboard integration, and Catppuccin theming.

## Features

- **Hyprland**: Modern Wayland compositor with smooth animations
- **Enhanced Waybar**: Custom modules with logical organization
  - MPRIS media controls
  - Clipboard history manager with wofi integration
  - Idle inhibitor toggle
  - Built-in backlight controls
  - Power profiles and system monitoring
- **Catppuccin Theme**: Consistent dark theme across all components
- **Clipboard Manager**: Python-based clipse integration
- **Wofi**: Application launcher with matching theme
- **Ghostty**: Modern terminal emulator configuration

## Prerequisites

This configuration requires an Arch Linux system with the following packages:

```bash
# Core packages
hyprland waybar wofi ghostty

# Dependencies for enhanced features
playerctl clipse brightnessctl

# Optional but recommended
hypridle hyprlock mako
```

## Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/arch-hyprland-dotfiles.git
   ```

2. Backup your existing configuration:
   ```bash
   mv ~/.config ~/.config.backup
   ```

3. Copy the dotfiles:
   ```bash
   cp -r arch-hyprland-dotfiles ~/.config
   ```

4. Start Hyprland or restart your session

## File Structure

```
.
├── hypr/                 # Hyprland configuration
│   ├── hyprland.conf     # Main config with auto-start programs
│   ├── keybinds.conf     # Keyboard shortcuts
│   ├── monitors.conf     # Display configuration
│   └── ...
├── waybar/               # Enhanced waybar setup
│   ├── config            # Waybar modules and layout
│   ├── style.css         # Catppuccin styling
│   └── scripts/          # Python scripts for custom modules
├── wofi/                 # Application launcher
├── ghostty/              # Terminal configuration
└── ...
```

## Waybar Features

The waybar configuration includes several custom enhancements:

- **Left**: Workspaces, Clipboard history, Idle inhibitor, Power profiles
- **Center**: Clock and Media controls (MPRIS)
- **Right**: System status (Brightness, Connectivity, Battery, Power menu)

### Custom Modules

- **Clipboard Manager**: Click to open history, right-click to clear
- **Media Controls**: Universal MPRIS support for Spotify, browsers, etc.
- **Idle Inhibitor**: Prevent screen sleep for presentations/videos

## Customization

The configuration uses consistent Catppuccin colors defined in `CLAUDE.md`. Key color variables:

- Background: `rgba(30, 30, 46, 0.9)`
- Surface: `rgba(49, 50, 68, 0.6)`
- Text: `#cdd6f4`
- Accent: `#74c7ec`

## Attribution

This configuration was inspired by and adapted from [omarchy](https://github.com/basecamp/omarchy), with significant enhancements and customizations added.

## License

MIT License - feel free to use and modify as needed.