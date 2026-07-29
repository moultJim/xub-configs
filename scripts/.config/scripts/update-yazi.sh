#!/usr/bin/env bash
# crash if any cmd in pipeline returns non-zero err code
set -euo pipefail

# --- CONFIGURATION ---
#DEFAULT_SYS_PATH="/usr/local/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
#export PATH=$DEFAULT_SYS_PATH
# Add brew (hardcoded linuxbrew setup, replacing slow eval
#export HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
#export HOMEBREW_CELLAR="/home/linuxbrew/.linuxbrew/Cellar"
#export HOMEBREW_REPOSITORY="/home/linuxbrew/.linuxbrew/Homebrew"
#export PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:$PATH"
#export MANPATH="/home/linuxbrew/.linuxbrew/share/man:$MANPATH"
#export INFOPATH="/home/linuxbrew/.linuxbrew/share/info:$INFOPATH"
#eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
# Add custom directories
#export PATH="/home/jim/.local/share/bob/nvim-bin:/home/jim/.cargo/bin:$PATH"
#export PATH="$HOME/.local/bin:$HOME/.config/scripts:$HOME/.fzf/bin:$PATH"
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$HOME/.cargo/bin"

API_HOST="https://api.github.com"
API_ENDPOINT="/repos/sxyazi/yazi/releases/latest"
REPO_API="${API_HOST}${API_ENDPOINT}"
# ---------------------
send_notification() {
    local title="$1"
    local message="$2"
    local urgency="${3:-normal}"
    local icon="system-software-update" # Standard app update icon

    # Swap icon if it is a critical failure alert
    if [ "$urgency" = "critical" ]; then
        icon="dialog-error"
    fi
    
    # Route variables to display screen 0 and prompt Dunst with a valid icon
    if command -v notify-send &> /dev/null; then
        DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus \
        notify-send -u "$urgency" \
                    -a "Yazi Updater" \
                    -i "$icon" \
                    -h string:x-canonical-private-synchronous:yazi-update \
                    "$title" \
                    "$message" 2>/dev/null || true
    fi
}

echo "🔍 Checking for Yazi updates..."

# 1. Get local version safely
if command -v yazi &> /dev/null; then
    LOCAL_VER=$(yazi --version | awk '/Version:/ {print $2}' | sed 's/^v//')
else
    LOCAL_VER="0.0.0"
    echo "⚠️ Yazi is not currently installed."
fi

# 2. Get latest remote version tag from GitHub API
# Fetch raw JSON payload first without breaking on pipe errors
RAW_JSON=$(curl -sL "$REPO_API" || echo "")

if [ -z "$RAW_JSON" ]; then
    echo "❌ Error: Network unreachable or API down."
    send_notification "Yazi Update Error" "Network network connection failure." "critical"
    exit 1
fi

# Isolate the tag field safely
REMOTE_VER=$(echo "$RAW_JSON" | grep '"tag_name":' | sed -E 's/.*"tag_name":\s*"v?([^"]+)".*/\1/' || echo "")

if [ -z "$REMOTE_VER" ]; then
    echo "❌ Error: Could not parse remote version from GitHub JSON response."
    send_notification "Yazi Update Error" "GitHub payload changed layout format." "critical"
    exit 1
fi

echo "Installed version: v$LOCAL_VER"
echo "Latest release: v$REMOTE_VER"

# 3. Compare and Update
if [ "$LOCAL_VER" = "$REMOTE_VER" ]; then
    echo "✅ Yazi is already up to date."
    exit 0
else
    echo "🔄 Update needed! Preparing installation via cargo binstall..."
    send_notification "Yazi Update" "New version v$REMOTE_VER found. Installing now..." "normal"

    if ! command -v cargo-binstall &> /dev/null && ! cargo binstall --help &> /dev/null; then
        echo "❌ Error: cargo-binstall command not found."
        send_notification "Yazi Update Failed" "cargo-binstall is missing from the environment path." "critical"
        exit 1
    fi

    if cargo binstall --no-confirm yazi-fm yazi-cli; then
        echo "🎉 Yazi successfully updated to v$REMOTE_VER!"
        send_notification "Yazi Updated" "Successfully upgraded to v$REMOTE_VER" "normal"
        exit 0
    else
        echo "❌ Error: cargo binstall execution failed."
        send_notification "Yazi Update Failed" "Installation process returned a non-zero exit code." "critical"
        exit 1
    fi
fi

