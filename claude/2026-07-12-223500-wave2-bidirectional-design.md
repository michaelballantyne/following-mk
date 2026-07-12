# Design: benchmark wave 2 — bidirectionality-essential specs

Priority 2 of the reflection (`...-220000-reflection-after-factoring-
and-wave1.md`). Design note before building; predictions recorded up
front per methodology.

## What "bidirectionality-essential" means here, precisely

In the relational substrate every spec is a conjunction of goals; the
honest definition of the differentiating class is: **specs an
enumerate-and-test synthesizer cannot check by running the candidate
forward on ground inputs.** Three concrete sub-classes, all
expressible today with zero new machinery (goals with variables):

- **W2a — symbolic (parametric) examples.** Inputs contain fresh
  logic vars under `=/=`/`numbero` constraints; outputs reuse the
  vars. One example denotes a family; constant-coincidence degenerates
  (the evens incident) are killed structurally. Also supplies the
  long-missing same-`l`/different-`e` information for rember. E&T
  cannot evaluate a candidate on a symbolic input at all (that
  requires symbolic-execution machinery we get for free).
  - rember: `(rember e (cons x (cons e (cons y '())))) = (x y)` with
    `(=/= x e)`, `(=/= y e)`, all numbero — one example subsuming a
    whole concrete family; plus a same-l/different-e pair.
- **W2b — partial outputs.** Ground inputs, outputs with holes:
  `(swap (5 6 7 8)) = (6 . V)`. Weakens refutation but should
  *force*: the known output prefix propagates through evalo/d
  backward into candidate structure. This is the cleanest place to
  observe the refute→force flip the reflection predicts.
- **W2c — composition/property specs.** The function applied twice,
  or chained through shared vars, on symbolic bounded-shape inputs:
  rev-acc involution `(rev (rev X '()) '()) = X` for symbolic X of
  bounded length; rember idempotence. E&T can check these on ground
  inputs but not symbolic ones; more importantly they exercise the
  interpreter running the *same candidate* in entangled directions.

Not in scope: quantifier alternation (∀-specs) — `run` has no way to
express it; noted as the boundary of the class.

## Prerequisites, in order

1. **Per-view attribution counters** (folded item (e)): a `tally/d`
   wrapper (label → {refute, force} counts) applied per view goal at
   arm level, implemented in following.scm so views.scm stays
   untouched. Without this the forcing-flip prediction is
   unmeasurable — unify(f) is too blunt. Must respect the
   counter-contamination lesson (`without-unify-counting` on any
   instrumentation reification).
2. **Untyped+TY port of wave 1** (adopting the default architecture):
   `<task>-untyped-id-ty.scm` for the six wave-1 tasks, mirroring the
   existing rember/append/duplicate untyped arms. W2 arms build on
   this stack.
3. R2P (task 1, in flight) for interleave's seat at the table.

## Measurement plan

For each sub-class: an arm per selected task (rember + swap + rev-acc
cover the three sub-classes), run under the untyped+TY stack, ce1,
240s, against two comparators: the concrete-example arm (same task,
ground examples) and the no-follower baseline with the same
bidirectional spec (does the *main search alone* handle symbolic
specs?). Metrics: feasibility, unify(main)/conde(main), per-view
refute/force tallies, depth-cut (must stay 0), answer + bound.
Standing practice: sample surviving streams of whatever is slowest.

## Predictions (to be scored)

1. W2a symbolic examples: refutation per example UP (family-level
   kills), EX forcing DOWN (`=` on symbolic operands stalls where
   concrete commits); net feasibility retained on rember; the
   same-l/different-e pair cuts the e-independence family that the
   4c post-mortem showed current examples cannot touch.
2. W2b partial outputs: first substantial EX *forcing* counts of the
   project (output structure is many-to-one backward, but the known
   prefix is exactly the determinate part); weaker refutation —
   possibly infeasible without a concrete-example anchor alongside.
3. W2c involution: hardest; double application doubles follower
   depth pressure (suspend-depth cutoffs may reappear); if feasible,
   it is the flagship demo — no per-operator inverse semantics
   anywhere, one interpreter run in entangled directions.
4. The no-follower comparator stays infeasible everywhere (baselines
   already die on ground specs; symbolic specs only enlarge the
   space).
