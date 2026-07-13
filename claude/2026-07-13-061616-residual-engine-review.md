# Review of the residual-goal engine (backlog item 3): one exponential parity bug, plus fidelity and test gaps

Advisor review of `residual.scm` and its test harness
(`tests/residual-{engine,interp,decisions}.scm`), commits `680cce8` +
`44cd0fa`, against the design note
`2026-07-13-051843-residual-goals-design.md` and the closure engine
(`following.scm`). Overall verdict: the representation and `settle` are
right and the file reads well — but the differential harness's coverage
was too narrow, and it missed an exponential deviation on exactly the
path the guard-robustness suite pins.

## Finding 1 (bug, confirmed): budget-blocked guard leftovers re-expand exponentially at commit

Probe: guard-robustness case 1 ("diverging guard commits when sole
survivor") run through both engines, comparing the decision vector
(fail / singleton / suspend / suspend-cutoff):

```
closure : result=(A) decisions=(0 0 2 2)
residual: result=(A) decisions=(0 0 2 4194304)
```

4,194,304 = 2^22 cutoffs where the closure engine takes 2. Same answer,
exponentially more work, and a decision-vector component (`suspend-cutoff`)
wildly off — this violates the migration's own bar.

Mechanism: `settle`'s dispatch re-attempts a `g-blocked` any time it is
settled (`residual.scm:88`), and the commit case of `settle-disj` splices
the guard residual — which can contain `g-blocked` nodes — into a fresh
goals list settled at `d1` (`residual.scm:166-169`). So a diverging guard
committed as sole survivor re-expands its blocked tail from `d1` with
refreshed budget at *every* level of the recursion: T(d) = 2·T(d+1) over
the ~21 levels of budget. The closure engine instead defers the hard
guard leftover to the next trigger: `conde/d-runtime`'s commit puts `fh`
in `conj/d-run`'s hard worklist (`following.scm:569`), which is never
re-run within the trigger.

The design note states the contract explicitly: "A g-blocked is
re-attempted only at the next trigger, when depth resets to 0"
(`residual.scm:67`'s own comment says the same). The commit path violates
it.

**Fix (mirror `conj/d-run`'s calling convention):** give `settle-conj`
initial soft/hard pool arguments (defaulting to empty). In
`settle-disj`'s commit case, `partition-blocked` the guard residual's
conjuncts into those pools and settle only the body goals:

```scheme
;; commit: body goals settle; guard leftovers enter the pools directly,
;; soft re-swept only if the pass changes the store, hard deferred --
;; exactly conde/d-runtime's (conj/d-run sd (list body) c (list f) '())
(let-values ([(s h) (partition-blocked (g-conj-goals guard-residual))])
  (settle-conj (g-conj-goals body) guard-state d1 s h))
```

This also removes a smaller redundancy: soft guard leftovers were being
re-settled unconditionally at commit (quiescent against `guard-state`, so
the re-settle was pure waste); in the pools they re-sweep only on store
change, matching the closure engine. After this change, the `g-blocked`
case in `settle`'s dispatch is exercised only at trigger time (the
residual conjunction's `g-blocked` children arrive via `settle->inf/d`'s
goals list), which is the stated contract. Keep that dispatch case;
update its comment to say it is the trigger-path re-attempt.

Acceptance: the probe above must produce identical vectors; the full
suite stays green.

## Finding 2 (test gap, caused finding 1 to slip through): guard-robustness never ported

The commit-splices-guard-obligation path is the subtlest part of
`settle-disj` — it is exactly what `tests/guard-robustness.scm`'s 8 tests
pin for the closure engine ("sole-survivor commit with retained
nondet-guard obligation", diverging guards, multi-answer guards,
extension leakage) — and none of them were ported. Port all 8 to
r-forms in a new `tests/residual-guards.scm` (same expected answers), and
add decision-equiv variants (à la `tests/residual-decisions.scm`) for at
least case 1 (diverging sole survivor — the finding-1 witness) and case 2
(diverging guard + succeeding sibling). Note the counter checks in the
originals (`> *suspend-depth-cutoff-counter* 0` etc.) must hold under the
residual engine too.

## Finding 3 (design fidelity): `alive?` flags dropped silently

The design note's datatype gives each alternative `alive?` ("guard fails
→ alt dies, PERMANENTLY") with a soundness argument (failure is monotone
in a growing store) and lists monotone alive-flags among the assertable
invariants; the implementation's `g-alt` has neither the flag nor the
pruning. A stalled disj is returned as the *original* node, so known-dead
alternatives are re-tested every re-settle and every trigger, forever —
re-doing exactly the work the residual representation exists to
eliminate.

Implement as persistent pruning rather than a mutable flag: when the
disj stalls, rebuild it without the alternatives whose guards failed
this pass (alternatives after the second survivor are untested — keep
them). Sound by the note's own monotonicity argument; decisions
unchanged (a pruned guard would have failed again), only work counts
shift. Do this as a **separate commit** after the finding-1 fix, and
confirm the decision-equiv tests are unaffected.

## Finding 4 (honesty of the record): stamps not implemented, notes claim otherwise

The design note says "the stamp fast path is already built in" (and the
notebook entry inherits the motivation-1 claim); the implementation has
no stamp field and no fast path — every trigger re-settles every residual
conjunct from scratch. Deferring stamps to cutover (they are an
optimization, orthogonal to decisions) is a reasonable call, but it must
be *written down*, not implied away: state the deferral in
`residual.scm`'s header and in the follow-up notebook entry. Do not
implement stamps now.

## Finding 5 (dead code / unasserted invariants)

`assert-flat-residual!` and `residual->sexp` are defined "for the
differential harness" but called nowhere. The note's "assertable data
invariants for the test suite" are asserted in zero tests, and all 37
tests drive the engine only through the follower integration — there are
no direct `settle`-level tests of residual *shape*. Add a handful to
`tests/residual-engine.scm`: call `settle` directly on (a) a committing
conj (expect TOP + extended state), (b) a nondet disj (expect a flat
residual passing `assert-flat-residual!`, and a sane `residual->sexp`
rendering), (c) a budget-blocked recursion (expect a `g-blocked`
conjunct). Also wire `assert-flat-residual!` into `settle->inf/d` on the
suspended branch — it is O(residual width), runs once per trigger, and
turns the flatness invariant from prose into a checked property.

## Finding 6 (harness hygiene): `decision-equiv` runs the closure side twice and binds dead `c`

```scheme
(let ([r (decisions-of (lambda () residual-run))])
  (let ([c (decisions-of (lambda () closure-run))])   ; c is never used
    r))
(decisions-of (lambda () closure-run))                 ; run again as expected
```

Leftover debugging shape: the closure run executes twice per test and the
first result is discarded. Simplify to one run of each side.

## Minor (readability, fix opportunistically)

- `settle-disj`'s `found` is a positional 3-list read back with
  `car`/`cadr`/`caddr`; bind names (`guard-residual`, `guard-state`,
  `body`) at the use sites.
- `rfail/d` is `(=/= 'x 'x)` — an idiom where an honest
  `(make-g-prim 'fail '() (lambda (st) #f))` says what it means.

## What's right (keep as is)

The core calls are correct and well-made: budget at `g-disj` not `g-call`
(the note's open question, resolved with measurement); the soft/hard
split as the quiescence-termination condition (bug found by the harness
and documented); `settle` at ~60 lines with one case per node; the
follower-boundary adapter leaving `following.scm` untouched; validation
sequenced before cutover. The file's comments carry the design's
load-bearing arguments (why g-blocked exists, why g-call is free). The
review's findings are all in the *periphery* the harness didn't reach —
which is itself the lesson: decision-equivalence is only as strong as the
scenario set, and the scenario set must include the engine's own
regression suite, not just the happy paths.
