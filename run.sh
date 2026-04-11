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
#   -h, --help              show this help
set -e
cd "$(dirname "$0")"

FAIL_DEPTH=
SUSPEND_DEPTH=
MAIN_DEPTH=
CHECK_EVERY=
PRINT_FOLLOWER=
DUMP_ON_INT=

usage() {
  sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --unsound-fail-depth)    FAIL_DEPTH="$2"; shift 2 ;;
    --suspend-depth)         SUSPEND_DEPTH="$2"; shift 2 ;;
    --main-unsound-depth)    MAIN_DEPTH="$2"; shift 2 ;;
    --check-follower-every)  CHECK_EVERY="$2"; shift 2 ;;
    --print-follower)        PRINT_FOLLOWER=1; shift ;;
    --dump-on-interrupt)     DUMP_ON_INT=1; shift ;;
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
chez --script "$tmp"
