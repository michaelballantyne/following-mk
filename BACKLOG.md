# Backlog

Roughly-prioritized open questions and experiments. Draw new items from
recent [`claude/`](claude/) notebook entries, `TODO.md`, and the research-goal
framing in [`README.md`](README.md). An item resolves when answered *either
way*; move it to Resolved with a one-line answer + link to the `claude/` entry.

**Project identity** (Michael, 2026-07-12) — the two distinguishing
factors to maintain, whatever the search strategy becomes:

1. *Write once, run all directions*: a plain relational interpreter
   yields backward example propagation approximately for free — no
   per-operator inverse semantics, abstract transformers, or
   hand-written unevaluation.
2. *Composable information sources*: interpreter, typechecker,
   termination constraints, etc. as separate relations composed in one
   constraint store — never one super-complex algorithm.

**Research-goal status** (2026-07-12): the original existence question —
orders-of-magnitude savings from determinacy-directed propagation in
*some* context, overhead ignored — is **answered yes, with headroom**:
168×→11,092× (work) and up to 934× (wall) on FD Latin squares, and
731× vs the enumerative baseline on append synthesis once the
termination view made the population refutable. The refined program:
raise the *forcing density* available to composed views in synthesis,
and move to explicit search strategies where measurements are
perturbation-immune (mk fair search is easily perturbed — measured:
sound constraint-only commits doubled its work). Methodology rules
stand: every perturbed search order also runs without pruning as its
own baseline; fair work metric = unify(main)/conde(main).

## Now

- [ ] **Rung 2 of the termination ladder: structurally-decreasing
  recursion.** The single highest-leverage addition identified by
  counters: rember ID levels 39/43 dominate total cost (52M of 57.6M
  unify) and still show depth-cut 918/3160 — candidates with base
  cases that diverge at runtime (recursive calls on non-decreasing
  args), unrefutable by examples, syntactically refutable by requiring
  self-call args to descend from the match scrutinee's cons-parts.
  Extend `base-case-patho/d` (needs scrutinee/pattern-var provenance
  through the term walk). Prediction: collapses the dominant levels
  the way rung 1 collapsed the divergent spines.

- [ ] **Explicit search strategies** (Michael's direction: interested
  in other searches even if mk's implicit heuristics must be recovered
  manually). The ID harness is the crude first instance; design the
  next: a size/cost-frontier priority queue over a first-order
  representation of the search, with the views as the pruning/forcing
  layer. Today's map of what mk's interleaving was implicitly doing —
  geometric demotion of deep spines (→ replaced soundly by the
  termination view), ordering luck (→ replaced by the size guarantee),
  completeness via fairness (→ levels complete by construction) — is
  the checklist of heuristics to recover explicitly. Neither project
  identity constrains the scheduler; protect the relational substrate
  the views compose in, not the interleaving.

- [ ] **First-order representation of the /d search.** Promoted from
  Later: it is now the substrate for three needs at once — custom
  search strategies (above), the follower memory problem (frontier ×
  F-cell closure chains; the view shrank it 4× but bigger tasks will
  re-hit it), and eventually mkcdcl-style provenance. Design note
  first: what the tree looks like, what survives across triggers.

## Next

- [ ] **Typechecker as a composed view.** The long-standing TODO item,
  now concretely motivated as the third view (identity #2) and by the
  literature contrast (Myth/Synquid get their power from types). The
  restricted language already has annotations. Which of
  evaluator/typechecker leads, per the old question — or do they
  simply compose symmetrically like evalo/d + base-case-patho/d did?

- [ ] **Fix the productivity tally.** Constraint-only commits
  (symbolo/=/= etc.) are invisible to the walk*-based check — B2-ce1
  scored 221k/221k triggers "unproductive" while doubling main-search
  work. Diff the constraint store too. Until then, don't trust
  "trigger productive" as the propagation signal.

- [ ] **Why is check-every=1 catastrophic?** 0.22s → >200s (append
  fair) is ~1000×, worse than linear per-trigger cost would suggest.
  Profile one: is it re-walking the whole term per trigger,
  reconstructing conj/d structure, constraint-store churn, or
  something superlinear in trigger count? Matters because pure-Andorra
  (fire always) is the FD regime's best config — the synthesis/FD
  split here is unexplained.

- [ ] **Map the FD win regime further** (cheap): Sudoku-style
  benchmark, instances needing more guessing, and where the
  crossover to baseline-wins sits as propagation-solvability decreases.

- [ ] **Guard-robustness tests** (unchanged): diverging guards,
  multi-answer guards, store-extending guards that fail later — the
  'nondet-on-real-ambiguity invariant is load-bearing for soundness.

- [ ] **Document the /d sharp corners + follower guarantees note**
  (unchanged): recursion not through conde/d diverges under fresh/d;
  end-of-run trigger doesn't force suspended followers; the intended
  `(run n (q) (follower q g/d) g)` pattern.

## Later / ideas

- **Verify + polish the related-work survey draft**
  (`claude/2026-07-12-190000-related-synthesis-systems.md`) — machine-
  written with unverified citations; check before citing externally.
  Reading shortlist inside: SMyth, Blaze, Burst, SyRup, Neural-Guided
  CLP.
- **mkcdcl revival (conditional)** — if refutation turns out to need
  learned *reasons* (CDCL lemmas) beyond checks. Known limitations of
  the prototype (Michael): same divergence gap (now addressed by the
  view), prune-only (no propagation — the expensive half to miss),
  disequality provenance blow-up. First-order rep is the natural
  provenance substrate; confining provenance to the follower still
  looks right. Repo: git@github.com:michaelballantyne/mkcdcl.git.
- **Env-plumbing removal** (tagged applications, cheaper lookup) —
  95.7% of suspend cutoffs, a third of guard work; matters whenever
  evalo/d is a heavy view again.
- **Steering characterization** (rember-2 lineage) — answer-quality
  story, partially subsumed by the size guarantee under ID.
- **Asymmetric leader/follower setups** — diagnostic instruments only
  (the product is symmetric by construction).
- Name/document the inf/d return type; rename `case-inf/d`/`stream`.
- Verify set-var-val! is genuinely disabled on the /d path.
- Remove `*unsound-fail-depth*`? Still unused; `*main-unsound-depth*`
  earned its keep today (level-finiteness), this one didn't.
- Racket port — only if Chez friction hurts again.

## Resolved

All 2026-07-12 unless noted; details in the linked entries.

- ~~Size-bounded ID rescues pruning~~ — falsified as posed (follower
  savings *shrank* to 1.5×; memory-infeasible; low bounds
  divergence-dominated), then **resurrected by composition**: ID +
  termination view solves both tasks, 731× vs enumerative baseline on
  append, rember to answer in 86s where baseline died. Verdict:
  `...-174500-size-bounded-id-verdict.md`; capstone:
  `...-181613-id-plus-view-capstone.md`.
- ~~Termination view (rung 1)~~ — built (`base-case-patho/d`), correct,
  regime-dependent: ≈neutral under fair search, transformative under
  ID, 4× follower-memory reduction. `...-184500-termination-view-results.md`.
- ~~What does the search actually explore?~~ — ~98% of size-bounded
  search work is unconditionally divergent candidates at every level;
  fair search never materializes them as complete bodies.
  `...-183000-population-composition.md`.
- ~~Existence proof (FD)~~ — Latin squares: 168× (6×6) → 11,092× work
  / 934× wall (8×8); whole board solved in one install-time firing;
  gap grows combinatorially. `...-173259-latin-square-existence-proof.md`,
  `...-181500-latin-8x8-scaling.md`.
- ~~Fair work metric~~ — unify(main)/conde(main) at the unifier level;
  follower saves ~5–6× under fair interleaving on the old benchmarks.
  `...-162447-fair-work-metric.md`.
- ~~Where does the deep unfolding come from?~~ — 95.7% env plumbing
  (`not-in-envo/d`/`lookupo/d`), not degenerate programs.
  `...-171500-suspend-depth-source-env-plumbing.md`.
- ~~Guanxi/KL recon~~ — propagator fixpoint over DFS; "explore ∝
  posterior mass, renormalize on refutation" reconstruction.
  `...-163000-guanxi-recon-kl-framing.md`. Weighted resumption folded
  into the explicit-search item.
- ~~Do the whole-body baselines terminate?~~ — YES under fair search
  (rember 3.5–6.8s, append 0.22s, canonical answers); April-era
  non-termination belief was stale; ce1 follower arms are what time
  out (>145–1000× wall). `...-184500-termination-view-results.md`.
- ~~Seeded-skeleton experiment~~ — seeded baseline solves in 6.2s
  (true answer), confirming divergence-domination; superseded by the
  view. (Files: `experiments/{rember,append}-seeded.scm`.)
- ~~check-every=1 on full tasks~~ — infeasible in every regime
  (OOM under ID; ~1000× wall under fair search). Root cause → Next.
- ~~Enhance test-check summary~~ — pre-existing (April).
