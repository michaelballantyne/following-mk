# Reflection: from "which search order" to "forcing density"

A higher-altitude pass after a day that falsified the project's
leading hypothesis and produced its first orders-of-magnitude win.
Reads on top of: fair-work-metric, suspend-depth-source,
latin-square-existence-proof, size-bounded-id-verdict (all
2026-07-12).

## What we believed this morning

The search-order note (2026-04-12) diagnosed fair interleaving as the
reason follower pruning (~5–6× on the fair metric) doesn't convert to
big wins: refutation never closes a subspace. The plan: size-closed
iterative deepening should let refutations finish subspaces, possibly
reaching the orders-of-magnitude regime. Secondary threads: why the
depth budget gets eaten, whether the metric was fair, what guanxi
does.

## What we know tonight

1. **The mechanism can do exactly what the research goal asks** —
   168× work / 14.5× wall on 6×6 Latin square, by genuine unit
   propagation (whole board solved in one install-time firing). The
   goal's existence question is answered *yes*.
2. **The search order was not the bottleneck on synthesis.**
   Size-closing made the follower's relative value *drop* (5–6× →
   1.5×), invariant across a 75× range of follower effort, and the
   config is memory-infeasible besides. The deeper diagnosis: below
   the match-skeleton size threshold the candidate population is
   caseless-divergent — **unrefutable by examples in principle**, not
   just unpruned in practice. Fair interleaving was never squandering
   large latent pruning; there wasn't much to squander at whole-body
   granularity.
3. **The right variable is forcing density**: how much
   uniquely-forced information the constraint structure yields per
   choice point. Latin square: dense (each committed cell forces
   neighbors). Whole-body interpreter synthesis: sparse (candidates
   below the skeleton threshold force nothing example-visible; env
   plumbing burns the depth budget that forcing would need). rember-2
   sits in between — a seeded skeleton with one hole — and that's
   precisely where the follower produced its steering win. This
   gradient is now the project's organizing axis.
4. Instrument-grade side results: fair work metric; per-site depth
   tally (95.7% env plumbing); follower memory scales with live
   frontier, not suspend depth; ID work at low bounds is an artifact
   of the unsound depth cutoff (linear in it).

## Direction going forward

The research question refines from "can propagation save
orders-of-magnitude in some context" (answered: yes) to:

> **How much forcing density does interpreter-based synthesis admit,
> and what representation choices (candidate structure, environment
> representation, second analyses) raise it?**

Priority order for next sessions:

1. **Skeleton-seeded synthesis** (in flight as of this entry): seed
   `(match l ['() ,h1] [(cons a d) ,h2])` so every candidate has a
   base case and low-size populations are example-refutable. The
   direct fix to the discovered bottleneck; rember-2's win predicts
   this is where the follower earns its keep.
2. **First-order /d representation** — now triply motivated:
   debuggability, per-trigger rebuild cost, and the frontier-memory
   explosion that blocks all bounded-search follower work.
3. **Env-plumbing removal** (tagged applications, cheaper lookup) —
   frees the depth budget for semantic forcing; 95.7% of cutoffs and
   a third of guard work.
4. **Second-view followers** (termination/skeleton analysis, types):
   kill structurally what examples can't. The symmetric compile-from-
   one-source vision (Michael) constrains the *product*; a second
   view is still one source, differently compiled.
5. **FD scaling** (N=8+, Sudoku) — cheap mapping of the win regime's
   growth.

Dropped/demoted by this reflection:
- **Weighted resumption / KL scheduling**: scheduling refinements
  can't beat a forcing-density ceiling; revisit only if seeded
  synthesis shows latent pruning being squandered again.
- **Size-bounded ID as a search strategy** for this grammar: worse
  than fair search even without a follower. The machinery stays
  (useful as an experimental control and for level-exhaustion
  measurements).
- **Pruning-ceiling oracle as a standalone**: partially answered —
  at whole-body granularity the ceiling is low *for structural
  reasons*; the seeded experiment supersedes it.
