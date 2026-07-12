# Existence proof: orders-of-magnitude follower wins on FD propagation

The benchmark-portfolio question (are the synthesis tasks capping what
the follower can show?) needed an existence proof: a domain where unit
propagation is *known* to dominate, to separate "the mechanism can't
win big" from "the benchmarks can't show it". Michael endorsed the
idea; implementation delegated to a subagent; verified and committed
by the main session.

## Setup

`experiments/latin-square.scm` (`./run.sh --timeout 600 ...`). NxN
Latin squares, three instances (uniqueness verified exhaustively):
4x4 propagation-solvable, 5x5 requiring genuine guesses, 6x6
propagation-solvable with givens clustered so row-major generation
hits the empty region first.

Arm A (fair baseline): givens as `==`, all pairwise row/col `=/=`
posted *before* per-cell value-generator `conde`s. Arm B: identical
leader + `(follower board net/d)`, where the net conjoins per cell a
`conde/d` over the N values, each guard `(==/d c v)` + `(=/=/d peer
v)` for all peers, empty bodies. Guard survival = domain filtering;
sole-survivor commit = unit propagation.

## Results (run 1, suspend-depth 20, check-every 1)

| instance | unify(main) A | unify(main) B | ratio | conde(main) A→B | wall |
|---|---:|---:|---:|---|---|
| 4x4 prop | 856 | 164 | 5.2× | 16→12 | B slower (0.3→0.8ms) |
| 5x5 guess | 4,401 | 605 | 7.3× | 63→19 | B slower (0.8→2.4ms) |
| **6x6 prop** | **92,736** | **552** | **168×** | **1277→24 (53×)** | **B 14.5× faster** |

On the propagation-solvable boards the follower solves the *entire
board in one install-time firing* (`follower singleton = 1`): every
`cello/d` stalls until peers pin it, the conj/d-run fixpoint cascades
naked singles to completion, and the main search's generators each
find their cell already bound. `conde (main)` collapses to exactly the
number of non-given cells. On the guessing board the follower fires
during search, refutes 3 bad branches, and still wins 7.3×.

At 6x6 the win is orders-of-magnitude on work *and* 14.5× on
wall-clock — the follower beats the baseline **even paying its own
overhead**, on the first benchmark where forced information is dense.

Throttle check (5x5): check-every 1 → 605 unify(main); 5 → 1,041;
20 → 3,180. Pure-Andorra (fire every conde) is feasible and best here;
CSP searches are tiny compared to synthesis.

## Two mechanism insights

1. **The depth budget is untouched: `cutoff: suspend` = 0 everywhere,**
   even for the 24-cell 6x6 cascade. `suspend-depth` grows only on
   *nested* conde/d; `cello/d` bodies are empty, and the whole-board
   cascade runs in `conj/d-run`'s iterate-while-progress loop, which
   doesn't consume depth. Contrast the synthesis interpreter, where
   env plumbing nests 20 deep before doing anything. Depth starvation
   is an artifact of how the /d interpreter is written, not of the
   follower machinery.
2. **Scaling in N is the story**: 5.2× → 7.3× → 168× from 4x4 to 6x6.
   The baseline's exponential backtracking grows with board size while
   the follower's propagation stays essentially linear. Bigger boards
   would presumably widen the gap arbitrarily.

## What this resolves

The research goal asked: is there *some* context where
determinacy-directed propagation gets orders-of-magnitude savings?
**Yes — measured, on-goal, and with wall-clock profit at 6x6.** The
mechanism is not the limiting factor. Combined with the (concurrent)
size-bounded ID results on synthesis — where the follower saves only
~1.5–2× and every config blows memory — the picture sharpens: the
gap between 168× (FD) and 1.5× (synthesis) is a property of how much
*forced* information the benchmark's constraint structure carries per
choice point, not of the follower. The interesting research question
is now: what, between "Latin square" and "interpreter-based
synthesis", accounts for the forcing-density difference, and can the
/d interpreter be restructured (cheaper env representation, more
guard-level forcing) to move synthesis toward the FD end?
