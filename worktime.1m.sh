#!/bin/bash
STATE_DIR=~/.worktime
TODAY=$(date +%Y-%m-%d)
STATE_FILE="$STATE_DIR/$TODAY.log"

if [ ! -f "$STATE_FILE" ]; then
  echo "⏱ 0m"
  exit 0
fi

source "$STATE_FILE"

# Constants
BREAK_THRESHOLD=60
WARNING_7H=420
LIMIT_8H=480

# Format active time
hours=$((active_minutes / 60))
mins=$((active_minutes % 60))

# Colors based on thresholds
if [ $active_minutes -ge $LIMIT_8H ]; then
  color="⬛"  # Red for limit
elif [ $active_minutes -ge $WARNING_7H ]; then
  color="🟠"  # Orange for warning
elif [ $active_minutes -ge $BREAK_THRESHOLD ]; then
  color="🟡"  # Yellow for break reminder
else
  color="🟢"  # Green for normal
fi

# Compact format for menu bar
echo "${color}⏱ ${hours}h ${mins}m"

# Dropdown content
if [ "$DROPDOWN" = "true" ] || [ "$1" = "--dropdown" ]; then
  echo "---"
  echo "Time: $active_minutes min"

  if [ $active_minutes -ge $LIMIT_8H ]; then
    echo "Status: 🛑 Limit reached"
  elif [ $active_minutes -ge $WARNING_7H ]; then
    echo "Status: ⚠ 1 hour left"
  elif [ $active_minutes -ge $BREAK_THRESHOLD ]; then
    echo "Status: ☕ Time for a break"
  else
    echo "Status: ✓ On track"
  fi

  echo "---"
  echo "Break at: $BREAK_THRESHOLD min"
  echo "Limit at: $LIMIT_8H min"
fi
