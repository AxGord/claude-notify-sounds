#!/bin/bash
INPUT=$(cat)

# Skip sound for sub-agent completions
if echo "$INPUT" | grep -q '"hook_event_name":[[:space:]]*"SubagentStop"'; then
  exit 0
fi

# Skip sound only when the turn is not a real completion:
# - subagent/workflow tasks always complete and re-invoke the main agent, so
#   a first-sighted one still running means the real finish comes later;
# - shell tasks may never complete (dev servers, watchers), so only a task
#   launched seconds before the Stop ("started it and now waiting") counts —
#   see the grace check below.
# Ids seen at a previous Stop are kept in a per-session state file, so an
# agent task surviving a turn boundary stops suppressing.
# The id/type adjacency matches the current payload serializer; if the key
# order ever changes, nothing matches and the sound plays — fail open.
NORM=$(printf '%s' "$INPUT" | tr -d ' \n\t')
if printf '%s' "$NORM" | grep -q '"background_tasks":\[{'; then
  SESSION=$(printf '%s' "$NORM" | grep -o '"session_id":"[^"]*"' | head -1 | cut -d'"' -f4)
  IDS=$(printf '%s' "$NORM" | grep -Eo '"id":"[^"]*","type":"(subagent|workflow)"' | cut -d'"' -f4 | sort -u)
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

  # A shell task launched moments before this Stop means the agent started it
  # and is waiting — its completion re-invokes the agent, the real finish comes
  # later. Older shell tasks (dev servers, watchers) never block the sound.
  # Launch time = birth time of the task output file; lookup failure — fail open.
  GRACE="${CLAUDE_NOTIFY_SOUNDS_GRACE:-30}"
  case "$GRACE" in ''|*[!0-9]*) GRACE=30 ;; esac
  SHELL_IDS=$(printf '%s' "$NORM" | grep -Eo '"id":"[^"]*","type":"shell"' | cut -d'"' -f4)
  NOW=$(date +%s)
  for TASK_ID in $SHELL_IDS; do
    for F in /tmp/claude-$(id -u)/*/*/tasks/"$TASK_ID".output; do
      [ -e "$F" ] || continue
      # GNU stat first: BSD spelling (-f %B) is a VALID GNU call that returns
      # filesystem block size, so the reverse order breaks silently on Linux
      BORN=$(stat -c %W "$F" 2>/dev/null || stat -f %B "$F" 2>/dev/null)
      case "$BORN" in ''|*[!0-9]*|0) continue ;; esac
      if [ $((NOW - BORN)) -lt "$GRACE" ]; then
        exit 0
      fi
    done
  done
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
