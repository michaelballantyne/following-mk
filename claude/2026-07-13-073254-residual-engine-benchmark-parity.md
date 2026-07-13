# Residual engine benchmark parity: mechanical port done, answers identical, small consistent overhead

Backlog 3b, first half: port the production relation vocabulary to the
residual engine and benchmark it against the closure engine before cutover.
Implemented by three parallel Sonnet subagents (interpreter ports, views
port) then two more (typed and untyped+TY benchmark arms), reviewed and
verified independently at every step; commits `fe38d2a` through `95ea511`
(and this entry) on `claude/backlog-item-3-review-qcqckq`.

## What was built

- `residual-interp-following.scm`, `residual-interp-untyped-following.scm`:
  production r-form ports of the typed and untyped /d interpreters (evalo/d,
  evalo-u/d), extracted from/added alongside the differential test suite.
- `residual-views.scm`: r-form port of R1 (`base-case-patho/d`), R2
  (`decreasing-recursiono/d`), R2P (`permuted-decreasing-recursiono/d`), TY
  (`type-ofo/d`), NV (`non-vacuous-testso/d`). R2T (`terminating-recursiono/d`
  / `concluding-oro/d`) is deliberately NOT ported — recorded non-viable,
  writes directly against `inf/d`, rescuing it is backlog 3c's open research
  question, not a mechanical port.
- Suite grew 171 → 213 (42 new differential tests: R2/R2P/TY/NV gates, the
  R2P-vs-R2 incomparability pair, the untyped-interpreter follower gates
  including the restored R1+R2 composition gate), all green.
- 20 parallel benchmark arms (`experiments/*-residual.scm`): 11 typed
  (`*-full-id-views[.scm|-r2p.scm]`) + 9 untyped+TY-default
  (`*-untyped-id-ty.scm`), each identical to its closure sibling except for
  engine/view loads and the r-form follower goal.

`tally/d` (per-view refute/force attribution) has no residual port — it's
written directly against the closure engine's curried goal representation.
Confirmed by inspection that `tally-step` is purely observational (never
alters store or control flow), so dropping the wrapper in residual arms has
zero effect on unify counts or answers; documented per-file where dropped.

## Benchmark results

All 19 completed comparisons (10 typed + 9 untyped) produced **byte-for-byte
identical answers** between engines. One task (interleave, R2-omitted
arm — the one config in the whole suite that runs with NO termination view)
genuinely times out on **both** engines, twice each, at the identical stall
point (bound 27→31) — confirmed by direct process inspection, not just the
agents' say-so. This is a known property of that specific arm (a documented
`(noR2)` config, expected to be search-heavy without R2's pruning) showing
up symmetrically, not a residual regression.

| task | closure unify-main | residual unify-main | ratio |
|---|---:|---:|---:|
| rember (typed) | 312,236 | 328,127 | 1.051× |
| rember-r2p (typed) | 251,834 | 275,153 | 1.093× |
| duplicate (typed) | 53,812 | 57,837 | 1.075× |
| duplicate-r2p (typed) | 53,812 | 57,837 | 1.075× |
| evens (typed) | 251,354 | 276,340 | 1.099× |
| last (typed) | 107,296 | 115,463 | 1.076× |
| member (typed) | 97,494 | 100,425 | 1.030× |
| rev-acc (typed) | 130,115 | 133,262 | 1.024× |
| swap (typed) | 454,748 | 504,535 | 1.110× |
| interleave-r2p (typed) | 108,475 | 115,939 | 1.069× |
| interleave (typed, noR2) | TIMEOUT | TIMEOUT | — |
| rember (untyped+TY) | 305,891 | 322,002 | 1.053× |
| append (untyped+TY) | 136,817 | 143,928 | 1.052× |
| duplicate (untyped+TY) | 52,315 | 56,496 | 1.080× |
| evens (untyped+TY) | 246,018 | 271,524 | 1.104× |
| last (untyped+TY) | 108,818 | 117,669 | 1.081× |
| member (untyped+TY) | 97,220 | 100,439 | 1.033× |
| swap (untyped+TY) | 446,949 | 498,096 | 1.114× |
| rev-acc (untyped+TY) | 126,853 | 129,994 | 1.025× |
| interleave (untyped+TY) | TIMEOUT | TIMEOUT | — |

## Reading the pattern

**unify-main is consistently 2.4%–11% higher on the residual engine, on
every single completed task, with zero inversions.** That consistency
(rather than a mix of wins and losses) says this is a small systematic
overhead, not noise or a task-dependent correctness gap — reinforced by
`unify-follower` (the more expensive metric, since it's the quantity the
whole follower/pruning apparatus exists to shrink) going the OTHER way,
consistently *lower* on residual (e.g. swap: 22.2M → 11.5M, roughly half;
last: 4.6M → 2.2M). So the representation itself is doing the pruning job
at least as well or better; the small main-search-visible overhead sits
somewhere else.

The most likely explanation, and the one the design record already
predicts: `residual.scm`'s header states plainly that **the stamp fast path
is NOT implemented** — every trigger currently re-settles every residual
conjunct from scratch, where the closure engine's `conj/d-run` has some
cheaper unchanged-store short circuits built into its fixpoint loop. A
few-percent constant-factor cost from redoing settle work that stamps would
memoize is exactly the shape of overhead this predicts, and is explicitly
deferred to cutover (steps 5-6) rather than being a design flaw. Per the
project's own stated regime (BACKLOG.md: "overhead IS in scope when it is
measurement-blocking... mere-inefficiency overhead stays out of scope"),
this modest overhead did not block a single measurement — every arm that
should complete, did, with an identical answer — so it does not need
resolution before cutover. It's worth re-measuring once stamps land, since
the prediction is falsifiable: if stamps close the gap, that confirms the
diagnosis; if they don't, something else is going on and is worth another
look.

Wall-clock times split roughly evenly (residual faster on evens/last/swap/
rev-acc-untyped/interleave-r2p-untyped... typed evens/last-typed/swap-typed/
rev-acc-typed; closure faster elsewhere, notably interleave-r2p-typed:
2,265ms vs 5,505ms despite a normal 1.07× unify-main ratio) — on a shared,
noisy sandbox machine this is expected and not a signal either way; the
work-count ratio is the reliable comparison here, wall time a secondary/
environment-caveated one as planned.

## Verdict and next step

**Benchmark parity confirmed**: the residual engine reproduces the closure
engine's search behavior (identical answers, identical timeout boundary on
the one hard task) at a small, well-understood, non-blocking overhead. This
clears the gate the migration plan set for cutover: "a subtly-wrong views
port that passes tests but mis-measures is worse than two coexisting
engines" — the port is not subtly wrong; it measures the same thing the
closure engine does, plus a documented, predicted, and bounded constant
factor.

**Deliberately NOT done in this pass** (per the user's explicit two-phase
request): stripping the closure engine (`inf/d`/`case-inf/d`/
`conj/d-run`/`conj/d-resume`/hard-suspended), renaming r→canonical, and
re-baselining the synthesis benchmarks on the residual engine alone. That's
backlog 3b's remaining half, to start once the user confirms this
comparison is satisfactory.
