#!/usr/bin/env bash
set -euo pipefail

# --- CONFIGURATION ---
# Merged paths so it finds Homebrew (Chromebook) or your regular setup (Xubuntu)
export PATH="/home/linuxbrew/.linuxbrew/bin:$HOME/.cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Ensure the scripts directory exists
mkdir -p "$HOME/.config/scripts"

# ---------------------
echo -e "\n📅 [$(date '+%Y-%m-%d %H:%M:%S')] Starting Update Validation Loop..."

send_notification() {
    local title="$1"
    local message="$2"
    local urgency="${3:-normal}"
    local icon="system-software-update"

    if [ "$urgency" = "critical" ]; then
        icon="dialog-error"
    fi
    
    if command -v notify-send &> /dev/null; then
        # SMART ENVIRONMENT DETECTION:
        # If /run/user/1000/bus exists, we are likely on your Xubuntu laptop and need D-Bus routing.
        if [ -S /run/user/1000/bus ]; then
            DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus \
            notify-send -u "$urgency" \
                        -a "Yazi Updater" \
                        -i "$icon" \
                        -h string:x-canonical-private-synchronous:yazi-update \
                        "$title" \
                        "$message" 2>/dev/null || true
        else
            # Otherwise, we are on the Chromebook where ChromeOS intercepts notifications natively
            notify-send -u "$urgency" -a "Yazi Updater" -i "$icon" "$title" "$message" 2>/dev/null || true
        fi
    fi
}

echo "🔍 Checking for Yazi updates via Cargo Binstall..."

# Get the version currently installed on your system before running the check
OLD_VER=$(yazi --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1 || echo "0.0.0")

# Run cargo binstall non-interactively (-y) for both packages.
if cargo binstall -y yazi-fm yazi-cli; then
    # Get the version after the command runs
    NEW_VER=$(yazi --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1 || echo "0.0.0")

    if [ "$OLD_VER" = "$NEW_VER" ] && [ "$OLD_VER" != "0.0.0" ]; then
        echo "✅ Yazi is already up to date (v$OLD_VER)."
    else
        echo "🎉 Yazi successfully updated from vOLDVERtovNEW_VER!"
        send_notification "Yazi Updated" "Successfully upgraded to v$NEW_VER" "normal"
    fi
else
    echo "❌ Error: Cargo binstall process failed."
    send_notification "Yazi Update Failed" "Binstall returned a non-zero exit code." "critical"
    exit 1
fi

# Keep only the last 100 lines of the log file to prevent infinite growth
if [ -f "$HOME/.config/scripts/yazi-updater.log" ]; then
    tail -n 100 "$HOME/.config/scripts/yazi-updater.log" > "$HOME/.config/scripts/yazi-updater.tmp" && mv "$HOME/.config/scripts/yazi-updater.tmp" "$HOME/.config/scripts/yazi-updater.log"
fi

