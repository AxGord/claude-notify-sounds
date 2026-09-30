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
