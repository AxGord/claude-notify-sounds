#!/bin/bash
cat > /dev/null

. "$(dirname "$0")/play-sound.sh"
play_sound Ping.aiff message-new-instant.oga 'Windows Notify.wav'
