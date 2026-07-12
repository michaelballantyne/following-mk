# Rung 2 lands: size-guaranteed search now cheaper than fair search

`decreasing-recursiono/d` (in `experiments/termination-view2.scm`,
drivers `experiments/{rember,append}-full-id-tv2.scm`) implements
structurally-decreasing recursion as a /d constraint. The
soundness-critical *fixed-position* semantics (any-position decrease is
unsound — argument-swapping recursions never globally decrease) falls
out of conde/d for free: an outer conde/d over parameter positions,
each clause's guard being the entire position-i decreasingness walk —
both-live stalls, one-live commits, none refutes. Classification sets
(`same`/`smaller` relative to p_i) grow at match sites when the
scrutinee is a classified bare var; a self-call is decreasing at i iff
its i-th arg is a `smaller` var. All 9 validation gates pass (accepts
both canonical answers; stalls on holes; refutes recurs-on-same,
cons-expression args, and the argument-swap case).

## ID results (ce20, same settings as capstone; rung-1 baseline
reproduced exactly first — clean same-machine comparison)

**rember-full**: total to canonical answer **57.6M → 2.62M unify(main)
(22×), 83s → 1.2–1.3s wall (~69×)**. Per-level ratios grow with bound
(1.4× at 19 → 36.2× at 43) exactly as the diverging-population share
predicted. **append-full**: 381k → 248k.

**depth-cut = 0 at every level, both tasks** (rung-1-only spent 4,421
rember cutoffs). The two rungs cover the entire divergent population
on these tasks — caseless (rung 1) + base-case-but-non-decreasing
(rung 2) — so the unsound `*main-unsound-depth*` crutch never fires:
the enumerative search is now *sound*, level-complete, and
guaranteed-minimal, with no unsound knob doing hidden work.

**The headline: total-to-answer is now BELOW fair search on both
tasks** — rember 2.62M vs 3.2M, append 248k vs 443k unify(main). The
smallest-answer guarantee, which cost 18× yesterday-morning's
arithmetic, is now free-and-better. All the gain is in exhausting
answer-free levels (answer-level cost unchanged) — the views make
*closing subspaces* cheap, which is precisely what the original
research framing wanted refutation to do.

## Fair-search probe (prediction from the population entry): half right

Fair-search rember with rungs 1+2 (no evalo/d), ce20: **5,629
follower refutations** — rung 2 does constrain the `e2` slot where
rung 1 was OR-neutralized, as predicted. But unify(main) is flat
(3.26M vs 3.23M baseline): the refuted candidates were already being
soft-demoted by interleaving at near-zero marginal cost. Confirmed
from both directions now: **refutation converts to savings only in
regimes where live candidates must be paid for in full.** Under fair
search the scheduler hides the junk; under ID the junk is the bill.

## Composition note

Identity #2 exercised again: rung 2 is an independent relation,
conjoined by `fresh/d` next to rung 1 (and optionally evalo/d) — three
views in one follower, no coordination code. Also a new conde/d
technique: clause guards as full semantic checks (not shape tests),
inheriting stall/commit/refute — including commit-with-deferred-check
when one position fails and the other is still holey.

## What this opens (backlog updated)

- The unsound main-depth knob is now dead weight on these tasks —
  candidates for removal or demotion to pure diagnostics.
- Rung 3 / third view: the typechecker — types force at partial holes
  where examples can't (many-to-one), and `(rember e a)` (accepted by
  rung 2, wrong by types) is the first concrete target.
- Harder benchmarks: with the enumerative regime sound and cheap, the
  suite can grow past rember/append.
