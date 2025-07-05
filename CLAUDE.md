# Design Theme Documentation

## Color Palette (Catppuccin-inspired)

### Primary Colors
- **Background**: `rgba(30, 30, 46, 0.9)` - Dark blue-gray with transparency
- **Surface**: `rgba(49, 50, 68, 0.6)` - Slightly lighter surface color
- **Text**: `#cdd6f4` - Light gray-blue text
- **Border**: `rgba(205, 214, 244, 0.2)` - Subtle border color

### Accent Colors
- **Primary Accent**: `#74c7ec` - Light blue (for active states, selections)
- **Success/Clock**: `#a6e3a1` - Light green (for clock display)
- **Warning**: `#f9e2af` - Light yellow (for battery warnings)
- **Error/Critical**: `#f38ba8` - Light red (for critical states)

### Transparency Levels
- **Main containers**: 0.9 opacity
- **Surface elements**: 0.6 opacity
- **Hover states**: 0.8 opacity
- **Selected states**: 0.2-0.3 opacity with accent color

## Typography
- **Font Family**: 'JetBrainsMono Nerd Font'
- **Font Size**: 13px (waybar), 14px (wofi)
- **Font Weight**: 500 (medium weight)

## Design Principles

### Visual Hierarchy
- **Rounded corners**: 12px for main containers, 8px for modules, 6px for buttons
- **Consistent spacing**: 6px margins, 4px padding for most elements
- **Subtle borders**: 1px solid with low opacity for definition

### Interactive States
- **Hover effects**: Increased opacity and border visibility
- **Active states**: Accent color background with high contrast text
- **Focus states**: Blue accent border for input elements
- **Transitions**: 0.3s ease for smooth animations

### Layout Structure
- **Waybar**: Translucent bar with individual module containers
- **Wofi**: Matching dark theme with rounded search input
- **Consistent margins**: 8px-12px spacing between major elements

## Component Styling

### Waybar Modules
- Individual rounded containers with subtle backgrounds
- Hover effects that brighten the container
- Color-coded states (battery, network, audio)
- Consistent icon spacing and sizing

### Wofi Launcher
- Rounded main window with subtle border
- Focused input with blue accent
- Hover and selection states matching waybar colors
- Smooth transitions between states

## Implementation Notes
- Uses RGBA colors for transparency effects
- GTK CSS compatible (no backdrop-filter)
- Consistent color variables across components
- Responsive hover states for better UX