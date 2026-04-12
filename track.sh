#!/bin/bash
set -e

STATE_DIR=~/.worktime
TODAY=$(date +%Y-%m-%d)
STATE_FILE="$STATE_DIR/$TODAY.log"
LAST_BREAK_FILE="$STATE_DIR/last_break_notified.txt"

# Create state directory if needed
mkdir -p "$STATE_DIR"

# Initialize today's state if not exists
if [ ! -f "$STATE_FILE" ]; then
  echo "active_minutes=0" > "$STATE_FILE"
  echo "warning_7h_sent=0" >> "$STATE_FILE"
  echo "limit_8h_sent=0" >> "$STATE_FILE"
fi

# Read current state
source "$STATE_FILE"
active_minutes=${active_minutes:-0}
warning_7h_sent=${warning_7h_sent:-0}
limit_8h_sent=${limit_8h_sent:-0}

# Check idle time (HIDIdleTime)
IDLE_TIME=$(ioreg -c IOHIDSystem | awk '/HIDIdleTime/ {print int($NF/1000000000); exit}')
if [ -z "$IDLE_TIME" ]; then
  IDLE_TIME=999999
fi

# If idle < 90s, increment active minutes
if [ "$IDLE_TIME" -lt 90 ]; then
  if [ $active_minutes -lt 480 ]; then
    active_minutes=$((active_minutes + 1))

    # Thresholds
    BREAK_THRESHOLD=60
    WARNING_7H=420
    LIMIT_8H=480

    # Send notification at 60 min (time for a break)
    if [ $active_minutes -ge $BREAK_THRESHOLD ] && [ $active_minutes -lt $((BREAK_THRESHOLD + 1)) ]; then
      osascript -e "display notification \"Time for a break\" with title \"Work Time Tracker\" sound name \"Glass\""
      echo "$active_minutes" > "$LAST_BREAK_FILE"
    fi

    # Send warning at 7h
    if [ $active_minutes -ge $WARNING_7H ] && [ $active_minutes -lt $((WARNING_7H + 1)) ] && [ "$warning_7h_sent" -eq 0 ]; then
      osascript -e 'display notification "1 hour left today" with title "Work Time Tracker" sound name "Glass"'
      warning_7h_sent=1
    fi

    # Send limit notification at 8h
    if [ $active_minutes -ge $LIMIT_8H ] && [ $active_minutes -lt $((LIMIT_8H + 1)) ] && [ "$limit_8h_sent" -eq 0 ]; then
      osascript -e 'display notification "Daily limit reached - display will sleep now" with title "Work Time Tracker" sound name "Glass"'
      pmset displaysleepnow
      limit_8h_sent=1
    fi

    # Write updated state
    echo "active_minutes=$active_minutes" > "$STATE_FILE"
    echo "warning_7h_sent=$warning_7h_sent" >> "$STATE_FILE"
    echo "limit_8h_sent=$limit_8h_sent" >> "$STATE_FILE"
  fi
fi

# Update last_break_file (even if no increment, for checking against threshold)
echo "$active_minutes" > "$LAST_BREAK_FILE"

# Output for launchd (optional, helpful for debugging)
echo "[$(date +'%H:%M:%S')] Active: $active_minutes min"
