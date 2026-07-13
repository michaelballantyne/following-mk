# Cutover complete: the closure engine is deleted (backlog 3b, second half)

Executes the design in `2026-07-13-081155-cutover-design.md` (Opus agent),
reviewed independently before commit (advisor). There is now exactly one /d
engine in this repository: the residual-goal `settle` evaluator. Suite
120 (pre-migration) → 114 (post-cutover), all green — the difference is
accounted for exactly (see below), not a coverage regression.

## What changed

- **`following.scm`**: the closure engine is gone —
  `inf/d?`/`case-inf/d`/`hard-suspended`/`check-suspend-depth`/`check-
  unsound-fail-depth`/the closure `conde/d` macro + `conde/d-runtime`/
  `conj/d-run`/`conj/d-resume`/`conj/d*`/the closure `fresh/d`/
  `wrap-for-depth-limit`/the six curried primitive constructors/
  `*unsound-fail-depth*`/its cutoff counter/the closure `tally-step` and
  `tally-wrap-resume`, all deleted. `follower-aux`/`run-and-set-follower`
  rewritten to call `settle` directly — `state-F` now holds
  `(residual-goal . term)`, plain data, not a curried closure. Everything
  engine-agnostic (counters, view-tally bookkeeping, `*suspend-depth*`,
  `*main-unsound-depth*`, the productivity tally) is untouched.
- **`residual.scm`**: every `r`-prefixed constructor took its canonical name
  (`conde/d`, `fresh/d`, `==/d`, `=/=/d`, `absento/d`, `symbolo/d`,
  `numbero/d`, `stringo/d`, `succeed/d`, `fail/d`). The migration-era
  translation shim (`follower-residual-goal`/`settle->inf/d`/
  `residual-resume`) is deleted — nothing needs it once the follower speaks
  `settle` natively. New: `g-tally` (a thin wrapper node for `tally/d`,
  `tally-blocked?`, and a `partition-blocked` extension) — see below.
- **`views.scm`**, **`restricted-interp-following.scm`**,
  **`restricted-interp-untyped-following.scm`**: edited IN PLACE, not
  replaced by their `residual-*` staging counterparts. This mattered:
  `residual-views.scm` had ZERO inline self-check tests of its own (all
  differential coverage lived in a separate test file that only sampled 19
  of `views.scm`'s 47) — swapping files would have silently cut coverage by
  more than half. The actual required change, once names are canonical, is
  minimal: recursive `define` → `define-relation/d` (the g-call laziness
  requirement is permanent, not migration scaffolding), mirroring the exact
  recursive/non-recursive choices already validated in the staging files.
  Every comment and test in `views.scm` survives untouched except R2T's
  section, whose *code* is gone (it manipulated `inf/d` directly, no
  residual analogue exists) but whose *analysis* is kept as documentation,
  pointing at the existing non-viable-negative note and backlog 3c.
- Deleted the staging files (`residual-views.scm`,
  `residual-interp-following.scm`, `residual-interp-untyped-following.scm`)
  and all six `tests/residual-*.scm` differential files — their job (prove
  the port works) is done, and comparing the engine to itself is
  meaningless now. Salvaged the two things with no duplicate elsewhere: the
  direct `settle`-level shape tests (→ new `tests/engine-shape.scm`) and the
  dead-alt-pruning witness (→ folded into `tests/guard-robustness.scm` as a
  single-engine assertion, hard-coded vector, no more closure comparison
  side). Deleted the 20 now-redundant `experiments/*-residual.scm` arms —
  the *original* experiment files call `views.scm`'s relations by canonical
  name, so they already run on the residual engine with zero changes.

## The one real design decision: `tally/d` as `g-tally`

No residual analogue existed (flagged as an open question at port time).
Built as a thin wrapper record (`g-tally label goal`), with `settle-tally`
mirroring the old `tally-step`'s refute/force semantics exactly, adapted to
`settle`'s `#f | (cons residual state)` protocol. The one subtlety that
would have been easy to get wrong: on a suspended result, **each surviving
conjunct gets re-wrapped in its own same-labeled `g-tally`, not the whole
flat pool in one wrapper node**. A single whole-pool wrapper would read as
one opaque soft node to `partition-blocked`, hiding a budget-blocked child
underneath it and re-expanding that child on every store change —
*relocating the exponential commit-splice bug from the engine review
(finding 1) inside the tally wrapper instead of fixing it.* `tally-blocked?`
extends `partition-blocked` to see through the wrapper so a budget-blocked
child stays hard. A dedicated regression test
(`tests/guard-robustness.scm`: "tally/d-wrapped diverging guard...") wraps
a diverging guard in `tally/d` and asserts the cutoff count matches the
unwrapped case exactly — the test that would have caught finding 1 had
`g-tally` existed then.

## Test count: 120 → 114, fully accounted

−11 (R2T's 11 self-check gates, removed with its code) +2 (the pruning
witness + the tally/g-tally regression, both new) +3 (salvaged
`engine-shape.scm`) = 114. Nothing silently dropped; the arithmetic closes.

## Advisor review found and fixed three more things before commit

Independent review (not by the executing agent) caught:

1. **A `fail/d` naming collision.** `residual.scm`'s new canonical `fail/d`
   (a bare `g-prim` value) was silently clobbered by `tests/guard-
   robustness.scm`'s long-standing local helper of the same name (a
   zero-arg procedure) — Chez top-level `define` rebinds a global, it
   doesn't lexically shadow, so loading that test file left the canonical
   `fail/d` unreachable for anything loaded afterward. Currently harmless
   (nothing calls the canonical value; the collision would fail loudly, not
   silently, if it ever mattered) but a real landmine. Fixed by renaming the
   local, newer-relative-to-the-primitive helper to `fail-cleanly/d` rather
   than touching the shared primitive.
2. **A stale mechanism comment.** `guard-robustness.scm`'s "SURPRISE" case
   (case 3a) explained *why* a sole-clause internally-ambiguous guard still
   commits by naming closure-engine internals (`conde/d-runtime`,
   `(nondeterministic)`, `g-thunk`) that no longer exist. The *conclusion*
   still holds (the test still passes); rewrote the mechanism description
   in terms of `settle-disj`'s actual loop.
3. **Three experiment files broken by the cutover but out of the design
   note's scope** (flagged by the executing agent as a decision for the
   advisor, not silently resolved):
   - `experiments/latin-square.scm` (the FD existence-proof flagship result)
     had exactly one closure dependency, `conj/d-list`, built on
     `conj/d-run` to conjoin a runtime-length list of goals (needed because
     the Latin square's peer-list length depends on N). Under the residual
     representation this is trivial — a `g-conj`'s `goals` field is already
     a list — so the fix is a one-line `(define (conj/d-list gs)
     (make-g-conj gs))`. Verified: reruns the 4×4 and 5×5 instances,
     correct unique answers on both arms.
   - `experiments/negative-view-branch-vacuity.scm` had the same
     `conj/d*`-on-a-fixed-arity-list pattern (one-line fix), PLUS a second,
     less obvious bug: its own local `non-vacuous-brancheso/d`/`rands-non-
     vacuous-brancheso/d` pair (mirroring `views.scm`'s `non-vacuous-
     testso/d`/`rands-non-vacuouso/d`, which the cutover DID convert) was
     never given `define-relation/d`, since this file was out of the
     design's scope. Plain mutually-recursive `define`s here now unfold
     infinitely at construction time under the residual engine's eager
     expansion, independent of the actual candidate — it hung (not a clean
     error, a SIGKILL, consistent with runaway construction-time recursion
     exhausting stack/heap before Chez could report anything). Converted
     both to `define-relation/d`; verified the file now runs to completion
     with all gates passing.
   - `experiments/r2p-gates.scm` mixes R2P gates (still live) with an R2T
     gate family (permanently gone, no residual analogue, ever). Removed
     only the R2T family; the 56 remaining R2P gates all pass.
   - The four `experiments/*-full-id-views-r2t.scm` benchmark arms are
     irreparable — R2T is not merely unported, it no longer exists as code
     anywhere, and their entire purpose was measuring it. Deleted outright;
     their conclusions are already recorded in prose (views.scm's preserved
     R2T documentation comments and the dedicated
     `...-040000-r2p-r2t-termination-generalization.md` notebook entry).

`experiments/archive/` and `synthesis/` were checked and are unaffected
(spot-checked `synthesis/rember-1.scm` runs correctly on the residual
engine with zero changes, as expected — it only ever used canonical
`follower`/`fresh/d` names).

## Verdict

The migration (backlog item 3, opened `2026-07-13-042503`) is complete: one
engine, decision- and answer-equivalent to the one it replaced on everything
measured, with the design's stated motivations (per-fire rebuild cost via
future stamps, memory, schedulability, printability) now available to build
on rather than deferred behind a coexistence shim. Next natural step, not
started here: the explicit scheduler reading the residual `g-disj`/
`g-blocked` frontier directly — the thing this whole representation change
was for.
