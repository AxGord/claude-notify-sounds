#!/bin/bash
INPUT=$(cat)

# Skip sound for sub-agent completions
if echo "$INPUT" | grep -q '"hook_event_name":[[:space:]]*"SubagentStop"'; then
  exit 0
fi

# Skip sound only when a background task STARTED THIS TURN is still running —
# work is not actually finished. Tasks already running at the previous Stop
# (dev servers, watchers) are long-lived and must not silence the sound forever.
# Task ids seen at the previous Stop are kept in a per-session state file.
# The id grep also matches session_crons ids — harmless: same first-sighting
# semantics, a stable cron id never suppresses the sound after its first Stop.
NORM=$(printf '%s' "$INPUT" | tr -d ' \n\t')
if printf '%s' "$NORM" | grep -q '"background_tasks":\[{'; then
  SESSION=$(printf '%s' "$NORM" | grep -o '"session_id":"[^"]*"' | head -1 | cut -d'"' -f4)
  IDS=$(printf '%s' "$NORM" | grep -o '"id":"[^"]*"' | cut -d'"' -f4 | sort -u)
  STATE_DIR="${TMPDIR:-/tmp}/claude-notify-sounds"
  STATE_FILE="$STATE_DIR/seen-${SESSION:-unknown}"
  PREV=$(cat "$STATE_FILE" 2>/dev/null)
  mkdir -p "$STATE_DIR" 2>/dev/null
  # Unpersistable state would suppress the sound on every turn — fail open
  if { printf '%s\n' "$IDS" > "$STATE_FILE"; } 2>/dev/null; then
    NEW=$(comm -23 <(printf '%s\n' "$IDS") <(printf '%s\n' "$PREV" | sort -u))
    if [ -n "$NEW" ]; then
      exit 0
    fi
  fi
fi

case "$(uname -s)" in
  Darwin)
    afplay /System/Library/Sounds/Basso.aiff &
    ;;
  Linux)
    SOUND=/usr/share/sounds/freedesktop/stereo/dialog-warning.oga
    if command -v paplay >/dev/null 2>&1 && [ -f "$SOUND" ]; then
      paplay "$SOUND" &
    elif command -v pw-play >/dev/null 2>&1 && [ -f "$SOUND" ]; then
      pw-play "$SOUND" &
    else
      printf '\a'
    fi
    ;;
  MINGW*|MSYS*|CYGWIN*)
    powershell.exe -NoProfile -WindowStyle Hidden -Command "(New-Object Media.SoundPlayer 'C:\Windows\Media\Windows Exclamation.wav').PlaySync()" &
    ;;
  *)
    printf '\a'
    ;;
esac
