# Residual engine review fixes: commit-splice bug fixed, guard suite ported, pruning landed

Implements all findings of the review
`2026-07-13-061616-residual-engine-review.md` (advisor review, implemented
by an Opus subagent over two rounds, each round re-verified independently
by the advisor). Suite 157 → 171, all green.

## The bug fix (finding 1)

`settle-disj`'s commit case now seeds the surviving guard's residual into
`settle-conj`'s soft/hard pools instead of re-settling it as goals —
mirroring `conde/d-runtime`'s `(conj/d-run sd (list body) c (list f) '())`
exactly. Budget-blocked guard leftovers are deferred to the next trigger,
as the design note's contract states, instead of being re-expanded
mid-pass with refreshed budget.

Measured on guard-robustness case 1 (diverging guard commits as sole
survivor), decision vector = (fail / singleton / suspend / cutoff):

| engine   | before fix        | after fix   |
|----------|-------------------|-------------|
| closure  | (0 0 2 2)         | (0 0 2 2)   |
| residual | (0 0 2 4,194,304) | (0 0 2 2)   |

4,194,304 = 2^22: the blocked tail re-expanded at every level of the
~21-deep budget, T(d) = 2·T(d+1). Same answer, exponential work — invisible
to the original harness because the guard-robustness suite had not been
ported. `settle`'s `g-blocked` dispatch case is now exercised only on the
trigger path, which is the stated contract.

## Guard-robustness ported (finding 2)

`tests/residual-guards.scm`: all 8 closure-engine guard-robustness tests
in r-form with the same expected answers and counter predicates, plus
decision-equiv variants for cases 1 and 2. This is the suite that would
have caught the bug; it is now permanent regression coverage for the
commit-splice path.

## Dead-alternative pruning (finding 3) — and its one understood divergence

On stall, `settle-disj` now rebuilds the disj without the alternatives
whose guards failed during the scan (the unscanned tail after the second
survivor is kept). Sound by monotonicity: the base store only grows along
a candidate's lifetime, so guard failure is permanent. This is the
`alive?` mechanism from the design note, realized as persistent rebuild
rather than a mutable flag.

**Pinned divergence.** Pruning creates the one deliberate, one-sided
exception to decision-vector equality with the closure engine: a dead
alternative whose guard fails only *after* budget-blocking work is never
re-verified on retriggers, while the closure engine re-enters the whole
conde/d and pays the cutoff again. Witness (3-alt disj, alt A's guard
diverges-then-fails, B/C stall on an outer var grounded later): closure
(0 1 1 2) vs residual (0 1 1 1) — follower decisions identical, cutoff
lower by exactly the skipped re-verification. The residual tally can only
be LOWER, never higher, and fail/singleton/suspend must always match.
Hard-coded as a test in `tests/residual-guards.scm` so any future shift
in either engine flags loudly. The exact-equality decision-equiv tests
remain untouched and passing — no scenario in the ported suites hits the
exception.

## Honesty and hygiene (findings 4–6, minors)

- `residual.scm`'s header now states the **stamp fast path is NOT
  implemented** and is deferred to cutover (steps 5–6) — the design note's
  "already built in" phrasing described the design, not this file. Every
  trigger currently re-settles residual conjuncts from scratch.
- `assert-flat-residual!` is wired into `settle->inf/d`'s suspended
  branch (the flatness invariant is now checked on every trigger), and
  three direct settle-level shape tests cover TOP/extension on commit,
  flat-residual shape + `residual->sexp` on nondet, and `g-blocked` on
  budget exhaustion.
- `decision-equiv` runs each side exactly once (was: closure side twice
  with a dead binding).
- Commit-site bindings named; `rfail/d` is an honest failing prim.

## Methodology note

The lesson the review adds to the migration record: **decision
equivalence is only as strong as its scenario set, and the scenario set
must include the engine's own regression suite** — the six original
probes were happy paths, and the one suite pinning the subtle path
(sole-survivor commit with retained guard obligation) was exactly the one
not ported. For 3b (cutover), the bar should be: every closure-engine
test file has a residual port or a recorded reason it can't have one
(`concluding-oro/d` being the known non-viable case).
