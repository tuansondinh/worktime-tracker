#!/bin/bash
set -e

WORKTIME_DIR="$HOME/.worktime"
TRACKER_DIR="$(cd "$(dirname "$0")" && pwd)"
PLIST_TEMPLATE="$TRACKER_DIR/com.son.worktime.plist"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
PLIST_DEST="$LAUNCH_AGENTS_DIR/com.son.worktime.plist"
LABEL="com.son.worktime"

echo "Setting up Work Time Tracker..."

# Install SwiftBar if not already installed
if ! [ -d "/Applications/SwiftBar.app" ]; then
  if command -v brew >/dev/null 2>&1; then
    echo "Installing SwiftBar..."
    brew install --cask swiftbar
    echo "✓ SwiftBar installed"
  else
    echo "  Homebrew not found — install SwiftBar manually: https://swiftbar.app"
  fi
else
  echo "✓ SwiftBar already installed"
fi

mkdir -p "$WORKTIME_DIR" "$LAUNCH_AGENTS_DIR"

cp "$TRACKER_DIR/track.sh" "$WORKTIME_DIR/"
cp "$TRACKER_DIR/worktime" "$WORKTIME_DIR/"
cp "$TRACKER_DIR/worktime.1m.sh" "$WORKTIME_DIR/"
cp "$TRACKER_DIR/stats.sh" "$WORKTIME_DIR/"
chmod +x "$WORKTIME_DIR/track.sh" "$WORKTIME_DIR/worktime" "$WORKTIME_DIR/worktime.1m.sh" "$WORKTIME_DIR/stats.sh"
echo "✓ Installed scripts to ~/.worktime/"

HOME_ESCAPED=$(printf '%s\n' "$HOME" | sed 's/[\/&]/\\&/g')
sed "s#__HOME__#$HOME_ESCAPED#g" "$PLIST_TEMPLATE" > "$PLIST_DEST"
echo "✓ Installed launchd agent"

launchctl bootout "gui/$(id -u)/$LABEL" >/dev/null 2>&1 || true
launchctl bootstrap "gui/$(id -u)" "$PLIST_DEST"
launchctl kickstart -k "gui/$(id -u)/$LABEL"
echo "✓ Tracker started"

# Auto-install SwiftBar plugin if SwiftBar is present
SWIFTBAR_DIRS=(
  "$HOME/Library/Application Support/SwiftBar/Plugins"
  "$HOME/Documents/SwiftBar"
  "$HOME/SwiftBar"
)

SWIFTBAR_PLUGIN_DIR=""
for dir in "${SWIFTBAR_DIRS[@]}"; do
  if [ -d "$dir" ]; then
    SWIFTBAR_PLUGIN_DIR="$dir"
    break
  fi
done

# Also check SwiftBar's own preferences for plugin folder
if [ -z "$SWIFTBAR_PLUGIN_DIR" ]; then
  PREF_DIR=$(defaults read com.ameba.SwiftBar PluginDirectory 2>/dev/null || true)
  if [ -n "$PREF_DIR" ] && [ -d "$PREF_DIR" ]; then
    SWIFTBAR_PLUGIN_DIR="$PREF_DIR"
  fi
fi

if [ -n "$SWIFTBAR_PLUGIN_DIR" ]; then
  ln -sf "$WORKTIME_DIR/worktime.1m.sh" "$SWIFTBAR_PLUGIN_DIR/worktime.1m.sh"
  echo "✓ SwiftBar plugin installed to $SWIFTBAR_PLUGIN_DIR"
else
  echo "  SwiftBar not found — skipping plugin install"
  echo "  To add later: ln -sf ~/.worktime/worktime.1m.sh <your-swiftbar-plugins-folder>/worktime.1m.sh"
fi

echo ""
echo "✓ Done! Run: worktime"
