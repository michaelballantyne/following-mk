# Residual-goal engine built and validated decision-equivalent (migration steps 1–4)

Implements the design in `2026-07-13-051843-residual-goals-design.md`. The
first-order representation of the /d search now exists as `residual.scm` and is
differentially validated against the closure engine (`following.scm`) on the
full engine surface. Backlog item 3's central question — *does the residual
representation reproduce the closure engine's behaviour?* — is answered **yes,
decision-equivalent**.

## What was built

`residual.scm` (~230 lines):

- **Datatype**: `g-prim` (leaf: ==, =/=, absento, symbolo, numbero, stringo),
  `g-conj` (`'()` = ⊤), `g-disj` + `g-alt` (committed-choice, guard+body),
  `g-call` (the recursion knot: lazy relation expansion), and one node the
  design note didn't name — `g-blocked`, a budget-blocked (depth-exceeded)
  `g-disj`, the residual analogue of the closure engine's `hard-suspended`
  record. See the correction below for why it's load-bearing.
- **`settle`**: `Goal × State × Depth → #f | (cons residual-conj State)`. The
  store-directed rewriter that replaces the four-way `inf/d` stream, the resume
  closures, `conj/d-run`, `conj/d-resume`, and the hard-suspended record with
  plain data. ~50 lines, one case per node type.
- **Follower integration**: `follower-residual-goal` wraps a residual goal as a
  `(λ ufd)(λ sd)(λ st) inf/d` so it plugs into the EXISTING `follower` /
  `run-and-set-follower` / trigger machinery unchanged — `settle->inf/d` maps
  the settle result onto the `#f` / state / `(state . resume)` protocol at the
  follower-goal boundary. Zero changes to `following.scm` or `mk.scm`.
- **Surface constructors**: `rconde/d`, `rfresh/d`, `r==/d`, … (r-prefixed so
  the engine coexists with the closure engine during migration), plus
  `define-relation/d` which makes a relation's call site return a `g-call`.

## The one design decision that changed: budget counts at g-disj, not g-call

The note tentatively proposed "budget = expansions per path per settle pass …
`g-call` expansion consumes one level," and flagged as an open question whether
that reproduces today's suspend-depth accounting. **It does not, and shouldn't.**

The closure engine's `check-suspend-depth` wraps every `conde/d` and increments
suspend-depth per conde/d entry; `fresh/d` and plain relation calls cost
nothing. In the residual world `conde/d` = `g-disj` and a relation call =
`g-call`. So to match the closure engine's accounting exactly, **depth must be
counted at `g-disj`** (charged on entry, +1 for the guards/body it evaluates),
and **`g-call` must be free** — lazy (to break construction recursion) but
charging no depth, exactly as `fresh/d` charges nothing. Every relational
recursion passes through a `g-disj` (verified: every /d relation body in the
interpreter and views has a `conde/d`), so this still bounds divergence.

Consequence: a budget-blocked suspension is a depth-exceeded `g-disj`
(wrapped as `g-blocked`), not an unexpanded `g-call`. A `g-call` never survives
settling under this policy. This is a cleaner match to the existing engine than
the note's g-call-budget sketch, and it's what makes decision-equivalence hold.

## The bug the differential harness caught: soft vs hard re-sweep

First implementation merged store-blocked and budget-blocked suspensions into
one "leftover" pool and re-swept all of them on any store change. The diverging
test (`(r/d)(r/d)` under a depth limit) then looped forever: a budget-blocked
disj, re-swept at low depth, re-expands, re-budget-blocks, binds fresh vars
(store "changes"), and never reaches quiescence. `conj/d-run` avoids this by
splitting soft (store-blocked, re-iterated on progress) from hard
(budget-blocked, deferred to the next trigger) worklists. Reintroducing that
split — `g-blocked` marks hard, `settle-conj` re-sweeps only soft — fixed it.
Lesson logged: the soft/hard distinction is not incidental bookkeeping, it's
what makes conjunction quiescence terminate.

## Validation (the note's bar: decisions, not byte-identical counters)

Three differential test files, all folded into `test-all.scm` (suite 120 → 157,
all green):

- `tests/residual-engine.scm` (13): the determinacy-goal-forms control tests
  (commit / nondet / nested / conjunction / return-to-first / diverging
  budget-block) and R1 `base-case-patho/d` (refute / succeed / stall / holey),
  hand-ported to r-forms, asserted against the SAME answers the closure engine
  produces.
- `tests/residual-interp.scm` (12 + 6): the WHOLE /d interpreter
  (`eval-expo/d` and friends) ported to r-forms — nested conde/d, guards
  carrying recursive calls (`not-in-envo/d`), Scheme-level env staging — then
  `following-interpreter` (ground eval, partial eval, suspend/resume) and
  `refutation` (5 candidate-set refutations) re-run through it. **The
  interpreter port required ZERO changes to `settle`** — this is the note's
  "ports come for free" claim demonstrated on the most complex /d program in the
  repo, and the strongest single piece of evidence that the representation is
  right.
- `tests/residual-decisions.scm` (6): the explicit per-trigger decision bar.
  For each scenario, run the closure follower and the residual follower over the
  same main search and compare the decision vector
  `(follower-fail follower-singleton follower-suspend suspend-cutoff)`.
  **All six match exactly.** The internal `conde/d`-entry work count differs
  (e.g. 43 vs 39 on refute-cons-shape, 327 vs 299 on refute-rember-else) — the
  "differs in the small" the note predicted and deliberately excluded; `settle`
  threads state differently from `conj/d-run`'s fixpoint, so evaluation-step
  counts diverge while every observable decision agrees.

## Status of the migration

- Step 1 (build runtime layer in parallel): **done** — `residual.scm`.
- Step 2 (port one small view): **done and then some** — R1 + the full
  interpreter.
- Step 3 (differential harness on decisions): **done** — decision vectors
  identical; answers identical across 31 ported scenarios.
- Step 4 (port conde/d/fresh/d macros; remaining ports come free): the macros
  exist as r-forms and the free-port claim is demonstrated. Renaming r→canonical
  is trivial syntax.
- Steps 5–6 (cut over; delete the closure engine; re-baseline) **not done**, on
  purpose. Cutover also has to port R2/TY/NV (incl. `concluding-oro/d`, which
  manipulates `inf/d` directly and is the non-viable R2T — drop or reimplement)
  and re-baseline the synthesis benchmarks + experiments. In a research context
  a subtly-wrong views port that passes tests but mis-measures is worse than two
  coexisting engines; the note sequences validation before cutover for exactly
  this reason. Staged as a follow-on backlog item.

## What this opens (pre-registered in the note)

- **R2T / backlog 1b rescue**: recompute-with-fresh-budget should deepen the
  frontiers *inside* a residual `g-disj`'s alternatives each trigger — the
  single-frontier behaviour R2T's OR-of-suspensions couldn't get. Now
  measurable, once R2/R2P are ported to r-forms. This is the first genuinely
  new research lever the engine unlocks.
- **Explicit scheduler**: the residual `g-disj`/`g-blocked` frontier carries
  name + depth and is a literal work queue; child ordering in `g-conj` is a
  pluggable policy (backlog 1b's "cheap refuters before evalo/d" without engine
  surgery).
