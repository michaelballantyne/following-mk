# Capstone: size-closed ID + termination view solves both synthesis tasks

The day's arc closes. This morning's hypothesis ("size-closed search
converts follower pruning into big savings") was falsified in its
original form (`...-174500-size-bounded-id-verdict.md`) because the
enumerative population was divergence-dominated and memory-infeasible.
The termination view (`...-184500-termination-view-results.md`) fixed
refutability; this entry reports what the combination does.

## Results (all `check-every 20`, `main-unsound-depth 1000`)

**append-full** (answer size 35):

| arm | outcome | total unify(main) | wall |
|---|---|---:|---:|
| ID baseline | died mid-27; 19.6M spent on 11–23 alone; never saw answer | — | >3500s |
| ID + evalo/d follower (sd 5/20/200) | OOM at bound 15, every config | — | — |
| **ID + view + evalo/d** | **canonical answer at 35** | **344,615** | **2.0s** |
| **ID + view only** | **canonical answer at 35** | **381,197** | **0.17s** |
| fair-search baseline (reference) | canonical answer | 442,724 | 0.22s |

On the levels the ID baseline could finish (11–23), view+evalo/d does
26.8k vs 19.6M — **731×**. Per-level exhaustion up to ~550× cheaper;
`depth-cut` drops to ~0 (each level's dozen divergent spines refuted
at their root instead of unfolded to the cutoff — the exact mechanism
the composition entry predicted); memory goes from OOM to trivial.

**rember-full** (answer size 47): view-only ID exhausts every level
through 43 — the plain baseline died mid-31 after ~1h — and finds the
canonical answer inside level 47. Levels 15/19/23/27: 18.9k / 36.7k /
100k / 303k unify(main) vs baseline 325k / 1.02M / 3.45M / 11.9M
(**17–39×** per level). Total to answer: 57.6M unify(main), 86s.

**Attribution**: the syntactic view is load-bearing. evalo/d alongside
it improves append main-work ~10% while costing 190× more follower
work (2.54M vs 13.3k unify(follower)). The old evalo/d-only follower
never completed a single full-task ID level at any configuration.

## Cross-regime reading (the honest ledger)

- **Enumerative regime**: transformed from infeasible to routine.
  This is where "work to exhaust a level" is well-defined and
  perturbation-immune (a level is a fixed finite set; sound pruning
  is monotone) — the methodological answer to mk fair search's
  easy-perturbability (Michael's point today; we measured constraint-
  only commits *doubling* fair-search work).
- **vs fair search on total work-to-answer**: append comparable
  (381k vs 443k); rember ~18× costlier (57.6M vs 3.2M) — the price
  of exhausting answer-free levels 39/43, i.e. the price of the
  smallest-answer guarantee fair search doesn't offer. (April's
  rember-2 trick-answer episode is exactly what the guarantee buys
  out.)
- **Next lever, identified by counters**: rember levels 39/43 still
  show depth-cut 918/3160 — candidates with base cases that diverge
  at runtime (non-decreasing recursion), unrefutable by examples,
  refutable by **rung 2** (structurally-decreasing recursive
  arguments). Those levels dominate total cost. Rung 2 is now the
  highest-leverage single addition.

## Project-identity note

Recorded from discussion with Michael today, as the two long-term
distinguishing factors to maintain:

1. **Write once, run all directions** — a plain relational
   interpreter yields backward example propagation ~for free (no
   witness functions / abstract transformers / hand unevaluation).
2. **Composable information sources** — interpreter, typechecker,
   termination constraints as separate relations composed in one
   store, never one super-algorithm.

Today's result is a direct exercise of (2): `base-case-patho/d` is
~40 lines, written independently, conjoined with `evalo/d` inside the
follower by plain `fresh/d`. And Michael's stated interest in
exploring **other search strategies** (even losing mk's implicit
heuristics and recovering them manually) is consistent with both
identities: the views compose in the relational substrate regardless
of who schedules them. Today showed mk's implicit heuristics are
identifiable and replaceable: interleaving's geometric spine-demotion
→ the view's sound refutation; ordering luck → the size guarantee.
