# Fix: SwiftBar Dropdown & Notification Timing

**Confidence: 9/10**

---

## Bug 1 — SwiftBar dropdown shows no extra information

### Root cause

`worktime.1m.sh` gates the `---` separator and all dropdown lines behind:
```bash
if [ "$DROPDOWN" = "true" ] || [ "$1" = "--dropdown" ]; then
```
SwiftBar never sets that env var and never passes `--dropdown`, so the condition is always false.  
SwiftBar reads **all stdout** from the plugin: lines before the first `---` go in the menu bar; lines after go in the dropdown. Because the `---` is never printed, SwiftBar has nothing to show when the user clicks.

### Fix — `worktime.1m.sh`

1. **Remove the `if` guard entirely** — always print the `---` and dropdown lines.
2. **Enhance the dropdown** to show:
   - Worked time today (formatted as Xh Ym and raw minutes)
   - Status label (On track / Break time / ⚠ 1h left / 🛑 Limit reached)
   - Time until next break and time remaining until the 8h limit
   - Thresholds for reference (break at 60 min, limit at 480 min)
   - A `Refresh` action item (SwiftBar `bash=...` or just informational)

Concrete output skeleton SwiftBar expects:
```
🟢2h 34m          ← menu bar line
---               ← separator
Today: 154 min (2h 34m)
Status: ✓ On track
Next break in: 26 min (at 180 min)
Daily limit in: 326 min (at 480 min)
---
⚙ Break at 60 min | Limit at 480 min
```

---

## Bug 2 — Notifications fire off full-hour boundaries

### Root cause

In `track.sh`, after sending a break notification:
```bash
last_break_notified=$active_minutes
```
`active_minutes` at that moment may not be a clean multiple of `BREAK_THRESHOLD` (60).  

Example: if the user was briefly idle at minute 60 and the tracker ran again at minute 63, the notification fires at 63 and `last_break_notified=63`. The next notification threshold becomes `63+60=123`, then `183`, `243` — all drifting further from clean hour marks on every cycle.

### Fix — `track.sh`

Anchor `last_break_notified` to the **nearest lower clean multiple** of `BREAK_THRESHOLD`:
```bash
last_break_notified=$(( (active_minutes / BREAK_THRESHOLD) * BREAK_THRESHOLD ))
```

This way the boundaries stay at 60 → 120 → 180 → 240 … regardless of when exactly the script ran.

---

## Files to change

| File | Change |
|------|--------|
| `worktime.1m.sh` | Remove `DROPDOWN` guard; always emit `---` + richer dropdown |
| `track.sh` | Anchor `last_break_notified` to clean threshold boundary |

## Deployment note

After editing the source files, re-run `setup.sh` (or manually copy the two files to `~/.worktime/`) so the live copies SwiftBar and launchd use are updated.

---

## Detailed diffs (planned)

### `worktime.1m.sh` — after the menu-bar echo, replace the conditional block:

**Remove:**
```bash
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
```

**Replace with (always-on dropdown):**
```bash
# ── Dropdown (always emitted; SwiftBar renders after first ---) ──
echo "---"
echo "Today: ${hours}h ${mins}m  (${active_minutes} min worked)"
echo "---"

# Status
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

# Time to daily limit (if not yet reached)
if [ $active_minutes -lt $LIMIT_8H ]; then
  mins_to_limit=$((LIMIT_8H - active_minutes))
  limit_h=$((mins_to_limit / 60))
  limit_m=$((mins_to_limit % 60))
  echo "Daily limit in: ${limit_h}h ${limit_m}m"
fi

echo "---"
echo "Break threshold: ${BREAK_THRESHOLD} min | Daily limit: ${LIMIT_8H} min"
```

### `track.sh` — anchor `last_break_notified`:

**Remove:**
```bash
    notify "Time for a break"
    last_break_notified=$active_minutes
```

**Replace with:**
```bash
    notify "Time for a break"
    last_break_notified=$(( (active_minutes / BREAK_THRESHOLD) * BREAK_THRESHOLD ))
```
