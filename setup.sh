#!/bin/bash
set -e

WORKTIME_DIR=~/.worktime
TRACKER_DIR=/Users/sonwork/Workspace/worktime-tracker

echo "Setting up Work Time Tracker..."

# Create worktime directory
mkdir -p "$WORKTIME_DIR"

# Copy scripts
cp "$TRACKER_DIR/track.sh" "$WORKTIME_DIR/"
cp "$TRACKER_DIR/worktime" "$WORKTIME_DIR/"
cp "$TRACKER_DIR/worktime.1m.sh" "$WORKTIME_DIR/"

# Make executable
chmod +x "$WORKTIME_DIR/track.sh"
chmod +x "$WORKTIME_DIR/worktime"
chmod +x "$WORKTIME_DIR/worktime.1m.sh"

# Create symlink in ~/.local/bin
if [ ! -L ~/.local/bin/worktime ]; then
  mkdir -p ~/.local/bin
  ln -sf "$WORKTIME_DIR/worktime" ~/.local/bin/worktime
  echo "✓ Symlinked to ~/.local/bin/worktime"
fi

echo ""
echo "✓ Setup complete!"
echo ""
echo "To use the command, add this to your shell config (~/.zshrc or ~/.bash_profile):"
echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
echo ""
echo "Then source it:"
echo "  source ~/.zshrc  # or ~/.bash_profile"
echo ""
echo "To check status now: $WORKTIME_DIR/worktime"
echo "To start the tracker now: launchctl load ~/Library/LaunchAgents/com.son.worktime.plist"
