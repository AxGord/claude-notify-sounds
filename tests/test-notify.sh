#!/bin/bash
# Hook-script tests: stub uname/afplay, feed payloads, check which sound plays.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/bin"
printf '#!/bin/sh\necho Darwin\n' > "$TMP/bin/uname"
# afplay runs in the background, so each case gets its own log file — a late
# write can never land in the next case
printf '#!/bin/sh\nbasename "$1" >> "$PLAYED"\n' > "$TMP/bin/afplay"
chmod +x "$TMP/bin/uname" "$TMP/bin/afplay"

FAILS=0
CASE=0

# run_case <name> <script> <payload> <expected sound file name or "none">
run_case() {
  CASE=$((CASE + 1))
  export PLAYED="$TMP/played-$CASE"
  printf '%s' "$3" | PATH="$TMP/bin:$PATH" TMPDIR="$TMP" bash "$ROOT/scripts/$2"
  # wait up to 5s for an expected sound, then a moment more to catch a duplicate
  if [ "$4" != none ]; then
    for _ in $(seq 50); do [ -s "$PLAYED" ] && break; sleep 0.1; done
  fi
  sleep 0.3
  GOT=none
  [ -s "$PLAYED" ] && GOT=$(cat "$PLAYED")
  if [ "$GOT" = "$4" ]; then
    echo "ok   $1"
  else
    echo "FAIL $1: expected $4, got $GOT"
    FAILS=$((FAILS + 1))
  fi
}

TRANSCRIPT="$TMP/transcript.jsonl"
cat > "$TRANSCRIPT" <<'EOF'
{"type":"user","promptId":"p-wrap","message":{"role":"user","content":"do the thing"}}
{"type":"user","promptId":"p-wrap","message":{"role":"user","content":"[Usage limit reached. Wrap up this turn]"},"isMeta":true,"turnCompanion":true,"usageLimitNote":"wrap_up"}
{"type":"assistant","promptId":"p-wrap","message":{"role":"assistant","content":[{"type":"text","text":"Limit reached, here is what is left"}]}}
{"type":"user","promptId":"p-released","message":{"role":"user","content":"go on"}}
{"type":"user","promptId":"p-released","message":{"role":"user","content":"[Usage limit reached. Wrap up this turn]"},"isMeta":true,"usageLimitNote":"wrap_up"}
{"type":"user","promptId":"p-released","message":{"role":"user","content":"[Limit lifted]"},"isMeta":true,"usageLimitNote":"release"}
EOF

stop_payload() {
  printf '{"session_id":"%s","transcript_path":"%s","prompt_id":"%s","hook_event_name":"Stop","background_tasks":[%s]}' \
    "$1" "$TRANSCRIPT" "$2" "$3"
}
SUBAGENT_TASK='{"id":"x1","type":"subagent","status":"running","description":"d","agent_type":"general-purpose"}'

run_case "limit stop of the main agent" notify-limit.sh \
  '{"session_id":"s1","hook_event_name":"StopFailure","error":"rate_limit","last_assistant_message":"You'"'"'ve hit your session limit"}' \
  Sosumi.aiff
run_case "limit stop of a subagent is silent" notify-limit.sh \
  '{"session_id":"s2","agent_id":"a123","agent_type":"general-purpose","hook_event_name":"StopFailure","error":"rate_limit"}' \
  none
run_case "agent_id quoted inside the message is not a subagent" notify-limit.sh \
  '{"session_id":"s3","hook_event_name":"StopFailure","error":"rate_limit","last_assistant_message":"{\"agent_id\":\"x\"}"}' \
  Sosumi.aiff
run_case "plain stop" notify-stop.sh "$(stop_payload s4 p-other '')" Basso.aiff
run_case "wrap-up stop plays the limit sound" notify-stop.sh "$(stop_payload s5 p-wrap '')" Sosumi.aiff
run_case "limit stop right after a wrap-up stop is silent" notify-limit.sh \
  '{"session_id":"s5","hook_event_name":"StopFailure","error":"rate_limit"}' \
  none
run_case "wrap-up stop with a live subagent is silent" notify-stop.sh \
  "$(stop_payload s6 p-wrap "$SUBAGENT_TASK")" none
run_case "wrap-up lifted by release is a plain stop" notify-stop.sh "$(stop_payload s7 p-released '')" Basso.aiff
run_case "stop without transcript still plays" notify-stop.sh \
  '{"session_id":"s8","transcript_path":"'"$TMP"'/missing.jsonl","prompt_id":"p-wrap","hook_event_name":"Stop","background_tasks":[]}' \
  Basso.aiff

[ "$FAILS" -eq 0 ] || { echo "$FAILS failed"; exit 1; }
