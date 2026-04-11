#!/bin/bash
# run.sh -- load the follower infrastructure and run one or more test files.
#
# Usage: ./run.sh [FLAGS] TEST-FILE [TEST-FILE...]
#
# Flags (all optional; unset flags leave the following.scm defaults in place):
#   --unsound-fail-depth N  set *unsound-fail-depth*     (follower, UNSOUND)
#   --suspend-depth N       set *suspend-depth*          (follower, sound)
#   --main-unsound-depth N  set *main-unsound-depth*     (main search, UNSOUND)
#   --check-follower-every N set *check-follower-every*  (main search throttle)
#   --print-follower        enable *print-follower-term*
#   --dump-on-interrupt     install Ctrl-C counter-dump handler
#   --timeout SECS          kill the chez process if it runs longer than SECS
#                           (prints "TIMEOUT after SECS" and exits 124)
#   -h, --help              show this help
set -e
cd "$(dirname "$0")"

FAIL_DEPTH=
SUSPEND_DEPTH=
MAIN_DEPTH=
CHECK_EVERY=
PRINT_FOLLOWER=
DUMP_ON_INT=
TIMEOUT=

usage() {
  sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --unsound-fail-depth)    FAIL_DEPTH="$2"; shift 2 ;;
    --suspend-depth)         SUSPEND_DEPTH="$2"; shift 2 ;;
    --main-unsound-depth)    MAIN_DEPTH="$2"; shift 2 ;;
    --check-follower-every)  CHECK_EVERY="$2"; shift 2 ;;
    --print-follower)        PRINT_FOLLOWER=1; shift ;;
    --dump-on-interrupt)     DUMP_ON_INT=1; shift ;;
    --timeout)               TIMEOUT="$2"; shift 2 ;;
    -h|--help)               usage; exit 0 ;;
    --)                      shift; break ;;
    -*)                      echo "unknown flag: $1" >&2; usage >&2; exit 1 ;;
    *)                       break ;;
  esac
done

if [[ $# -eq 0 ]]; then
  usage >&2
  exit 1
fi

tmp=$(mktemp -t following-mk.XXXXXX)
trap 'rm -f "$tmp"' EXIT
{
  echo '(load "load.scm")'
  echo '(load "restricted-interp.scm")'
  echo '(load "restricted-interp-following.scm")'
  [[ -n $FAIL_DEPTH ]]     && echo "(*unsound-fail-depth* $FAIL_DEPTH)"
  [[ -n $SUSPEND_DEPTH ]]  && echo "(*suspend-depth* $SUSPEND_DEPTH)"
  [[ -n $MAIN_DEPTH ]]     && echo "(*main-unsound-depth* $MAIN_DEPTH)"
  [[ -n $CHECK_EVERY ]]    && echo "(*check-follower-every* $CHECK_EVERY)"
  [[ -n $PRINT_FOLLOWER ]] && echo "(*print-follower-term* #t)"
  [[ -n $DUMP_ON_INT ]]    && echo "(install-interrupt-counter-dump!)"
  for f in "$@"; do
    printf '(load "%s")\n' "$f"
  done
} > "$tmp"

if [[ -n $TIMEOUT ]]; then
  chez --script "$tmp" &
  chez_pid=$!
  sleep "$TIMEOUT" &
  sleep_pid=$!
  # Poll until either chez or the sleep finishes.  macOS bash 3.2 doesn't
  # support `wait -n`, so poll with `kill -0` at 100ms.
  while kill -0 "$chez_pid" 2>/dev/null && kill -0 "$sleep_pid" 2>/dev/null; do
    sleep 0.1
  done
  set +e
  if kill -0 "$chez_pid" 2>/dev/null; then
    kill -9 "$chez_pid" 2>/dev/null
    wait "$chez_pid" 2>/dev/null
    echo "TIMEOUT after ${TIMEOUT}s" >&2
    exit 124
  fi
  wait "$chez_pid"
  rc=$?
  kill "$sleep_pid" 2>/dev/null
  wait "$sleep_pid" 2>/dev/null
  exit "$rc"
else
  chez --script "$tmp"
fi
