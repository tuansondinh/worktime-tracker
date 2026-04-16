#!/bin/bash
set -e

WORKTIME_DIR="$HOME/.worktime"
TRACKER_DIR="$(cd "$(dirname "$0")" && pwd)"
PLIST_TEMPLATE="$TRACKER_DIR/com.son.worktime.plist"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
PLIST_DEST="$LAUNCH_AGENTS_DIR/com.son.worktime.plist"
LABEL="com.son.worktime"

echo "Setting up workbar..."

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

# Write default config only on fresh install (don't overwrite existing user settings)
if [ ! -f "$WORKTIME_DIR/config.json" ]; then
  printf '{"enable_break_notifications": true, "enable_notification_sound": true, "break_threshold": 60, "daily_limit": 480}\n' > "$WORKTIME_DIR/config.json"
  echo "✓ Created default config"
fi

HOME_ESCAPED=$(printf '%s\n' "$HOME" | sed 's/[\/&]/\\&/g')
sed "s#__HOME__#$HOME_ESCAPED#g" "$PLIST_TEMPLATE" > "$PLIST_DEST"
echo "✓ Installed launchd agent"

launchctl bootout "gui/$(id -u)/$LABEL" >/dev/null 2>&1 || true
launchctl bootstrap "gui/$(id -u)" "$PLIST_DEST"
launchctl kickstart -k "gui/$(id -u)/$LABEL"
echo "✓ Tracker started"

# Set up SwiftBar plugins folder and link plugin
SWIFTBAR_PLUGIN_DIR=""

# Check if user already has a configured plugins folder
PREF_DIR=$(defaults read com.ameba.SwiftBar PluginDirectory 2>/dev/null || true)
if [ -n "$PREF_DIR" ] && [ -d "$PREF_DIR" ]; then
  SWIFTBAR_PLUGIN_DIR="$PREF_DIR"
fi

# Check common locations
if [ -z "$SWIFTBAR_PLUGIN_DIR" ]; then
  for dir in "$HOME/Library/Application Support/SwiftBar/Plugins" "$HOME/Documents/SwiftBar" "$HOME/SwiftBar"; do
    if [ -d "$dir" ]; then
      SWIFTBAR_PLUGIN_DIR="$dir"
      break
    fi
  done
fi

# No folder found — create default
if [ -z "$SWIFTBAR_PLUGIN_DIR" ]; then
  SWIFTBAR_PLUGIN_DIR="$HOME/SwiftBar"
  mkdir -p "$SWIFTBAR_PLUGIN_DIR"
  echo "✓ SwiftBar plugins folder created at ~/SwiftBar"
fi

# Always ensure SwiftBar knows which folder to use
defaults write com.ameba.SwiftBar PluginDirectory "$SWIFTBAR_PLUGIN_DIR"

rm -rf "$SWIFTBAR_PLUGIN_DIR/worktime.1m.sh"
ln -sf "$WORKTIME_DIR/worktime.1m.sh" "$SWIFTBAR_PLUGIN_DIR/worktime.1m.sh"
echo "✓ SwiftBar plugin linked to $SWIFTBAR_PLUGIN_DIR"

# Launch SwiftBar so it picks up the plugin
open -a SwiftBar 2>/dev/null || true

echo ""
echo "✓ Done! Run: worktime"
