# Resolved: the check-every=1 catastrophe is fair-search trajectory perturbation

The mystery: fair-search append-full goes 0.22s (no follower) to >200s
(evalo/d follower at ce1), ~1000× — far worse than the 20× firing
frequency alone explains. Three-part answer, one hypothesis killed,
one control that settles it.

## Chain-growth hypothesis: falsified

I predicted the F-cell's `conj/d-resume` chains grow per trigger
(closures wrapping closures → quadratic). Measured (subagent, temp
instrumentation, reverted): **worklist size stays bounded at 3–4 items
for the entire run at both ce1 and ce20; per-trigger unify cost is
flat in trigger index.** Good news for the current architecture — the
soft/hard worklist does not accumulate along a branch.

## The decomposition

- **Linear part (~20–30×)**: per-main-conde-entry follower cost is
  ~7,300 unify at ce1 vs ~237 amortized at ce20. Expected, boring.
- **Perturbation part (the rest)**: firing every conde changes *which*
  commits happen *when*; under fair interleaving that reshapes the
  whole exploration order, and the path to the answer gets far longer
  (ce1 never solved within 120s despite covering fewer conde entries
  than ce20's complete run).

## The control that isolates it

Under the enumerative regime the level population is fixed — the
scheduler cannot be perturbed onto a longer path. `append-full-id-tv2`
at ce1: **solves in 1.6s, unify-main 197,706 — LESS main work than
ce20's 248,260** (earlier firing = earlier pruning), follower work up
linearly (~2.15M). Same follower, same firing rate: no catastrophe.

So the catastrophe is not follower cost at all; it is mk fair search's
perturbation sensitivity (Michael's "almost anything you do makes it
spend time in a different space"), now demonstrated in its purest
form: an instrumentation-frequency knob with zero semantic content
changes fair-search wall time by ~1000× while the enumerative regime
barely notices — and even *benefits* on the work metric.

## Consequences

- Pure-Andorra firing (ce1) is the RIGHT config in the enumerative
  regime (matching the FD finding, where ce1 was also best) — the
  synthesis/FD split on throttling is resolved: it was never about
  task type, only about scheduler perturbability.
- The follower's per-fire constant (rebuilding and re-running the /d
  goal conjunction) is now the whole overhead story — flat but large.
  That is exactly what the first-order representation targets, with
  chain-growth ruled out as a factor.
- Every fair-search wall-clock comparison in older notes should be
  read with this in mind: throttle settings are confounded with
  trajectory changes there.
