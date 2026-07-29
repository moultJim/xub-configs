#!/usr/bin/env bash

# Check global env variable, set if not
: ${NVIM_APPNAME:="nvim-jm"}
export NVIM_APPNAME

# Launch a new Ghostty window running Neovim (jv version) 
ghostty -e nvim 
