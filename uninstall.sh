#!/bin/bash

WORKTIME_DIR="$HOME/.worktime"
LABEL="com.son.worktime"
PLIST="$HOME/Library/LaunchAgents/com.son.worktime.plist"

echo "Uninstalling workbar..."

# Stop and remove launchd agent
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
rm -f "$PLIST"
echo "✓ Tracker stopped"

# Remove SwiftBar plugin (search known locations)
for dir in \
  "$WORKTIME_DIR/plugins" \
  "$HOME/Library/Application Support/SwiftBar/Plugins" \
  "$HOME/Documents/SwiftBar" \
  "$HOME/SwiftBar" \
  "$(defaults read com.ameba.SwiftBar PluginDirectory 2>/dev/null || true)"
do
  rm -f "$dir/worktime.1m.sh" 2>/dev/null || true
done
echo "✓ SwiftBar plugin removed"

# Remove scripts, keep daily logs and config
rm -f \
  "$WORKTIME_DIR/track.sh" \
  "$WORKTIME_DIR/worktime" \
  "$WORKTIME_DIR/worktime.1m.sh" \
  "$WORKTIME_DIR/stats.sh" \
  "$WORKTIME_DIR/setup.sh" \
  "$WORKTIME_DIR/launchd.log" \
  "$WORKTIME_DIR/launchd-error.log" \
  "$WORKTIME_DIR/last_break_notified.txt"
rm -rf "$WORKTIME_DIR/plugins"
echo "✓ Scripts removed"

echo ""
echo "✓ workbar uninstalled"
echo "  Your stats logs are preserved in $WORKTIME_DIR"
