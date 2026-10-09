#!/bin/bash
cd ~/.config/picom && picom --window-shader-fg=rounded-borders.glsl --window-shader-fg-rule="$HOME/.config/picom/tray-border.glsl:class_g = 'stalonetray'" --backend=glx --daemon
