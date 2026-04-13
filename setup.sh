#!/bin/bash
set -e

WORKTIME_DIR="$HOME/.worktime"
TRACKER_DIR="/Users/sonwork/Workspace/worktime-tracker"
PLIST_TEMPLATE="$TRACKER_DIR/com.son.worktime.plist"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
PLIST_DEST="$LAUNCH_AGENTS_DIR/com.son.worktime.plist"
LABEL="com.son.worktime"

echo "Setting up Work Time Tracker..."

mkdir -p "$WORKTIME_DIR" "$LAUNCH_AGENTS_DIR" "$HOME/.local/bin"

cp "$TRACKER_DIR/track.sh" "$WORKTIME_DIR/"
cp "$TRACKER_DIR/worktime" "$WORKTIME_DIR/"
cp "$TRACKER_DIR/worktime.1m.sh" "$WORKTIME_DIR/"
cp "$TRACKER_DIR/stats.sh" "$WORKTIME_DIR/"
chmod +x "$WORKTIME_DIR/track.sh" "$WORKTIME_DIR/worktime" "$WORKTIME_DIR/worktime.1m.sh" "$WORKTIME_DIR/stats.sh"

ln -sf "$WORKTIME_DIR/worktime" "$HOME/.local/bin/worktime"
echo "✓ Symlinked to ~/.local/bin/worktime"

HOME_ESCAPED=$(printf '%s\n' "$HOME" | sed 's/[\/&]/\\&/g')
sed "s#__HOME__#$HOME_ESCAPED#g" "$PLIST_TEMPLATE" > "$PLIST_DEST"
echo "✓ Installed launchd agent: $PLIST_DEST"

launchctl bootout "gui/$(id -u)/$LABEL" >/dev/null 2>&1 || true
launchctl bootstrap "gui/$(id -u)" "$PLIST_DEST"
launchctl kickstart -k "gui/$(id -u)/$LABEL"
echo "✓ Tracker loaded and started"

echo ""
echo "✓ Setup complete!"
echo ""
echo "Add to shell config (~/.zshrc or ~/.bash_profile):"
echo '  export PATH="$HOME/.local/bin:$PATH"'
echo ""
echo "SwiftBar: install only ~/.worktime/worktime.1m.sh as plugin."
echo "Do not copy track.sh, worktime, or stats.sh into SwiftBar plugin folder."
echo ""
echo "Check status: worktime"
echo "Launchd logs: ~/.worktime/launchd.log and ~/.worktime/launchd-error.log"
