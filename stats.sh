#!/bin/bash
# Worktime Tracker - Usage Statistics
# Usage: worktime stats [--week|--month|--all] [--json]

STATE_DIR=~/.worktime
TODAY=$(date +%Y-%m-%d)

# Parse arguments
PERIOD="week"
JSON_OUTPUT=false
for arg in "$@"; do
  case "$arg" in
    --week)   PERIOD="week" ;;
    --month)  PERIOD="month" ;;
    --all)    PERIOD="all" ;;
    --json)   JSON_OUTPUT=true ;;
    --help|-h)
      echo "Usage: worktime stats [--week|--month|--all] [--json]"
      echo ""
      echo "Options:"
      echo "  --week   Show this week's stats (default)"
      echo "  --month  Show this month's stats"
      echo "  --all    Show all-time stats"
      echo "  --json   Output as JSON"
      exit 0
      ;;
  esac
done

# Calculate date range based on period
case "$PERIOD" in
  week)
    # Monday of current week
    START_DATE=$(date -v-monday +%Y-%m-%d 2>/dev/null || date -d "last monday" +%Y-%m-%d 2>/dev/null)
    ;;
  month)
    START_DATE=$(date +%Y-%m-01)
    ;;
  all)
    START_DATE="2000-01-01"
    ;;
esac

# Collect log files in range
log_files=()
if [ -d "$STATE_DIR" ]; then
  for file in $(ls "$STATE_DIR"/*.log 2>/dev/null); do
    [ -f "$file" ] && log_files+=("$file")
  done
fi

# If no log files at all, check if today's exists
if [ ${#log_files[@]} -eq 0 ]; then
  if [ "$JSON_OUTPUT" = true ]; then
    echo '{"error":"No data found","total_days":0}'
  else
    echo "No data found. Start tracking with: worktime"
  fi
  exit 1
fi

# Process log files
total_minutes=0
total_days=0
max_day_minutes=0
max_day_date=""
limit_reached_days=0
under_60_days=0
daily_totals=()
weekday_totals=(0 0 0 0 0 0 0)  # Mon=0 .. Sun=6

for log_file in "${log_files[@]}"; do
  filename=$(basename "$log_file")
  date_str="${filename%.log}"

  # Filter by date range
  if [[ "$date_str" < "$START_DATE" ]] || [[ "$date_str" > "$TODAY" ]]; then
    continue
  fi

  # Extract active_minutes from log file
  if [ -f "$log_file" ]; then
    minutes=$(grep -E '^active_minutes=' "$log_file" 2>/dev/null | head -1 | cut -d'=' -f2)
    minutes=${minutes:-0}

    if [ "$minutes" -gt 0 ]; then
      total_minutes=$((total_minutes + minutes))
      total_days=$((total_days + 1))
      daily_totals+=("$date_str:$minutes")

      # Track max day
      if [ "$minutes" -gt "$max_day_minutes" ]; then
        max_day_minutes=$minutes
        max_day_date="$date_str"
      fi

      # Count limit reached (>=480 min)
      if [ "$minutes" -ge 480 ]; then
        limit_reached_days=$((limit_reached_days + 1))
      fi

      # Count light days (<60 min)
      if [ "$minutes" -lt 60 ]; then
        under_60_days=$((under_60_days + 1))
      fi

      # Accumulate by weekday
      dow=$(date -j -f "%Y-%m-%d" "$date_str" +%u 2>/dev/null || date -d "$date_str" +%u 2>/dev/null)
      dow=$((dow - 1))  # 0=Mon .. 6=Sun
      if [ "$dow" -ge 0 ] && [ "$dow" -le 6 ]; then
        weekday_totals[$dow]=$((weekday_totals[$dow] + minutes))
      fi
    fi
  fi
done

if [ $total_days -eq 0 ]; then
  if [ "$JSON_OUTPUT" = true ]; then
    echo "{\"period\":\"$PERIOD\",\"start_date\":\"$START_DATE\",\"total_days\":0}"
  else
    echo "No data found for this period (since $START_DATE)."
  fi
  exit 1
fi

# Calculate averages
avg_minutes=$((total_minutes / total_days))
avg_hours=$((avg_minutes / 60))
avg_mins=$((avg_minutes % 60))

total_hours=$((total_minutes / 60))
total_remainder=$((total_minutes % 60))

# Format period label
case "$PERIOD" in
  week)  period_label="This Week" ;;
  month) period_label="This Month" ;;
  all)   period_label="All Time" ;;
esac

if [ "$JSON_OUTPUT" = true ]; then
  # Build daily array
  daily_json="["
  for entry in "${daily_totals[@]}"; do
    d="${entry%%:*}"
    m="${entry##*:}"
    daily_json+="{\"date\":\"$d\",\"minutes\":$m},"
  done
  daily_json="${daily_json%,}]"

  # Build weekday array
  wd_names=("Mon" "Tue" "Wed" "Thu" "Fri" "Sat" "Sun")
  wd_json="["
  for i in 0 1 2 3 4 5 6; do
    wh=$((weekday_totals[$i] / 60))
    wm=$((weekday_totals[$i] % 60))
    wd_json="${wd_json}{\"day\":\"${wd_names[$i]}\",\"minutes\":${weekday_totals[$i]},\"hours\":\"${wh}h ${wm}m\"},"
  done
  wd_json="${wd_json%,}]"

  cat <<EOF
{
  "period": "$PERIOD",
  "period_label": "$period_label",
  "start_date": "$START_DATE",
  "today": "$TODAY",
  "summary": {
    "total_hours": "$total_hours h $total_remainder m",
    "total_minutes": $total_minutes,
    "working_days": $total_days,
    "avg_per_day": "$avg_hours h $avg_mins m",
    "avg_minutes": $avg_minutes,
    "best_day": {"date": "$max_day_date", "minutes": $max_day_minutes},
    "limit_reached_days": $limit_reached_days,
    "light_days": $under_60_days
  },
  "daily": $daily_json,
  "by_weekday": $wd_json
}
EOF
  exit 0
fi

# Human-readable output
echo ""
echo "📊 Work Time Statistics — $period_label"
echo "   ($START_DATE → $TODAY)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Total tracked:   $total_hours h $total_remainder m"
echo "  Working days:    $total_days"
echo "  Daily average:   $avg_hours h $avg_mins m"
echo "  Best day:        $max_day_date ($(echo "scale=1; $max_day_minutes / 60" | bc) h)"
echo ""
echo "  8h limit hit:    $limit_reached_days day(s)"
echo "  Light days (<1h): $under_60_days day(s)"
echo ""

# Bar chart of daily totals (last 14 entries or all if fewer)
echo "  Daily breakdown:"
echo "  ──────────────────────────────────────"

# Determine display range (last 14 days or fewer)
display_count=${#daily_totals[@]}
if [ $display_count -gt 14 ]; then
  display_count=14
  start_idx=$((${#daily_totals[@]} - 14))
else
  start_idx=0
fi

for ((i = start_idx; i < ${#daily_totals[@]}; i++)); do
  entry="${daily_totals[$i]}"
  d="${entry%%:*}"
  m="${entry##*:}"

  # Bar width: each hour = 4 chars, max ~28 chars
  bar_len=$((m / 60 * 4))
  if [ $bar_len -gt 28 ]; then
    bar_len=28
  fi
  if [ $bar_len -eq 0 ] && [ $m -gt 0 ]; then
    bar_len=1
  fi

  # Short date format (MM-DD)
  short_date="${d:5}"

  # Color indicator
  if [ "$m" -ge 480 ]; then
    indicator="🔴"
  elif [ "$m" -ge 420 ]; then
    indicator="🟠"
  elif [ "$m" -ge 60 ]; then
    indicator="🟡"
  else
    indicator="🟢"
  fi

  bar=$(printf '█%.0s' $(seq 1 $bar_len 2>/dev/null) || printf '█%.0s' $(jot $bar_len 2>/dev/null))
  spaces=$(printf ' %.0s' $(seq 1 $((28 - bar_len)) 2>/dev/null) || printf ' %.0s' $(jot $((28 - bar_len)) 2>/dev/null))

  h=$((m / 60))
  rm=$((m % 60))
  printf "  %s %s │%s%s│ %dh %dm\n" "$indicator" "$short_date" "$bar" "$spaces" "$h" "$rm"
done

echo ""

# Weekday averages
echo "  By weekday (avg):"
echo "  ──────────────────────────────────────"

weekday_names=("Mon" "Tue" "Wed" "Thu" "Fri" "Sat" "Sun")
# Count days per weekday
weekday_counts=(0 0 0 0 0 0 0)
for entry in "${daily_totals[@]}"; do
  d="${entry%%:*}"
  dow=$(date -j -f "%Y-%m-%d" "$d" +%u 2>/dev/null || date -d "$d" +%u 2>/dev/null)
  dow=$((dow - 1))
  if [ "$dow" -ge 0 ] && [ "$dow" -le 6 ]; then
    weekday_counts[$dow]=$((weekday_counts[$dow] + 1))
  fi
done

for i in 0 1 2 3 4 5 6; do
  if [ ${weekday_counts[$i]} -eq 0 ]; then
    printf "  %-3s │ %s\n" "${weekday_names[$i]}" "—"
  else
    avg_wd=$((weekday_totals[$i] / weekday_counts[$i]))
    avg_wd_h=$((avg_wd / 60))
    avg_wd_m=$((avg_wd % 60))

    # Bar
    bar_len=$((avg_wd / 60 * 3))
    if [ $bar_len -gt 20 ]; then
      bar_len=20
    fi
    if [ $bar_len -eq 0 ] && [ $avg_wd -gt 0 ]; then
      bar_len=1
    fi
    bar=$(printf '▓%.0s' $(seq 1 $bar_len 2>/dev/null) || printf '▓%.0s' $(jot $bar_len 2>/dev/null))
    spaces=$(printf ' %.0s' $(seq 1 $((20 - bar_len)) 2>/dev/null) || printf ' %.0s' $(jot $((20 - bar_len)) 2>/dev/null))

    printf "  %-3s │%s%s│ %dh %dm (%d days)\n" "${weekday_names[$i]}" "$bar" "$spaces" "$avg_wd_h" "$avg_wd_m" "${weekday_counts[$i]}"
  fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
