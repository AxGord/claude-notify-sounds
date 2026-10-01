#!/bin/bash
# Sourced by the notify-* scripts.
# Usage: play_sound <macOS sound> <freedesktop sound> <Windows Media sound>
play_sound() {
  case "$(uname -s)" in
    Darwin)
      afplay "/System/Library/Sounds/$1" &
      ;;
    Linux)
      SOUND="/usr/share/sounds/freedesktop/stereo/$2"
      if command -v paplay >/dev/null 2>&1 && [ -f "$SOUND" ]; then
        paplay "$SOUND" &
      elif command -v pw-play >/dev/null 2>&1 && [ -f "$SOUND" ]; then
        pw-play "$SOUND" &
      else
        printf '\a'
      fi
      ;;
    MINGW*|MSYS*|CYGWIN*)
      SOUND="C:\\Windows\\Media\\$3"
      powershell.exe -NoProfile -WindowStyle Hidden -Command "(New-Object Media.SoundPlayer '$SOUND').PlaySync()" &
      ;;
    *)
      printf '\a'
      ;;
  esac
}

# Usage: play_limit_sound <session_id>
# One limit stop can reach both hooks: a wrap-up Stop, then a StopFailure when a
# task notification wakes the agent into the limit. A repeat within 60 seconds in
# the same session stays silent.
play_limit_sound() {
  case "$1" in
    ''|*[!A-Za-z0-9_-]*) ;;
    *)
      local stamp="${TMPDIR:-/tmp}/claude-notify-sounds-limit-$1"
      local now last
      now=$(date +%s)
      last=$(cat "$stamp" 2>/dev/null)
      case "$last" in ''|*[!0-9]*) last=0 ;; esac
      [ $((now - last)) -lt 60 ] && return
      echo "$now" > "$stamp" 2>/dev/null
      ;;
  esac
  play_sound Sosumi.aiff suspend-error.oga 'Windows Critical Stop.wav'
}
