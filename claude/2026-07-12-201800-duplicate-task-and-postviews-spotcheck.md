# Third task (duplicate) + post-views stream spot check (rung-4 families)

Two results, both from Michael's suggestions (broaden benchmarks;
keep sampling the explored stream).

## duplicate: the views story strengthens

`experiments/duplicate-*.scm`: synthesize "each element doubled" —
answer `(match l ['() l] [(cons a d) (cons a (cons a (duplicate d)))])`,
size 38, single param (exercises rung 2's one-position case), no `if`,
double-cons. Verified ground-truth sanity first.

| arm | outcome | unify(main) | wall |
|---|---|---:|---:|
| fair search, no follower | canonical answer | 417,928 | 0.29s |
| ID baseline (no views) | timed out mid-level-31, never near 39 | — | >600s |
| ID + 3 views, ce20 | canonical answer at 39 | 110,775 | 85ms |
| **ID + 3 views, ce1** | **canonical answer at 39** | **66,432** | **432ms** |

Cross-task table, views-ID total-to-answer vs fair baseline
(unify-main): rember 1.2×, append 1.8×, **duplicate 6.3×** better.
Every task so far: ce1 beats ce20 on main work in the enumerative
regime; depth-cut stays 0 (the ladder covers this answer shape too —
no new divergent family); the ID-without-views baseline blows up on
every task. Note a measurement subtlety the subagent caught: the
answer's term-size-lb must be computed with real logic vars as
pattern holes (38), not quoted symbols (43).

## Post-views spot check: what survives rungs 1–3 (rember, bounds 35–43)

160 candidates sampled from the surviving stream. Two dominant doomed
families that all three views pass:

1. **Vacuous conditions, ~33% of the stream**: `(if (= X X) then
   else)` with syntactically identical condition arguments — the else
   is dead code, the candidate is equivalent to its own then-branch,
   which size-ordered search already enumerated at smaller size. So a
   non-vacuity constraint is minimal-answer-preserving (a canonicity
   restriction, not a semantic one). Implementable with the existing
   stall discipline — compare the two condition positions *as program
   text*: `(conde/d ([] [(==/d c1 c2)] [fail]) ([] [(=/=/d c1 c2)]
   []))` — stalls while holey, refutes on committed identical text
   (view build in progress as of this entry).
2. **Parameter-irrelevant recursive branches, ~20–25%**: bodies whose
   cons-branch never consults `e` (including numeral-literal holes
   that absento bars from ever equalling any example's `e`) —
   structurally cannot be rember. Cheap check: `e` dataflow-reachable
   in the recursive branch (Myth-style relevance, framed as a
   canonicity restriction). Needs its own design pass. Related
   benchmark gap: the current example suite cannot refute
   e-independence at all (no two examples share `l` with different
   `e`) — add such a pair regardless.

Estimated joint ceiling: ~2× further stream reduction. This
sample-diagnose-refute loop is now the mainline per the evening
regime call (ignore overhead; exhaust search-space reductions).
