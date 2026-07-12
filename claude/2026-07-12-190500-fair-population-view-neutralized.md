# Fair-search population: rung 1 is OR-neutralized by the committed skeleton

Second round of Michael's stream-sampling suggestion: ~650 candidates
each from fair-search rember-full, baseline vs termination-view-only
follower (ce20). Both found the canonical answer; the question was
attention allocation.

## The two searches explore near-disjoint work distributions

- Size-bounded ID stream (earlier entry): ~98% caseless applications.
- Fair-search stream (both arms): **99% match-skeleton candidates** —
  the outer `(match l ['() e1] [(cons x y) e2])` commits almost
  immediately and all subsequent work fills `e2`. `e1` is trivially
  clean (`l` or `'()`) in ~92%.

Same grammar, same conde order — the difference is where each
scheduler's *work* concentrates: fair interleaving geometrically
demotes the deep app-spines that dominate ID levels; ID's exhaustive
levels pay full price for exactly those spines.

## Rung 1 is inert here for a mechanistic reason, not a scheduling one

`base-case-patho/d` requires *some* self-call-free path. With a clean
committed `e1`, the match's path-OR is satisfied forever, and the view
never constrains `e2` — where all the work happens. Confirmed in the
deltas: baseline vs view streams are flat within noise on every
composition metric (e2 shape distribution, self-call presence 42→44%,
buried-letrec presence 44→46%).

Two actionable observations:

1. **Rung 2 has no OR.** Decreasingness is a for-all over self-calls,
   so it constrains `e2` regardless of the clean base case — rung 2
   should bite under fair search where rung 1 cannot. Test as soon as
   the rung-2 prototype lands (prediction: fail-counter finally moves
   under fair search).
2. **Buried letrec junk is ~45% of `e2` content** — rember-full.scm
   lacks ex3's `(absento 'letrec q)`; rung 1's letrec refutation only
   fires on a whole-term letrec. Add the absento to the benchmark (or
   extend the view to refute buried letrec-with-no-clean-path).

Caveat on the analysis agent's headline example: it flagged
`(match l ['() l] [(cons a d) (rember a d)])`-style fills as loopholes;
several such are actually terminating (recursion on the strict tail) —
the population statistics stand, but per-candidate divergence calls in
its prose should not be trusted without checking.
