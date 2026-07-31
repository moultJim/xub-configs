export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="$HOME/.local/state"
export BROWSER="google-chrome"
export TERMINAL="ghostty"
export DISPLAY=:0
export LYNX_CFG="$HOME/.config/lynx/lynx.cfg"

# Check if nvim exists in commands array
# If not, use vim.

export EDITOR="${commands[nvim]:-vim}"

# Set binary path first, then add flags
if (( ${+commands[less]}  )); then
    export PAGER="less -FRSX --use-color"
    export MANPAGER="less -FRSX --use-color"
fi

