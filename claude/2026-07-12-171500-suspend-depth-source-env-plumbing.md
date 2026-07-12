# Resolved: the follower's deep unfolding is environment plumbing

Answers the backlog Now item "where does the follower's deep unfolding
come from?" (and TODO's "I don't understand where else the follower
will have the opportunity to unfold unboundedly"). Instrumentation
delegated to a subagent; tally and interpretation below.

## Instrumentation (committed)

`conde/d` now captures a source label (`file:line`) at expansion time
via Chez syntax annotations (`syntax->annotation` → source object →
`locate-source`), zero call-site churn. `conde/d-runtime` records
entries, cutoffs, and max-depth-at-entry per label in hashtables;
`(print-depth-tally!)` dumps them; `reset-counters!` resets. Passive
unless printed.

## The tally (ex3 rember follower, check-every=20, 9453 cutoffs)

| site | relation | entries | cutoffs | max-depth |
|---|---|---:|---:|---:|
| interp:9 | `not-in-envo/d` | 133,957 | 3,482 | 21 |
| interp:23 | `lookupo/d` inner (val/rec) | 75,913 | 3,190 | 21 |
| interp:20 | `lookupo/d` outer (x=y / x≠y) | 161,059 | 2,373 | 21 |
| interp:76 | `eval-expo/d` main | 150,378 | 168 | 21 |
| interp:53 | `ext-env*o/d` | 82,675 | 116 | 21 |
| interp:44 | `eval-listo/d` | 83,014 | 116 | 21 |
| interp:138/153 | `match` / `if` | 84,412 | 8 | 21 |

**95.7% of suspend cutoffs fire in `not-in-envo/d` + `lookupo/d`.**

## Interpretation

The grammar restrictions (no nested applications/letrecs) did their
job — the deep unfolding is NOT degenerate program expansion. It is
honest, linear-in-environment-size recursion:

1. `suspend-depth` is one counter threaded through the whole nested
   conde/d chain of a trigger: eval-expo/d descent × guard evaluation ×
   env scans all charge the same budget of 20.
2. `not-in-envo/d` and `lookupo/d` cost one conde/d entry per env
   binding scanned, and eval-expo/d's keyword-shadowing guards run
   `not-in-envo/d` (a full scan) on essentially every clause.
3. The env grows with the interpreted program's recursion: letrec binds
   the function, each application adds params, each match adds `a`/`d`;
   on a 4-element-list rember call the env is ~16 bindings deep. A
   lookup near the bottom of that env, under an already-deep eval
   chain, crosses depth 20 — so the *budget runs out inside the
   evaluation of a single honest recursive call*.

## Implications

- **The follower's refutation power at suspend-depth 20 is
  depth-starved on exactly the benchmarks we care about.** A trigger
  that would refute a candidate by running an example forward to a
  contradiction gets hard-suspended mid-plumbing instead. This
  reframes the pruning-ceiling question: the ceiling knob is
  `*suspend-depth*`, and 20 is far below what one honest recursive
  evaluation costs (~depth 100+ for our examples, given env scans).
- **Immediate experiment** (running as of this entry): follower ID
  arms with `--suspend-depth 200 --check-follower-every 20` — the
  oracle-ish "let the follower actually finish its refutations" arm.
- **Structural fixes** (backlog): remove `not-in-envo/d` guards via
  tagged applications (TODO already suspected this; the tally makes it
  the single biggest depth+work win: 134k entries, 37% of cutoffs);
  cheaper lookup (tagged env / avoiding re-scans). Note a blanket
  "don't charge depth for deterministic commits" is NOT sound as a
  divergence guard: a looping letrec unfolds through deterministic
  commits too. But env scans over *ground* envs are bounded by env
  length — a targeted exemption may be justifiable later.
- Wall-clock observation from the same session: at check-every=1 the
  follower ID arms could not finish even one level (bound 15/11) in
  ~18 minutes — every-conde triggering re-pays the env-plumbing cost
  at every choice point. Throttling is mandatory for wall-feasible
  experiments; the work-metric comparison is unaffected.
