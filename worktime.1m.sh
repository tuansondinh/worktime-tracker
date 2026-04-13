#!/bin/bash
STATE_DIR=~/.worktime
TODAY=$(date +%Y-%m-%d)
STATE_FILE="$STATE_DIR/$TODAY.log"

if [ ! -f "$STATE_FILE" ]; then
  echo "0m"
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

if [ $active_minutes -ge $LIMIT_8H ]; then
  echo "Status: 🛑 Daily limit reached"
elif [ $active_minutes -ge $WARNING_7H ]; then
  remaining_limit=$((LIMIT_8H - active_minutes))
  echo "Status: ⚠️  1 hour left  (${remaining_limit} min to limit)"
elif [ $active_minutes -ge $BREAK_THRESHOLD ]; then
  echo "Status: ☕ Time for a break!"
else
  mins_to_break=$((BREAK_THRESHOLD - active_minutes))
  echo "Status: ✓ On track"
  echo "Next break in: ${mins_to_break} min"
fi

if [ $active_minutes -lt $LIMIT_8H ]; then
  mins_to_limit=$((LIMIT_8H - active_minutes))
  limit_h=$((mins_to_limit / 60))
  limit_m=$((mins_to_limit % 60))
  echo "Daily limit in: ${limit_h}h ${limit_m}m"
fi

echo "---"
echo "Break threshold: ${BREAK_THRESHOLD} min | Daily limit: ${LIMIT_8H} min"
