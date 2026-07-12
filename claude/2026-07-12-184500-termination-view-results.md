# Termination-view follower: works as designed; pays off by regime — and a stale premise falls

`base-case-patho/d` (in `experiments/termination-view.scm`, with
`tv-*` drivers) is the rung-1 termination check as a /d constraint:
"some control path through the body avoids applying the recursive
name." Shape discrimination lives in conde/d guards, so holes stall,
committed structure commits, and all-paths-sealed refutes.
Path-OR is a conde/d whose clause *guards* are the recursive checks —
both-fail refutes, both-live stalls (sound, just unconfirmed).
No-shadowing of the recursive name is imposed (=/=/d on match pattern
vars), making self-call detection purely syntactic. All six semantics
checks pass, including refuting `(cons ,h1 (rember e ,h2))` *through
the holes* and stalling without over-commitment on a holey match.

## Correction first: the whole-body baselines TERMINATE under fair search

Verified twice (subagent + main session): plain no-follower
rember-full finds the exact canonical answer in **3.5–6.8s**
(uncontended vs contended), append-full in **0.22s**. The
"rember-full doesn't terminate" belief came from April-era notes
(the interpreter and benchmarks have both changed since — grammar
restrictions, absento constraints, example ordering) and from today's
ID regime, and the cheap control was never re-run until now.
Advisor lesson recorded: run the baseline control before building the
apparatus that assumes its result.

Corollary: the April impression was likely also shaped by the
*follower* arm at the old default `check-every=1`, which really does
time out (B0-ce1: append 0.22s → >200s timeout, rember → >300s at
~5GB). **ce1 is catastrophic under fair search too** — the earlier
"fair search + follower runs fine" observation was specific to ce20.

## Results (fair search; wall times† under CPU contention)

rember-full: baseline A 6.8s† / 3.23M unify(main). B0 (evalo/d, ce1)
TIMEOUT at ~5GB. B1 (base+evalo/d, ce1) TIMEOUT but at **1.2GB** —
the view's refutations shrink the live frontier ~4×. B1-ce20 42s†,
2,530 refutations, main work ≈ baseline. B2 (view only) ce20: 4.1s,
main work ≈ baseline (3.25M).

append-full: A 0.22s. B0-ce20 1.6s† and mildly *below* baseline main
work (390k vs 442k). B1-ce1 12.4s†, 2,591 refutations. B2-ce20 0.32s,
≈ baseline. Every terminating arm found the exact canonical answer.

## Three findings that matter

1. **Regime-dependence, sharpened.** Fair interleaving demotes deep
   branches geometrically — an implicit soft depth penalty — so
   divergent caseless spines never dominate *work* under fair search
   the way they dominate the *size-bounded* stream (98% of work, per
   the composition entry). The view is therefore ≈neutral under fair
   search (B2-ce20 within noise of baseline) and its target-rich
   regime is exactly the enumerative one — which is memory-blocked
   for followers. But finding 2 cuts into that circle:
2. **The view shrinks follower memory ~4×** (1.2GB vs 5GB at ce1) by
   killing divergent branches before their state accumulates. The
   thing that blocks the enumerative regime is the thing the view
   reduces. Immediate follow-up (running as of this entry): does
   append ID bound-15 — which OOM'd at every config — become feasible
   with the view conjoined?
3. **Constraint-only commits are invisible to the productivity tally,
   and they are not free.** B2-ce1 rember: 221k/221k triggers scored
   "unproductive" (the tally walks the term structurally; symbolo/=/=
   commits don't move it), yet main-search work *doubled* (6.16M vs
   3.23M unify; conde 227k vs 117k). Sound early-committed
   constraints perturbed the search adversely — the mirror image of
   the rember-2 steering effect, and a caution for all future
   "propagation is harmless" reasoning. Fix the tally to also diff
   the constraint store before trusting it again.

Also: ce20 fires produce *more* refutations than ce1 on the view-only
arm (106 vs 8 on rember) — by the 20th conde a candidate is committed
enough to be refutable; at every-conde frequency the follower mostly
sees still-open structure. Throttling helps soundness-per-fire, not
just overhead.

## Status

The relation is correct and cheap; it holds the rung-1 spot of the
termination ladder (rung 2: structurally-decreasing recursion, per
discussion with Michael). Its payoff thesis is now: *enabler for the
enumerative regime* (memory + refutation density) rather than
*accelerator for fair search*. The fair-search population comparison
(sampling with/without the view — Michael's suggestion) runs next.
