#!/bin/bash
cat > /dev/null

case "$(uname -s)" in
  Darwin)
    afplay /System/Library/Sounds/Ping.aiff &
    ;;
  Linux)
    SOUND=/usr/share/sounds/freedesktop/stereo/message-new-instant.oga
    if command -v paplay >/dev/null 2>&1 && [ -f "$SOUND" ]; then
      paplay "$SOUND" &
    elif command -v pw-play >/dev/null 2>&1 && [ -f "$SOUND" ]; then
      pw-play "$SOUND" &
    else
      printf '\a'
    fi
    ;;
  MINGW*|MSYS*|CYGWIN*)
    powershell.exe -NoProfile -WindowStyle Hidden -Command "(New-Object Media.SoundPlayer 'C:\Windows\Media\Windows Notify.wav').PlaySync()" &
    ;;
  *)
    printf '\a'
    ;;
esac
