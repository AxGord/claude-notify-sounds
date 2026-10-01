#!/bin/bash
# StopFailure hook, matcher "rate_limit": the turn ended on a usage limit
INPUT=$(cat)

# Subagent limit stops (payload carries agent_id) are not the session's stop:
# during the wrap-up allowance subagents keep going and each is rejected on its
# own. The session's limit stop is the main agent's — a StopFailure here, or a
# wrap-up Stop in notify-stop.sh.
NORM=$(printf '%s' "$INPUT" | tr -d ' \n\t')
if printf '%s' "$NORM" | grep -q '"agent_id":"'; then
  exit 0
fi

. "$(dirname "$0")/play-sound.sh"
play_limit_sound "$(printf '%s' "$NORM" | grep -Eo '"session_id":"[^"]*"' | head -1 | cut -d'"' -f4)"
