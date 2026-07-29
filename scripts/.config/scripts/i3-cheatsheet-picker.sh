#!/usr/bin/env bash

# 1. Path to your personal cheatsheets folder
CHEATSHEET_DIR="$HOME/.config/cheat/cheatsheets/personal"

# 2. Get list of files, strip the path, and present them in Rofi
SELECTED_FILE=$(ls "$CHEATSHEET_DIR" | rofi -dmenu -p "   Cheatsheets" -theme catppuccin-mocha)

# 3. If you escape out of Rofi without selecting, exit cleanly
if [ -z "$SELECTED_FILE" ]; then
    exit 0
fi

# 4. Tell i3 to split your current workspace container vertically
# i3-msg split horizontal

# 5. Launch a new Ghostty window running Neovim with the target file
ghostty -e nvim "$CHEATSHEET_DIR/$SELECTED_FILE"
