#!/bin/bash
set -e

STATE_DIR="$HOME/.worktime"
TODAY=$(date +%Y-%m-%d)
STATE_FILE="$STATE_DIR/$TODAY.log"

BREAK_THRESHOLD=60
WARNING_7H=420
LIMIT_8H=480

mkdir -p "$STATE_DIR"

write_state() {
  {
    echo "active_minutes=$active_minutes"
    echo "last_break_notified=$last_break_notified"
    echo "warning_7h_sent=$warning_7h_sent"
    echo "limit_8h_sent=$limit_8h_sent"
  } > "$STATE_FILE"
}

notify() {
  local message="$1"
  osascript -e "display notification \"$message\" with title \"Work Time Tracker\" sound name \"Glass\"" >/dev/null 2>&1 || {
    printf '[%s] Notification failed: %s\n' "$(date +'%F %T')" "$message" >> "$STATE_DIR/launchd-error.log"
  }
}

if [ ! -f "$STATE_FILE" ]; then
  active_minutes=0
  last_break_notified=0
  warning_7h_sent=0
  limit_8h_sent=0
  write_state
fi

source "$STATE_FILE"
active_minutes=${active_minutes:-0}
last_break_notified=${last_break_notified:-0}
warning_7h_sent=${warning_7h_sent:-0}
limit_8h_sent=${limit_8h_sent:-0}

IDLE_TIME=$(ioreg -c IOHIDSystem | awk '/HIDIdleTime/ {print int($NF/1000000000); exit}')
if [ -z "$IDLE_TIME" ]; then
  IDLE_TIME=999999
fi

if [ "$IDLE_TIME" -lt 90 ] && [ "$active_minutes" -lt "$LIMIT_8H" ]; then
  active_minutes=$((active_minutes + 1))

  if [ "$active_minutes" -ge $((last_break_notified + BREAK_THRESHOLD)) ]; then
    notify "Time for a break"
    last_break_notified=$(( (active_minutes / BREAK_THRESHOLD) * BREAK_THRESHOLD ))
  fi

  if [ "$active_minutes" -ge "$WARNING_7H" ] && [ "$warning_7h_sent" -eq 0 ]; then
    notify "1 hour left today"
    warning_7h_sent=1
  fi

  if [ "$active_minutes" -ge "$LIMIT_8H" ] && [ "$limit_8h_sent" -eq 0 ]; then
    notify "Daily limit reached - display will sleep now"
    limit_8h_sent=1
    write_state
    pmset displaysleepnow
  fi

  write_state
fi

echo "[$(date +'%H:%M:%S')] Active: $active_minutes min | Idle: $IDLE_TIME s"
