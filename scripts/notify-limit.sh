#!/bin/bash
# StopFailure hook, matcher "rate_limit": the turn ended on a usage limit
cat > /dev/null

. "$(dirname "$0")/play-sound.sh"
play_sound Sosumi.aiff suspend-error.oga 'Windows Critical Stop.wav'
