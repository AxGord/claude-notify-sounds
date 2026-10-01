#!/bin/bash
INPUT=$(cat)

# Skip sound for sub-agent completions
if echo "$INPUT" | grep -q '"hook_event_name":[[:space:]]*"SubagentStop"'; then
  exit 0
fi

# Skip sound only when the turn is not a real completion:
# - subagent/workflow tasks always complete and re-invoke the main agent, so
#   any Stop while one is still running is not the real finish — even across
#   turn boundaries (the agent may wake on a task notification, reply, and
#   wait again);
# - shell tasks may never complete (dev servers, watchers), so only a task
#   launched seconds before the Stop ("started it and now waiting") counts —
#   see the grace check below.
# The id/type adjacency matches the current payload serializer; if the key
# order ever changes, nothing matches and the sound plays — fail open.
NORM=$(printf '%s' "$INPUT" | tr -d ' \n\t')
if printf '%s' "$NORM" | grep -q '"background_tasks":\[{'; then
  if printf '%s' "$NORM" | grep -Eq '"id":"[^"]*","type":"(subagent|workflow)"'; then
    exit 0
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

. "$(dirname "$0")/play-sound.sh"

# A turn the CLI told to wrap up on the usage limit (wrap-up allowance) ends with
# a normal Stop, not StopFailure — it is the limit stop. The CLI writes that note
# to the transcript under the turn's promptId with usageLimitNote "wrap_up"
# ("release" when the limit lifts). Any lookup failure — plain stop sound.
# Reads raw INPUT, not NORM: stripping whitespace would break paths with spaces.
json_str() {
  printf '%s' "$INPUT" | grep -Eo "\"$1\":[[:space:]]*\"[^\"]*\"" | head -1 | sed 's/.*"\([^"]*\)"$/\1/'
}
PROMPT_ID=$(json_str prompt_id)
TRANSCRIPT=$(json_str transcript_path)
if [ -n "$PROMPT_ID" ] && [ -f "$TRANSCRIPT" ] &&
  grep -aF "\"promptId\":\"$PROMPT_ID\"" "$TRANSCRIPT" | grep -Eo '"usageLimitNote":"[^"]*"' | tail -1 | grep -q '"wrap_up"'; then
  play_limit_sound "$(json_str session_id)"
  exit 0
fi

play_sound Basso.aiff dialog-warning.oga 'Windows Exclamation.wav'
