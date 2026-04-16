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
    echo "paused=$paused"
  } > "$STATE_FILE"
}

load_config() {
  if [ -f "$STATE_DIR/config.json" ]; then
    enable_break_notifications=$(grep -o '"enable_break_notifications": *\(true\|false\)' "$STATE_DIR/config.json" | grep -o '\(true\|false\)' || echo "true")
    enable_notification_sound=$(grep -o '"enable_notification_sound": *\(true\|false\)' "$STATE_DIR/config.json" | grep -o '\(true\|false\)' || echo "true")
    _v=$(grep -o '"break_threshold": *[0-9]*' "$STATE_DIR/config.json" | grep -o '[0-9]*')
    [ -n "$_v" ] && BREAK_THRESHOLD=$_v
    _v=$(grep -o '"daily_limit": *[0-9]*' "$STATE_DIR/config.json" | grep -o '[0-9]*')
    if [ -n "$_v" ]; then
      LIMIT_8H=$_v
      WARNING_7H=$(( LIMIT_8H - 60 ))
    fi
  else
    enable_break_notifications="true"
    enable_notification_sound="true"
  fi
}

notify() {
  local message="$1"
  local notification_type="${2:-break}"  # break, warning, or limit

  # Check if this notification type should be shown
  if [ "$notification_type" = "break" ] && [ "$enable_break_notifications" != "true" ]; then
    return
  fi

  # Build the osascript command with optional sound
  local sound_clause=""
  if [ "$enable_notification_sound" = "true" ]; then
    sound_clause='sound name "Glass"'
  fi

  osascript -e "display notification \"$message\" with title \"Work Time Tracker\" $sound_clause" >/dev/null 2>&1 || {
    printf '[%s] Notification failed: %s\n' "$(date +'%F %T')" "$message" >> "$STATE_DIR/launchd-error.log"
  }
}

if [ ! -f "$STATE_FILE" ]; then
  active_minutes=0
  last_break_notified=0
  warning_7h_sent=0
  limit_8h_sent=0
  paused=0
  write_state
fi

source "$STATE_FILE"
load_config
active_minutes=${active_minutes:-0}
last_break_notified=${last_break_notified:-0}
warning_7h_sent=${warning_7h_sent:-0}
limit_8h_sent=${limit_8h_sent:-0}
paused=${paused:-0}

# Handle --toggle-pause command
if [ "${1:-}" = "--toggle-pause" ]; then
  if [ "$paused" -eq 1 ]; then
    paused=0
  else
    paused=1
  fi
  write_state
  exit 0
fi

IDLE_TIME=$(ioreg -c IOHIDSystem | awk '/HIDIdleTime/ {print int($NF/1000000000); exit}')
if [ -z "$IDLE_TIME" ]; then
  IDLE_TIME=999999
fi

if [ "$paused" -eq 0 ] && [ "$IDLE_TIME" -lt 90 ]; then
  active_minutes=$((active_minutes + 1))

  if [ "$active_minutes" -ge $((last_break_notified + BREAK_THRESHOLD)) ]; then
    notify "Time for a break" "break"
    last_break_notified=$(( (active_minutes / BREAK_THRESHOLD) * BREAK_THRESHOLD ))
  fi

  if [ "$active_minutes" -ge "$WARNING_7H" ] && [ "$warning_7h_sent" -eq 0 ]; then
    notify "1 hour left today" "warning"
    warning_7h_sent=1
  fi

  if [ "$active_minutes" -ge "$LIMIT_8H" ] && [ "$limit_8h_sent" -eq 0 ]; then
    notify "Daily limit reached - display will sleep now" "limit"
    limit_8h_sent=1
    pmset displaysleepnow
  fi

  write_state
fi

echo "[$(date +'%H:%M:%S')] Active: $active_minutes min | Idle: $IDLE_TIME s"
