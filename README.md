# Work Time Tracker

Track active laptop usage, cap at 8h/day with break reminders and warnings.

## Features

- **Idle-aware tracking**: Only counts time when laptop is in use (idle < 90s)
- **Daily 8h limit**: Soft lock via display sleep at 8h
- **Break reminders**: Every 60 active minutes
- **7h warning**: "1 hour left today" notification
- **Status command**: `worktime` shows today's stats
- **SwiftBar plugin**: Optional menu bar integration

## Installation

```bash
cd /Users/sonwork/Workspace/worktime-tracker
./setup.sh
```

This will:
1. Create `~/.worktime/` directory and scripts
2. Symlink `worktime` to `~/.local/bin/`
3. Install launchd plist
4. Start the tracker (if previously loaded, will be reloaded)

## Usage

```bash
# Add to your PATH in ~/.zshrc or ~/.bash_profile:
export PATH="$HOME/.local/bin:$PATH"

# Then use:
worktime
worktime --verbose
```

## Configuration

State files live in `~/.worktime/YYYY-MM-DD.log`:

```
active_minutes=204
last_break_notified=180
warning_7h_sent=0
limit_8h_sent=0
```

Manual reset: edit today's log file or delete it to start fresh.

## Scripts

- `track.sh` - Main tracker (runs every 60s via launchd)
- `worktime` - Status command (symlinked to `~/.local/bin/worktime`)
- `worktime.1m.sh` - SwiftBar plugin (optional)

## Uninstall

```bash
launchctl unload ~/Library/LaunchAgents/com.son.worktime.plist
rm -rf ~/.worktime
rm ~/.local/bin/worktime
rm ~/Library/LaunchAgents/com.son.worktime.plist
```
