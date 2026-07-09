# 🍚 brams153-first_rice
Welcome to my very first rice! This repository contains my personal dotfiles, featuring a fully customized, dynamic, and aesthetic desktop environment built around **i3wm**. It includes dynamic color generation based on wallpapers, smooth blur effects, and custom scripts for a better workflow.
### 🎥 Showcase

![rice](rice.mp4)
## 🛠️ Tools & Dependencies
Here is a breakdown of the core components used to build this setup:
| Category | Tool | Description |
|---|---|---|
| **Window Manager** | **i3wm** | Tiling window manager configured for gaps and intuitive keybinds. |
| **Status Bar** | **Polybar** | Highly customizable status bar (using the Material theme). |
| **Terminal** | **Kitty** | Fast, feature-rich, GPU-based terminal emulator. |
| **Compositor** | **Picom** | Handles dual_kawase blur, shadows, and smooth window fading. |
| **App Launcher** | **Rofi** | Used for launching apps, power menus, and wallpaper selection. |
| **Color Generator** | **Wallust** | Dynamically generates color schemes from the current wallpaper. |
| **Wallpapers** | **Feh / xwinwrap / mpv** | Handles both static images and live (video) wallpapers. |
| **Productivity** | **Polypomo** | Polybar Pomodoro timer module. |
*Note: Other utilities include maim (screenshots), copyq (clipboard manager), and i3lock (screen locker).*
## 📂 Directory Structure
```text
└── brams153-first_rice/
    ├── LICENSE
    └── Rice/
        ├── i3/
        │   ├── config
        │   ├── config.save
        │   ├── config_default
        │   ├── wallust-colors
        │   └── scripts/
        │       ├── audio.sh, battery.sh, caffeine.sh, dolar.sh, etc.
        ├── picom/
        │   ├── compton.conf
        │   ├── default_picom.conf
        │   └── picom.conf
        ├── polybar/
        │   ├── launch.sh
        │   └── material/
        │       ├── config.ini, colors.ini, modules.ini, etc.
        │       └── scripts/
        │           ├── rofi/
        │           ├── polypomo/
        │           └── wall-menu.sh, color-switch.sh, etc.
        └── wallust/
            ├── wallust.toml
            └── templates/
                ├── i3-colors, kitty-colors, polybar-colors, rofi-colors

```
## 🌟 Features
 * **Dynamic Theming:** Thanks to wallust, changing the wallpaper automatically updates the colors of i3, Polybar, Kitty, and Rofi.
 * **Live Wallpapers:** Integrated scripts to smoothly run .mp4 and .mkv video backgrounds using xwinwrap and mpv.
 * **Custom Rofi Menus:** Beautifully themed menus for app launching, network management, power options, and wallpaper selection.
 * **Pomodoro Integration:** Built-in Pomodoro timer right in the Polybar to help keep focus.
## 🙏 Credits & Acknowledgments
This rice wouldn't be possible without the amazing work of the open-source community. Huge thanks to:
 * **Aditya Shakya (@adi1090x)** for the incredible **Huge Polybar Collection**. The *Material* theme used here is heavily based on their fantastic work.
 * **Kitty** for an incredibly fast and scriptable terminal emulator.
 * **Wallust** for the seamless dynamic color generation.
 * **Renato Alves (@unode)** for **Polypomo**, the awesome Pomodoro widget for Polybar.
 * **icemodding** for several helpful i3 status scripts.
 * **Exo** (from the ArchlinuxLatinoamerica group) for the Dollar exchange rate script.
## 📜 License
This project is licensed under the MIT License - see the LICENSE file for details.
