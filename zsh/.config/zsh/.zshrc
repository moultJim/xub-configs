# Hardcode clean system defaults
DEFAULT_SYS_PATH="/usr/local/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export PATH=$DEFAULT_SYS_PATH
# Add brew (hardcoded linuxbrew setup, replacing slow eval
export HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
export HOMEBREW_CELLAR="/home/linuxbrew/.linuxbrew/Cellar"
export HOMEBREW_REPOSITORY="/home/linuxbrew/.linuxbrew/Homebrew"
export PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:$PATH"
export MANPATH="/home/linuxbrew/.linuxbrew/share/man:$MANPATH"
export INFOPATH="/home/linuxbrew/.linuxbrew/share/info:$INFOPATH"
#eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
# Add custom directories
export PATH="$HOME/.local/share/bob/nvim-bin:$HOME/.cargo/bin:$PATH"
export PATH="$HOME/.local/bin:$HOME/.config/scripts:$HOME/.fzf/bin:$PATH"
# Bat theme
export BAT_THEME="Catppuccin Mocha"
# ==============================================================================
# FZF Environment Variables & Custom Hooks
# ==============================================================================
export FZF_FD_OPTS="--type f --hidden --follow --exclude .git"
export FZF_DEFAULT_COMMAND="fd $FZF_FD_OPTS"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type d --hidden --follow --exclude .git"

export FZF_DEFAULT_OPTS=" \
  --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
  --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
  --color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
  --color=selected-bg:#45475a \
  --multi"

export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always --line-range :500 {}'"
export FZF_COMPLETION_OPTS="--preview 'bat --style=numbers --color=always --line-range :500 {}'"

# Integrate fd with fzf's command-line fuzzy auto-completion
_fzf_compgen_path() { fd $FZF_FD_OPTS . "$1" }
_fzf_compgen_dir() { fd --type d --hidden --follow --exclude .git . "$1" }

# Define starship config location
export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"

# ==============================================================================
# VI-Mode Configuration Hooks & Completions Styles 
# (MUST be defined BEFORE plugins load)
# ==============================================================================
function zvm_after_select_vi_mode() { starship_zle-keymap-select }
zvm_after_init_commands+=('eval "$(fzf --zsh)"')

# Config fzf-tab (Pre-seeding values before fzf-tab plugin initializes)
zstyle ':completion:*' group-name ''
zstyle ':descriptions' format '[%d]'
zstyle ':fzf-tab:*' fzf-bindings 'ctrl-space:toggle+down' 'f1:toggle-preview'

zstyle ':completion:*:*:*' fzf-preview '
  if [ -d $realpath ]; then
    eza --color=always --icons=always --tree --level=1 $realpath
  else
    bat --style=numbers --color=always --line-range :500 $realpath 2>/dev/null
  fi
'
zstyle ':completion:*:*:cd:*' fzf-preview 'eza -1 --color=always --icons=always $realpath'
zstyle ':completion:*:*:env:*' fzf-preview 'echo ${(P)word}'
zstyle ':completion:*:*:export:*' fzf-preview 'echo ${(P)word}'
zstyle ':completion:*:(*man*):*' fzf-preview 'man $word'

# ==============================================================================
# Antidote Compilation Engine
# ==============================================================================
ANTIDOTE_DIR="${ZDOTDIR:-$HOME}/.antidote"
zplugins=${ZDOTDIR:-$HOME}/.zsh_plugins.txt

if [[ ! -d "$ANTIDOTE_DIR" ]]; then
    git clone --depth=1 https://github.com/mattmc3/antidote.git ${ZDOTDIR:-~}/.antidote
fi

source "$ANTIDOTE_DIR/antidote.zsh"

# Performance optimization: Generate static file only if .zsh_plugins.txt changes
# :r strips the .txt extension, allowing clean append of .zsh
if [[ ! ${zplugins}.zsh -nt ${zplugins} ]]; then
    antidote bundle < ${zplugins} > ${zplugins:r}.zsh
fi
source ${zplugins:r}.zsh

source <(carapace _carapace zsh)

# ------------------------------------------------------------------------------
# FZF-TAB & CARAPACE STYLING
# ------------------------------------------------------------------------------
#
# Enable group descriptions with a clean visual divider
zstyle ':completion:*:descriptions' format '[%d]'

# Force fzf-tab to use a structured list view with groupp headers
zstyle ':completion:*' group-name ''

# Inject custom flags into the fzf binary used by fzf-tab
# Giving a preview window, rounded borders, and custom colors
zstyle ':fzf-tab:*' fzf-flags \
  --height=40% \
  --layout=reverse \
  --border=rounded \
  --no-unicode \
  --inline-info \
  --group-border=underline \
  --color="header:#87afaf,border:#4e4e4e,label:#aeaeae"

# Switch groups smoothly using shift-left and shift-right arrows
zstyle ':fzf-tab:*' switch-group 'S-left' 'S-right'

# Give different completion types unique, subtle ANSI colors
zstyle ':completion:*:options' list-colors '=(#b)(--[a-zA-Z0-9-]##)*=0;36'
zstyle ':completion:*:commands' list-colors '=(#b)([a-zA-Z0-9-]##)*=0;32'

# ==============================================================================
# Environment Settings & Custom Functions
# ==============================================================================
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=cyan,bold'

HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY

unalias run-help 2>/dev/null
autoload -Uz run-help
autoload -Uz run-help-git
export HELPDIR="/usr/share/zsh/help"

setopt AUTO_CD
setopt INTERACTIVE_COMMENTS
setopt AUTO_PARAM_SLASH

[ -f ~/.aliases ] && source ~/.aliases

fpath=(~/.zsh_functions $fpath)
autoload -Uz mkc
autoload -Uz up
autoload -Uz ftldr
autoload -Uz y

# ==============================================================================
# Prompt Initialization (Must remain at the absolute bottom)
# ==============================================================================
eval "$(zoxide init zsh)"
# Only initialize starship if its zle keymap wrapper hasn't been defined yet
if [[ ! -n ${(f)functions[starship_zle-keymap-select]} ]]; then
    eval "$(starship init zsh)"
fi
