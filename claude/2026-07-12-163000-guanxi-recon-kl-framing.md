# Guanxi recon: what its search is, and a KL-divergence framing of our problem

Michael relayed a remark from Edward Kmett: our pruning-vs-search-order
problem "has something to do with KL divergence," and his logic
language guanxi may have a search that avoids it. A subagent explored a
clone of https://github.com/ekmett/guanxi plus Kmett's public talks and
threads. Digest below; conclusions are mine.

## What guanxi's search actually is

Guanxi is a **propagator network first, search second** (`src/Signal.hs`:
propagators run to a quiescent fixpoint before any branching;
`src/FD/Var.hs`: finite-domain vars shrink monotonically and only
introduce a disjunction at *grounding* time, after propagation has
narrowed the domain). That discipline — push all deterministic
information, branch only where nothing more propagates — is the Andorra
pattern made explicit, i.e. structurally the same thing our follower
does, but over richer domains and applied to the *whole* search rather
than one wrapped conjunct.

The surprise is the disjunction layer (`src/FD/Monad.hs`): its
`MonadLogic` instance sets `interleave = (<|>)` over a CPS LogicT
(`src/Logic/Cont.hs`) — i.e. **plain depth-first backtracking, no
fairness at all**. The library *has* fair interleaving machinery
(`src/Logic/Class.hs`, reflection-without-remorse queues) and the FD
monad deliberately opts out. Guanxi's bet: strong propagation refutes
bad branches before you commit to them, so you don't need fair
interleaving to hedge. That bet is not directly available to us —
mk-style relational synthesis relies on interleaving for completeness
in a way FD problems don't — but it's the same thesis as this project's,
taken further: determinacy-directed work should *replace* scheduling
hedges, not coexist with them.

## The KL connection (reconstructed, not sourced)

No published Kmett statement connects guanxi to KL divergence — the
agent searched honestly and found none. But `wip/` is suggestive:
`wip/RationalArithmetic.hs` contains a working arithmetic coder next to
a small search monad that walks the binary choice tree by coin-flip and
*collapses exhausted subspaces* (`branch Done Done = Done`), with a
comment trailing off "...these can be used to help inform a". Arithmetic
coding is the textbook bridge to KL: coding under model Q when the truth
is P costs H(P) + D_KL(P‖Q); the excess over optimal *is* the KL
divergence.

Applied to search: treat the search tree as a distribution over leaves;
a branch's ideal exploration budget is proportional to its posterior
mass; refuting a branch sets its mass to zero and **renormalizes the
survivors** — the freed budget flows to the refuted branch's neighbors
under the measure, not to whoever a round-robin reaches next. In this
frame:

- **mk's fair interleaving is the uniform coding distribution over live
  streams** — maximally ignorant, maximal divergence from any sensible
  posterior over where the answer lives.
- Our observed pathology (pruning redistributes slots size-disordered;
  a size-3 hole and a size-31 candidate get the same slot) is exactly
  "exploring under a distribution far from the posterior."
- **Size-bounded iterative deepening is the special case** of a
  2^(−size)-ish prior: zero mass above the bound, roughly uniform
  within it. So the experiment we're already running is the crudest
  member of a family, and the KL frame tells us what the refinement
  ladder looks like.

## Concrete transferables (in increasing ambition)

1. **Size-bounded ID** — already in flight. The KL frame predicts its
   payoff is monotone in how well "small programs first" matches the
   true answer-size distribution, which for interpreter synthesis is
   strongly small-biased.
2. **Weighted resumption**: when the follower kills a branch, pull the
   next stream from a priority queue keyed by accumulated cost
   (−log₂ prior, e.g. current term size) instead of returning to the
   interleaver's round-robin. This is the direct "renormalize on
   refutation" mechanism, implementable at our conde hook / mplus
   layer.
3. **Mass accounting as instrumentation**: attach a running
   log-probability to each stream and measure whether follower pruning
   reduces *remaining probability mass* faster than it reduces
   *scheduler slots*. That gap is the KL story made measurable, and
   would explain quantitatively why 5–6× pruning doesn't convert under
   fair interleaving.

## What does not transfer

The propagator network itself (we'd need rich domains; the follower is
our weaker analogue), DLX/ZDD exact-cover (needs an explicit finite
cover matrix), and pure DFS (reintroduces divergence hazards that mk's
interleaving exists to avoid).

## Effect on the backlog

- Size-bounded ID gains a sharper interpretation: it's the first rung
  of a prior-directed-search ladder. If it works, weighted resumption
  (rung 2) is the natural follow-up and subsumes "which ID step size."
- Added "mass accounting" as a candidate instrument if the ID results
  are ambiguous.

Guanxi clone was in session scratchpad (ephemeral); key files if
re-cloning: `src/Signal.hs`, `src/FD/Monad.hs`, `src/FD/Var.hs`,
`src/Logic/Cont.hs`, `wip/RationalArithmetic.hs`,
`wip/ProbabilisticTree.hs`.
