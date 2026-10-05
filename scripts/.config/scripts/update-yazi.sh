#!/usr/bin/env bash
set -euo pipefail

# --- CONFIGURATION ---
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$HOME/.cargo/bin"

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
        DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus \
        notify-send -u "$urgency" \
                    -a "Yazi Updater" \
                    -i "$icon" \
                    -h string:x-canonical-private-synchronous:yazi-update \
                    "$title" \
                    "$message" 2>/dev/null || true
    fi
}

echo "🔍 Checking for Yazi updates natively via Cargo..."

# Get the version currently installed on your system before running the check
OLD_VER=$(yazi --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1 || echo "0.0.0")

# Run cargo install WITHOUT --force. 
# Cargo will automatically check crates.io. If you have the latest version, it skips.
# If a newer version exists, it downloads and compiles it.
if cargo install yazi-build; then
    # Get the version after the command runs
    NEW_VER=$(yazi --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1 || echo "0.0.0")

    if [ "$OLD_VER" = "$NEW_VER" ] && [ "$OLD_VER" != "0.0.0" ]; then
        echo "✅ Yazi is already up to date (v$OLD_VER)."
    else
        echo "🎉 Yazi successfully updated from v$OLD_VER to v$NEW_VER!"
        send_notification "Yazi Updated" "Successfully upgraded to v$NEW_VER" "normal"
    fi
else
    echo "❌ Error: Cargo update process failed."
    send_notification "Yazi Update Failed" "Cargo returned a non-zero exit code." "critical"
    exit 1
fi

# Keep only the last 100 lines of the log file to prevent infinite growth
if [ -f /home/jim/.config/scripts/yazi-updater.log ]; then
    tail -n 100 /home/jim/.config/scripts/yazi-updater.log > /home/jim/.config/scripts/yazi-updater.tmp && mv /home/jim/.config/scripts/yazi-updater.tmp /home/jim/.config/scripts/yazi-updater.log
fi
