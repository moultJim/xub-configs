#!/usr/bin/env bash

# 1. Path to your personal cheatsheets folder
CHEATSHEET_DIR="$HOME/.config/cheat/cheatsheets/personal"

# 2. Get list of files, strip the path, and present them in Rofi
SELECTED_FILE=$(ls "$CHEATSHEET_DIR" | rofi -dmenu -p "   Cheatsheets" -theme catppuccin-mocha)

# 3. If you escape out of Rofi without selecting, exit cleanly
if [ -z "$SELECTED_FILE" ]; then
    exit 0
fi

# 4. Prepare nvim launch
# Check global env variable, set if not                              
${NVIM_APPNAME:="nvim-jm"}                                           
export NVIM_APPNAME                                                  
                                                                     
# Launch a new Ghostty window running Neovim (jv version) with selected cheatsheet
/usr/bin/ghostty -e zsh -c "/home/jim/.local/share/bob/nvim-bin/nvim $CHEATSHEET_DIR/$SELECTED_FILE"
