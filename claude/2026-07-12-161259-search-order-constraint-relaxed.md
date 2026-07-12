# Direction call: search-order perturbation is now allowed, with a rule

2026-07-12, from discussion with Michael at the start of independent
research mode.

## The original constraint and why it existed

The project originally forbade perturbing the search order at all. The
reason: past related projects (custom search strategies + pruning
mechanisms entangled together) were both slower than baseline mk *and*
impossible to evaluate — you couldn't disentangle how much of the
behavior change came from the pruning mechanism vs. from the exotic
search order, so no apples-to-apples comparison against faster-mk was
possible.

## The update

The findings in `2026-04-12-search-order.md` (fair interleaving
redistributes a pruned branch's scheduler slots size-disordered; a
refutation never closes off a subspace; the depth counter is
anti-correlated with program size) convinced Michael the mechanism
may simply not be able to pay off under the stock mk search order.

So: depth-limiting, iterative deepening on term size, or other search
strategies are now **in scope**, under one methodological rule:

> **Every perturbed search order must also be run *without* pruning as
> its own baseline.** The comparison that matters is
> (search order S + follower) vs (search order S alone), so the
> follower's effect is isolated from the search-order effect.

Comparisons against stock-mk-order baselines are still interesting for
context, but they can't attribute value to the follower.

## Two more calls made in the same discussion

- **Steering is secondary.** The rember-2 steering effect (follower
  finds the intended recursive program where baseline finds an overfit
  trick) is nice, but the research goal is significant *performance*
  gains from pruning/propagation. Prioritize accordingly.
- **Work metric:** wall-clock is the ultimate target, but while we're
  in the "ignore overhead" phase, any principled machine-independent
  work metric is acceptable — my (Claude's) choice. Plan: count at a
  level both arms share, e.g. main-search conde expansions and
  unifications counted inside the unifier rather than at the `==`
  wrapper (which mk internals bypass).

## Consequence for the backlog

The size-bounded-search experiment is confirmed as the centerpiece
("Now" item 1), with the explicit two-baseline design:
size-bounded search alone vs. size-bounded search + follower, across
the rember/append benchmarks. `BACKLOG.md` updated in the same commit
as this note.
