#!/usr/bin/env bash

# 1. Capture all passed arguments into a clean search phrase
TARGET_CMD="$*"

# If no argument was provided, prompt user for a name first
if [ -z "$TARGET_CMD" ]; then
    read -r -p "Enter command/query to look up: " TARGET_CMD
    [ -z "$TARGET_CMD" ] && exit 0
fi

# URL encode function to ensure web sources do not break on spaces or symbols
url_encode() {
    echo "$1" | jq -rr @uri 2>/dev/null || echo "$1" | sed 's/ /+/g'
}

ENCODED_CMD=$(url_encode "$TARGET_CMD")
FIRST_WORD=$(echo "$TARGET_CMD" | awk '{print $1}')

# 2. Define your list of sources for fzf
SELECTION=$(cat <<EOF | fzf --header="Get Help For: $TARGET_CMD" --height=40% --border
1. Local: Man Page (man)
2. Local: Built-in Shell Help (help)
3. Local: Info Pages (info)
4. Local: System Documentation (/usr/share/doc)
5. CLI API: cheat.sh
6. CLI API: tldr-pages
7. Web TUI: Explainshell (via Lynx)
8. Web TUI: GNU Coreutils Manual (via Lynx)
9. Web GUI: Google Search (Desktop Browser)
EOF
)

# Exit if user hits ESC or aborts fzf
[ -z "$SELECTION" ] && exit 0

# 3. Match user choice to the correct tool/execution style
case "$SELECTION" in
    *"Man Page"*)
        man "$FIRST_WORD"
        ;;
    *"Shell Help"*)
        # help is a bash builtin, we trigger a subshell bash to evaluate it
        bash -c "help $FIRST_WORD" | less
        ;;
    *"Info Pages"*)
        info "$FIRST_WORD"
        ;;
    *"/usr/share/doc"*)
        # Find matching documentation folders on your hard drive and browse them
        DOC_DIR=$(find /usr/share/doc -maxdepth 1 -iname "*$FIRST_WORD*" | fzf --header="Select a local doc folder to view")
        if [ -n "$DOC_DIR" ]; then
            # If lynx or ranger isn't preferred, use a recursive folder viewer or file lister
            ls -la "$DOC_DIR" | less
        fi
        ;;
    *"cheat.sh"*)
        # Uses curl directly for an ANSI pre-formatted endpoint
        curl -s "cheat.sh/$ENCODED_CMD" | less -R
        ;;
    *"tldr-pages"*)
        # Falls back to curl cheat.sh implementation of tldr if local tldr tool isn't installed
        command -v tldr >/dev/null 2>&1 && tldr "$FIRST_WORD" || curl -s "tldr.sh/$FIRST_WORD" | less
        ;;
    *"Explainshell"*)
        # Explainshell expects arguments to be formatted into the query path
        lynx "https://explainshell.com"
        ;;
    *"GNU Coreutils"*)
        # Redirect directly to gnu coreutils reference index
        lynx "https://gnu.org"
        ;;
    *"Google Search"*)
        # Open your system-default graphical web browser (Firefox, Chrome, etc.)
        # If running purely via headless SSH, swap this to: lynx "https://google.com"
        xdg-open "https://google.com" >/dev/null 2>&1 &
        ;;
esac

