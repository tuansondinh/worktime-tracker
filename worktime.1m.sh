#!/bin/bash
STATE_DIR=~/.worktime
TODAY=$(date +%Y-%m-%d)
STATE_FILE="$STATE_DIR/$TODAY.log"

if [ ! -f "$STATE_FILE" ]; then
  echo "0m"
  exit 0
fi

source "$STATE_FILE"

# Constants (defaults, may be overridden by config)
BREAK_THRESHOLD=60
WARNING_7H=420
LIMIT_8H=480

# Load user config overrides
cfg_break_notif="true"
cfg_sound="true"
if [ -f "$STATE_DIR/config.json" ]; then
  _bt=$(grep -o '"break_threshold": *[0-9]*' "$STATE_DIR/config.json" | grep -o '[0-9]*')
  [ -n "$_bt" ] && BREAK_THRESHOLD=$_bt
  _v=$(grep -o '"enable_break_notifications": *\(true\|false\)' "$STATE_DIR/config.json" | grep -o '\(true\|false\)')
  [ -n "$_v" ] && cfg_break_notif="$_v"
  _v=$(grep -o '"enable_notification_sound": *\(true\|false\)' "$STATE_DIR/config.json" | grep -o '\(true\|false\)')
  [ -n "$_v" ] && cfg_sound="$_v"
fi

paused=${paused:-0}

# Format active time
hours=$((active_minutes / 60))
mins=$((active_minutes % 60))

# Colors based on thresholds
if [ "$paused" -eq 1 ]; then
  color="⏸"  # Paused
elif [ $active_minutes -ge $LIMIT_8H ]; then
  color="🔴"  # Red for limit
elif [ $active_minutes -ge $WARNING_7H ]; then
  color="🟡"  # Yellow at 7h warning
else
  color="🟢"  # Green before 7h
fi

# Compact format for menu bar
echo "${color}${hours}h ${mins}m"

# Dropdown (always emitted; SwiftBar renders lines after first ---)
echo "---"
echo "Today: ${hours}h ${mins}m  (${active_minutes} min worked)"
echo "---"

if [ "$paused" -eq 1 ]; then
  echo "Status: ⏸ Tracking paused"
  echo "▶ Resume | bash=$HOME/.worktime/track.sh param1=--toggle-pause terminal=false refresh=true"
elif [ $active_minutes -ge $LIMIT_8H ]; then
  echo "Status: 🛑 Daily limit reached"
  echo "⏸ Pause | bash=$HOME/.worktime/track.sh param1=--toggle-pause terminal=false refresh=true"
elif [ $active_minutes -ge $WARNING_7H ]; then
  remaining_limit=$((LIMIT_8H - active_minutes))
  echo "Status: ⚠️  1 hour left  (${remaining_limit} min to limit)"
  echo "⏸ Pause | bash=$HOME/.worktime/track.sh param1=--toggle-pause terminal=false refresh=true"
elif [ $active_minutes -ge $BREAK_THRESHOLD ]; then
  echo "Status: ☕ Time for a break!"
  echo "⏸ Pause | bash=$HOME/.worktime/track.sh param1=--toggle-pause terminal=false refresh=true"
else
  mins_to_break=$((BREAK_THRESHOLD - active_minutes))
  echo "Status: ✓ On track"
  echo "Next break in: ${mins_to_break} min"
  echo "⏸ Pause | bash=$HOME/.worktime/track.sh param1=--toggle-pause terminal=false refresh=true"
fi

if [ $active_minutes -lt $LIMIT_8H ]; then
  mins_to_limit=$((LIMIT_8H - active_minutes))
  limit_h=$((mins_to_limit / 60))
  limit_m=$((mins_to_limit % 60))
  echo "Daily limit in: ${limit_h}h ${limit_m}m"
fi

echo "---"

# Weekly stats
STATS_JSON=$(bash "$HOME/.local/bin/stats.sh" --week --json 2>/dev/null)
if [ $? -eq 0 ] && [ -n "$STATS_JSON" ]; then
  week_total=$(echo "$STATS_JSON" | grep -o '"total_hours":"[^"]*"' | cut -d'"' -f4)
  week_days=$(echo "$STATS_JSON" | grep -o '"working_days":[0-9]*' | cut -d':' -f2)
  week_avg=$(echo "$STATS_JSON" | grep -o '"avg_per_day":"[^"]*"' | cut -d'"' -f4)
  echo "This Week: ${week_total}  (${week_days} days, avg ${week_avg})"
fi

echo "---"
echo "Break threshold: ${BREAK_THRESHOLD} min | Daily limit: ${LIMIT_8H} min"

echo "---"

# Settings submenu
if [ "$cfg_break_notif" = "true" ]; then
  echo "Settings | dropdown=false"
  echo "--Break notifications: ✓ on | bash=$HOME/.worktime/worktime param1=config param2=break param3=off terminal=false refresh=true"
else
  echo "Settings | dropdown=false"
  echo "--Break notifications: ✗ off | bash=$HOME/.worktime/worktime param1=config param2=break param3=on terminal=false refresh=true"
fi

if [ "$cfg_sound" = "true" ]; then
  echo "--Notification sound: ✓ on | bash=$HOME/.worktime/worktime param1=config param2=sound param3=off terminal=false refresh=true"
else
  echo "--Notification sound: ✗ off | bash=$HOME/.worktime/worktime param1=config param2=sound param3=on terminal=false refresh=true"
fi

echo "--Break time: ${BREAK_THRESHOLD} min | dropdown=false"
echo "----30 min | bash=$HOME/.worktime/worktime param1=config param2=break-time param3=30 terminal=false refresh=true"
echo "----45 min | bash=$HOME/.worktime/worktime param1=config param2=break-time param3=45 terminal=false refresh=true"
echo "----60 min | bash=$HOME/.worktime/worktime param1=config param2=break-time param3=60 terminal=false refresh=true"
echo "----90 min | bash=$HOME/.worktime/worktime param1=config param2=break-time param3=90 terminal=false refresh=true"
echo "----120 min | bash=$HOME/.worktime/worktime param1=config param2=break-time param3=120 terminal=false refresh=true"
