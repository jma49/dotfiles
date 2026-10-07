#!/bin/bash

# Records Claude Code session state; the kitty tab bar (~/.config/kitty/tab_bar.py)
# reads it to show status and play sounds.
# Usage: agent-state.sh <start|working|blocked|done|failed|end>, hook input on stdin
# State file: ~/.cache/claude-agents/<session_id>.json, one line of JSON:
#   state   working | blocked | done | failed | idle
#   since   when the current state began (seconds)
#   started when this turn began; kitty uses since - started to spot long turns
#   pid     the claude process; kitty deletes the file once it exits
#   window  the kitty pane (KITTY_WINDOW_ID); kitty uses it to tell whether you are watching
#   pane    the herdr pane (HERDR_PANE_ID), used instead of window inside herdr
# Hooks run synchronously on every tool call, so this sticks to bash builtins and
# exits early when the state is unchanged.
# stdout counts as hook output (UserPromptSubmit/SessionStart add it to context),
# so nothing may be printed here.

event=$1
input=$(cat)
[[ $input =~ \"session_id\":\ *\"([A-Za-z0-9_-]+)\" ]] || exit 0
dir="$HOME/.cache/claude-agents"
file="$dir/${BASH_REMATCH[1]}.json"

if [ "$event" = end ]; then
  rm -f "$file"
  exit 0
fi

prev=$(cat "$file" 2>/dev/null)
prev_state=""; prev_started=0
[[ $prev =~ \"state\":\"([a-z]+)\" ]] && prev_state=${BASH_REMATCH[1]}
[[ $prev =~ \"started\":([0-9]+) ]] && prev_started=${BASH_REMATCH[1]}

now=$(date +%s)
case $event in
  start)
    # resume and compact also fire SessionStart; keep any existing state
    [ -n "$prev_state" ] && exit 0
    state=idle; started=$now ;;
  working)
    [ "$prev_state" = working ] && exit 0
    state=working
    # Going from blocked back to working is still the same turn
    if [ "$prev_state" = blocked ]; then started=$prev_started; else started=$now; fi ;;
  blocked|done|failed)
    [ "$prev_state" = "$event" ] && exit 0
    state=$event
    # Ending without passing through working (e.g. a reply after a background task
    # wakes it) is not a long turn
    case $prev_state in
      working|blocked) started=$prev_started ;;
      *) started=$now ;;
    esac ;;
  *) exit 0 ;;
esac

# Walk up to the claude process: the hook command may be wrapped in an extra sh
pid=$PPID
for _ in 1 2 3; do
  [[ $(ps -o comm= -p "$pid" 2>/dev/null) == *claude* ]] && break
  pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
  [ -n "$pid" ] || break
done
[[ $(ps -o comm= -p "${pid:-0}" 2>/dev/null) == *claude* ]] || pid=0

window=${KITTY_WINDOW_ID:-0}
[[ $window =~ ^[0-9]+$ ]] || window=0
# Sessions inside herdr have no KITTY_WINDOW_ID (the herdr server is not a kitty
# child); the tab bar asks herdr which pane is focused instead
pane=${HERDR_PANE_ID:-}
[[ $pane =~ ^[A-Za-z0-9:_-]*$ ]] || pane=""

mkdir -p "$dir"
tmp="$file.$$"
printf '{"state":"%s","since":%s,"started":%s,"pid":%s,"window":%s,"pane":"%s"}\n' \
  "$state" "$now" "$started" "$pid" "$window" "$pane" >"$tmp" && mv -f "$tmp" "$file"
exit 0
