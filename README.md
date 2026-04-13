# Work Time Tracker

Track active macOS laptop usage, cap at 8h/day with break reminders and warnings.

## Install

```bash
npm install -g @tuan_son.dinh/worktime-tracker
```

That's it. SwiftBar and the tracker are installed automatically. Your active work time appears in the menu bar, updated every minute.

> Requires [Homebrew](https://brew.sh). If not installed: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`

## Features

- **Menu bar widget**: Live time display via SwiftBar, updated every minute
- **Idle-aware tracking**: Only counts time when laptop is in use (idle < 90s)
- **Daily 8h limit**: Soft lock via display sleep at 8h
- **Break reminders**: Every 60 active minutes
- **7h warning**: "1 hour left today" notification

## Usage

```bash
worktime              # today's active time
worktime --verbose    # detailed status
worktime stats        # this week's stats
worktime stats --month
worktime stats --all
worktime stats --json
```

## Requirements

- macOS only
- Node.js ≥ 14

## Uninstall

```bash
launchctl unload ~/Library/LaunchAgents/com.son.worktime.plist
rm -rf ~/.worktime
rm ~/Library/LaunchAgents/com.son.worktime.plist
npm uninstall -g worktime-tracker
```
