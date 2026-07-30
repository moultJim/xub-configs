#!/usr/bin/env zsh

# Ctrl-r to revisit menu
# <esc> to fully exit
# <esc> can still be used with fzf
# q is general quit of doc sources
# ==============================================================================
# 1. Environment & Theme Configurations (Rest of your script remains here...)
# ==============================================================================

# Catppuccin Mocha styling for less and man pages
export LESS_TERMCAP_mb=$'\E[1;31m'     # Start blink -> Pink/Red (#f38ba8)
export LESS_TERMCAP_md=$'\E[1;34m'     # Start bold -> Blue (#89b4fa)
export LESS_TERMCAP_me=$'\E[0m'        # End all mode formatting
export LESS_TERMCAP_se=$'\E[0m'        # End standout mode
export LESS_TERMCAP_so=$'\E[38;5;232;48;5;224m' # Start standout -> Inverse on Rosewater (#f5e0dc)
export LESS_TERMCAP_ue=$'\E[0m'        # End underline mode
export LESS_TERMCAP_us=$'\E[1;35m'     # Start underline -> Mauve/Lavender (#cba6f7)

# Global Less behavior override
export LESS="-FRSX --use-color"

# Catppuccin Mocha theme string for fzf
MOCHA_THEME="--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"

# ==============================================================================
# 2. Capture Clean Search Queries (With State History)
# ==============================================================================
HISTORY_FILE="$HOME/.cache/gh_history"
mkdir -p "$(dirname "$HISTORY_FILE")"

TARGET_CMD="$*"
if [[ -z "$TARGET_CMD" ]]; then
    LAST_QUERY=""
    [[ -f "$HISTORY_FILE" ]] && LAST_QUERY=$(cat "$HISTORY_FILE")

    if [[ -n "$LAST_QUERY" ]]; then
        printf "Enter command/query to look up [Default: %s]: " "$LAST_QUERY"
    else
        printf "Enter command/query to look up: "
    fi
    
    read -r TARGET_CMD
    
    if [[ -z "$TARGET_CMD" ]]; then
        TARGET_CMD="$LAST_QUERY"
    fi
    [[ -z "$TARGET_CMD" ]] && exit 0
fi

echo "$TARGET_CMD" > "$HISTORY_FILE"

url_encode() {
    printf '%s' "$1" | jq -rr @uri 2>/dev/null || printf '%s' "$1" | sed 's/ /+/g'
}
ENCODED_CMD=$(url_encode "$TARGET_CMD")
FIRST_WORD=$(echo "$TARGET_CMD" | awk '{print $1}')

# ==============================================================================
# 3. Intelligent Initial Selection Pre-Calculation
# ==============================================================================
INITIAL_QUERY=""
if [[ "$(whence -w $FIRST_WORD 2>/dev/null)" == *"builtin"* ]]; then
    INITIAL_QUERY="Shell Help"
elif ! man "$FIRST_WORD" >/dev/null 2>&1; then
    INITIAL_QUERY="apropos"
fi

# ==============================================================================
# 4. Preview Window Generation Loop
# ==============================================================================
export TARGET_CMD FIRST_WORD ENCODED_CMD
PREVIEW_COMMAND='
if curl -s --connect-timeout 1 1.1.1.1 >/dev/null; then ONLINE=1; else ONLINE=0; fi

case {} in
    *"apropos"*) apropos "$TARGET_CMD" 2>/dev/null | head -n 30 ;;
    *"cheat.sh"*) 
        if [ $ONLINE -eq 1 ]; then curl -s "cheat.sh/${TARGET_CMD// /+}" | head -n 30; 
        else echo "⚠️ Offline: cheat.sh requires an active internet connection."; fi ;;
    *"tldr-pages"*) 
        if command -v tldr >/dev/null; then tldr "$FIRST_WORD" | head -n 30;
        elif [ $ONLINE -eq 1 ]; then curl -s "tldr.sh/$FIRST_WORD" | head -n 30;
        else echo "⚠️ Offline: Local tldr tool missing, and remote tldr.sh API is unreachable."; fi ;;
    *"Man Page"*) man "$FIRST_WORD" | col -b | head -n 30 ;;
    *"Shell Help"*) 
        if [[ "$(whence -w $FIRST_WORD 2>/dev/null)" == *"builtin"* ]]; then
            bash -c "help $FIRST_WORD 2>/dev/null" | head -n 30
        else
            echo "ℹ️ $FIRST_WORD is an external command (not a shell builtin)."
        fi ;;
    *) echo "💡 Press ENTER to open this web/system browser interface..." ;;
esac
'

# ==============================================================================
# 5. Core Execution Loop (Persists Until Explicit Escape)
# ==============================================================================
while true; do
    # Primary FZF Interface Rendering
    SELECTION=$(cat <<EOF | fzf \
        ${=MOCHA_THEME} \
        --bind="ctrl-j:down,ctrl-k:up" \
        --bind="ctrl-r:unbind(ctrl-r)+change-query()" \
        --header="Documentation Dashboard ── Search: $TARGET_CMD  [Ctrl+R: Reset Filter]" \
        --height=60% \
        --border=rounded \
        --layout=reverse \
        --query="$INITIAL_QUERY" \
        --preview="$PREVIEW_COMMAND" \
        --preview-window="right:55%:nohidden"
0. Keyword: Search via apropos [Previewable]
1. Local: Man Page (man) [Previewable]
2. Local: Built-in Shell Help (help) [Previewable]
3. CLI API: cheat.sh [Previewable]
4. CLI API: tldr-pages [Previewable]
5. Local: Info Pages (info)
6. Local: System Documentation (/usr/share/doc)
7. Web TUI: Explainshell (via Lynx)
8. Web TUI: GNU Coreutils Manual (via Lynx)
9. Web GUI: Google Search (via xdg-open)
EOF
    )

    # If user cancels out via Escape, break loop safely and drop to interactive shell
    [[ -z "$SELECTION" ]] && break

    # Clear initial query flag so returning to menu shows all tools unfiltered
    INITIAL_QUERY=""

    # Router logic execution (OR true blocks prevent sub-command exit codes from breaking loop)
    case "$SELECTION" in
        *"apropos"*)
            APROPOS_CHOICE=$(apropos "$TARGET_CMD" 2>/dev/null | fzf \
                ${=MOCHA_THEME} \
                --bind="ctrl-j:down,ctrl-k:up" \
                --header="Apropos results for: $TARGET_CMD" \
                --height=50% \
                --border=rounded \
                --layout=reverse)
            if [[ -n "$APROPOS_CHOICE" ]]; then
                MAN_TARGET=$(echo "$APROPOS_CHOICE" | awk '{print $1}')
                man "$MAN_TARGET"
            fi
            ;;
        *"Man Page"*) man "$FIRST_WORD" || true ;;
        *"Shell Help"*) bash -c "help $FIRST_WORD" | less || true ;;
        *"cheat.sh"*) curl -s "cheat.sh/$ENCODED_CMD" | less || true ;;
        *"tldr-pages"*) (command -v tldr >/dev/null 2>&1 && tldr "$FIRST_WORD") || curl -s "tldr.sh/$FIRST_WORD" | less || true ;;
        *"Info Pages"*) info "$FIRST_WORD" || true ;;
        *"/usr/share/doc"*) 
            DOC_DIR=$(find /usr/share/doc -maxdepth 1 -iname "*$FIRST_WORD*" | fzf \
                ${=MOCHA_THEME} \
                --bind="ctrl-j:down,ctrl-k:up" \
                --header="Select documentation folder" \
                --height=50% \
                --border=rounded \
                --layout=reverse)
            [[ -n "$DOC_DIR" ]] && ls -la "$DOC_DIR" | less
            ;;
        *"Explainshell"*) lynx -lss="$HOME/.config/lynx/mocha.lss" "https://explainshell.com" || true ;;
        *"GNU Coreutils"*) lynx -lss="$HOME/.config/lynx/mocha.lss" "https://gnu.org" || true ;;
        *"Google Search"*) xdg-open "https://google.com" >/dev/null 2>&1 & ;;
    esac
done

# Safety Anchor: If loop breaks, transform process into a living Zsh instance
exec zsh -i
