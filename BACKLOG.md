# Backlog

Roughly-prioritized open questions and experiments. Draw new items from
recent [`claude/`](claude/) notebook entries and the research-goal
framing in [`README.md`](README.md). An item resolves when answered *either
way*; move it to Resolved with a one-line answer + link to the `claude/` entry.
Current priority order is set by the reflection
`claude/2026-07-12-220000-reflection-after-factoring-and-wave1.md`.

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
Regime call (Michael, 2026-07-12 evening): stay in
ignore-overhead-and-exhaust-search-space-reductions mode for a good
while yet — the mainline loop is: sample the surviving stream, find a
doomed family, build the cheap refuter/view, measure the reduction,
repeat. Pure-Andorra firing (ce1) is the default in the enumerative
regime. Refinement (Michael): overhead IS in scope when it is
measurement-blocking — an arm that OOMs or times out before producing
its numbers (as every pre-view follower-ID config did) leaves the
pruning question unanswered, and fixing that is reductions work, not
optimization. Mere-inefficiency overhead stays out of scope.

**Session directive** (Michael, 2026-07-12, this session): explore
(1) factoring the typechecker out of the interpreter, (2) additional
information sources as new views, (3) whether unit propagation needs
strengthening (CDCL). And: **expand the synthesis benchmark suite
before diving into anything complex beyond the untyped-interpreter
work**. All four explored same session; symbolic examples got folded
into the wave-2 Now item, the other survey ideas (abstract-domain
views, coverage) wait in Next.

**Session handoff (2026-07-13):** Tasks 1 and 2 RESOLVED earlier this
session. Task 1: R2P works (interleave feasible), R2T diverges
(structural negative), per-task measure selected
(`...-040000-r2p-r2t-termination-generalization.md`). Task 2: wave-2
measured (`...-042500-wave2-bidirectional-results.md`).

**CORRECTION (2026-07-13, item 2b, `...-041637-property-specs-are-anchor-carried.md`):**
the wave-2 headline "property specs (rev-involution) are the flagship /
strongly-pinning" was **confounded** and is now retracted. A controlled
experiment (property-only / anchor-only / property+anchor for append,
rember, rev) shows: on every task, a SINGLE ground anchor pins the answer
at least as well as the relational property and 5–64× cheaper in follower
work; rev-anchor-only alone synthesizes canonical rev-acc that wave-2 had
credited to the involution property. Relational property = pure follower
overhead when a pinning ground example exists (all three tasks). Live
next items reset by the reflection
`...-041925-reflection-bidirectionality-is-expressiveness-not-efficiency.md`:
**3 (first-order rep — where the measured wins live)**, then 1b (unified
termination view). Bidirectionality is now understood as an *expressiveness*
win (write once, run all directions, no inverse semantics), NOT a
search-efficiency win — so the property-spec-as-efficiency line is closed
and identity #1's defense is an expressiveness write-up (Later), decoupled
from search-cost claims.

## Now

(re-ordered by the 2026-07-13 reflection: search strategy over spec shape)

- [x] **1. Generalize the termination view beyond fixed-position
  decrease** — RESOLVED. R2P (`permuted-decreasing-recursiono/d`,
  injective-assignment multiset measure) admits interleave's
  argument-swap and makes it feasible (108,475 @ 35 vs infeasible);
  R2P is INCOMPARABLE to R2 (rev-acc's growing accumulator is
  R2P-refuted/R2-accepted). The uniform combined view R2T = R2∨R2P
  DIVERGES as a follower (structural: an OR of independently-suspending
  whole-body /d checks can't deepen a single suspend-depth frontier) —
  recorded negative, `...-040000-r2p-r2t-termination-generalization.md`.
  Decision: per-task measure (R2 default, R2P for permuting recursion).

- [ ] **1b. (spawned) Unified single-frontier termination view** — the
  principled fix for R2T's divergence: one walk branching only at the
  per-self-call measure test (fixed-position vs permuted), single
  committed state → one suspension frontier to deepen. May re-hit the
  single-state tension; needs a design pass. Also its sibling lead:
  reorder conj/d-run's resume worklist so cheap refuters run before
  evalo/d (touches the engine; connects to view-scheduling / the
  CDCL-note stall-ordering theme) — measure whether that alone
  rescues R2T.

- [x] **2. Benchmark wave 2: bidirectionality-essential tasks** —
  first pass DONE (`...-042500-wave2-bidirectional-results.md`).
  Key finding: weaker examples (symbolic W2a, partial-output W2b) admit
  MORE degenerates, not fewer — minimality-first ID returned smaller
  wrong programs for both, the evens lesson recurring. Wave-2 named
  property specs the "flagship," **but 2b later RETRACTED that** —
  rev-involution was carried by its ground anchor, not the involution
  property (see 2b and the 2026-07-13 reflection). What survives from
  wave-2: the weaker-examples-admit-more-degenerates finding; tally/d
  earning its keep; untyped+TY confirmed as default (wave-1 ports all
  within ±3% of typed). Prerequisites (a) ports, (e) tally all done.

- [x] **2b. Property/relational spec suite** — RESOLVED, negatively and
  importantly (`...-041637-property-specs-are-anchor-carried.md`).
  Built as a controlled experiment (property-only / anchor-only /
  property+anchor) for append-associativity, rember-idempotence, and a
  decisive rev-anchor-only comparator. Finding: a single ground anchor
  pins the answer at least as well as the relational property on all
  three tasks and 5–64× cheaper; property-only always returns the
  smallest degenerate (append `s`, rember `l`); the property changes
  nothing about which program is found and adds only entangled-eval
  follower cost. **Retracts the wave-2 flagship claim** (rev-involution
  was anchor-carried). Consequence: bidirectionality is expressiveness,
  not efficiency (reflection
  `...-041925-reflection-bidirectionality-is-expressiveness-not-efficiency.md`);
  the property-spec-as-efficiency line is closed, priority moves to item 3.

- [ ] **2c. Methodology note (cheap, now lower priority):** single ground
  anchors UNDER-pin (rember head-wrap degenerate from
  `(rember 5 (6 5))=(6)`); a spec needs one example per structural case
  (this is why the wave-1 concrete rember used 4). Fold into the sharp-
  corners doc rather than chasing separately. Still open from the wave-2
  plan: rung-4b relevance ablation vs the untyped stack.

- [ ] **3. First-order representation of the /d search, steps 1–2,
  then the explicit scheduler on top. NOW THE TOP PRIORITY** (2026-07-13
  reflection: search strategy over spec shape). Design note:
  `claude/2026-07-12-200500-first-order-rep-design.md`. **Step-1
  implementation map ready** (registry + per-site constructors, file:line
  anchors, byte-identical-counter regression via tv2/tv3):
  `claude/2026-07-13-042503-first-order-rep-step1-implementation-map.md` —
  start there. Green-lit by
  Michael on conceptual-clarity grounds; memory-sharing half is
  measurement-enabling; speed half stays deprioritized; step 2's
  printable follower trees also upgrade the sampling loop. The
  scheduler that follows (size/cost-frontier priority queue with
  views as the pruning/forcing layer) recovers mk's implicit
  heuristics explicitly: geometric demotion of deep spines → the
  termination view; ordering luck → the size guarantee; completeness
  via fairness → levels complete by construction. Neither project
  identity constrains the scheduler; protect the relational substrate
  the views compose in, not the interleaving.

## Next

- [ ] **Length-domain abstract view** (survey #2): eval-lengtho/d
  over auto-abstracted examples; dense-forcing hypothesis on
  element-blind tasks (duplicate/append/evens/interleave); the
  join-tension (rember stalls at element tests) is the thing to
  measure. Parked behind broadening.

- [ ] **Coverage/adequacy view via trace reification** (survey #3):
  class-B cut of unexercised-branch junk that NOTHING in the current
  stack can see; also the architectural probe of store-mediated
  view-to-view communication. Rises in priority once branchier tasks
  (last, swap-pairs) are measured.

- [ ] **Fix the productivity tally.** Constraint-only commits
  (symbolo/=/= etc.) are invisible to the walk*-based check — B2-ce1
  scored 221k/221k triggers "unproductive" while doubling main-search
  work. Diff the constraint store too. Until then, don't trust
  "trigger productive" as the propagation signal. Related open
  question (from old TODO): when the follower forces/fails, does the
  leader actually avoid the equivalent work, or does the store-level
  communication under-cut goal-level exploration? Worth a targeted
  measurement once the tally is trustworthy.

- [ ] **Broaden the synthesis benchmark suite** (endorsed by Michael
  2026-07-12; `duplicate` in progress as the third task). Within the
  current language, target answer-shape diversity: `duplicate`
  (double-cons, no if, 1 param), a member/contains-like task (if-heavy,
  number result... needs boolean encoding — check expressibility),
  swap-pairs (nested match), tasks with 2 recursive calls in the body.
  Then the differentiating class: tasks where *bidirectionality is
  essential* (run backward/partial-output specs, relation synthesis,
  Barliman-style) where enumerate-and-test has no natural entry — the
  right ground to defend the relational substrate against the
  Burst/Trio comparison. Watch per-task: which view refutes/forces,
  whether depth-cut stays 0 (a nonzero = a new divergent family the
  ladder misses), and views-arm vs baseline ratios. Standing practice
  (Michael): sample each task's surviving explored stream and
  spot-check for obviously-non-viable families — this loop found the
  divergence domination, the OR-neutralization, and the rung-4
  families; it is the engine of the ignore-overhead regime.

- [ ] **Map the FD win regime further** (cheap): Sudoku-style
  benchmark, instances needing more guessing, and where the
  crossover to baseline-wins sits as propagation-solvability decreases.

- [ ] **Guard-robustness tests** (unchanged): diverging guards,
  multi-answer guards, store-extending guards that fail later — the
  'nondet-on-real-ambiguity invariant is load-bearing for soundness.

- [ ] **Document the /d sharp corners + follower guarantees note**
  (unchanged): recursion not through conde/d diverges under fresh/d;
  end-of-run trigger doesn't force suspended followers; the intended
  `(run n (q) (follower q g/d) g)` pattern. Fold in from old TODO:
  document the conj/d-disj/d implementation and its refutation
  capabilities, and the hard-suspend-at-depth vs resumable-suspend
  convergence argument (refining resumptions don't refresh the depth
  budget; only the top-level resume of a hard suspend does).

## Later / ideas

- **Verify + polish the related-work survey draft**
  (`claude/2026-07-12-190000-related-synthesis-systems.md`) — machine-
  written with unverified citations; check before citing externally.
  Reading shortlist inside: SMyth, Blaze, Burst, SyRup, Neural-Guided
  CLP.
- **mkcdcl revival (conditional)** — evaluated 2026-07-12
  (`claude/2026-07-12-211500-cdcl-evaluation.md`): verdict *not now,
  and mostly not CDCL* — ID re-refutation is capped at ~2.7× and owned
  by explicit search; hand-written views saturated the shared-reason
  families on the current suite and transfer across tasks; stall-time
  lookahead predicted low-yield outside FD. Sharpened triggers to
  revisit: (1) broadened benchmarks keep producing task-specific
  refutation families (measure: refuted-candidate logging hook +
  syntactic clustering), or (2) the explicit scheduler's profile shows
  heavy same-reason refutation across non-prefix-shared contexts.
  Known prototype limitations (Michael): divergence gap (now addressed
  by the view), prune-only, disequality provenance blow-up. First-order
  rep is the provenance substrate either way (third motivation).
  Repo: git@github.com:michaelballantyne/mkcdcl.git.
- **Env-plumbing removal** (tagged applications, cheaper lookup) —
  95.7% of suspend cutoffs, a third of guard work; matters whenever
  evalo/d is a heavy view again.
- **Steering characterization** (rember-2 lineage) — answer-quality
  story, partially subsumed by the size guarantee under ID.
- **Asymmetric leader/follower setups** — diagnostic instruments only
  (the product is symmetric by construction).
- **Relational-substrate related-work note** (from old TODO; the
  synthesis-systems survey covers the PBE world but not the mk
  lineage): dKanren (Rosenblatt), Lozov's relational conversion
  papers, backjumping-miniKanren, underconstraints, the condg lineage
  from staged-mk (and whether the latest staged-mk approach removes
  the /d syntactic overhead), Andorra/EAM contrast — plus worked
  examples of *limitations*: things CDCL or Lozov's machinery
  terminates on that following-mk does not (fair conjunction vs
  complete unit propagation).
- Name/document the inf/d return type; rename `case-inf/d`/`stream`.
- Verify set-var-val! is genuinely disabled on the /d path (and the
  old-TODO question of removing it entirely — Will thinks it has
  negative ecosystem value; maybe upstream-first).
- Remove `*unsound-fail-depth*`? Still unused. And with rungs 1+2,
  `*main-unsound-depth*` never fires on the benchmark suite either
  (depth-cut 0) — both unsound knobs are now candidates for demotion
  to pure diagnostics or removal.
- **Profit regime for bidirectionality (demoted from 2d).** 2b closed the
  efficiency case for property specs on functions with cheap forward
  examples. The reflection
  (`...-041925-...expressiveness-not-efficiency.md`) found the surviving
  candidates all need an object-language change or are out of scope:
  (i) nondeterministic relations where a functional example over-commits
  (insert-anywhere, permutation, sort) — but the object language is
  deterministic-functional and lacks `<`/arithmetic; (ii) oracle-free PBE
  (no ground truth to score). Michael's Peano-length
  `length(append(a,b))=append(length(a),length(b))` (length → unary list,
  `+`=append at object level) is expressible but multi-function and STILL
  has cheap ground examples per component, so it's not in the regime either.
  Revisit only if the object language grows nondeterminism or a real
  no-oracle task appears. Identity #1's proper defense is an expressiveness
  write-up (author effort / inverse-code avoided), not a search-cost arm.
- Racket port — only if Chez friction hurts again.

## Resolved

All 2026-07-12 unless noted; details in the linked entries.

- ~~Rung 4a: non-vacuous conditions view~~ — built, 1.61× further on
  rember; with 4b/4c negatives it closed the canonicity family (the
  reduction loop converged on rember). The remaining rung-4 half
  (dataflow relevance) moved into the wave-2 item, to be evaluated
  against the untyped stack. `...-203000-rung4a-vacuous-conditions.md`.

- ~~Benchmark broadening wave 1 (build + first measurements)~~ — six
  tasks added (member?, last, swap-pairs, evens, rev-acc, interleave);
  the unchanged five-view stack solves 5/6 in 4–38s, all six
  enumerative baselines timeout (matched-level ratios 175×–2,380×);
  machine beat the human canonical on swap (63 vs 74) and evens (55
  vs 69); evens spec bug caught by minimality; last reified its
  spec-dead branch as a hole; interleave exposed R2 as load-bearing
  for feasibility (→ new Now item).
  `...-214500-benchmark-wave1-results.md`.

- ~~Is TY worth keeping / untyped-interpreter factoring~~ — YES, and
  the factoring is free: untyped generator + type-ofo/d matches
  typed-full within ~2% on all three tasks; TY flips from
  fully-overlapped to 8.3× on rember (task-specific: 1.18× append,
  ~1.07× duplicate); no ill-typed answer ever surfaces (TY is
  efficiency, not correctness, on this suite). Checking-time types ≈
  generation-time types. Rungs 4b (occurso, negative vs typed stack)
  and 4c (branch vacuity, zero cut) closed earlier same day.
  `...-212000-untyped-factoring-results.md`.

- ~~Do we need CDCL / stronger-than-unit propagation?~~ — Not now, and
  mostly not CDCL: ID re-refutation capped at 2.74× (per-level
  measurement) and owned by explicit search; views are hand-learned
  position-generic lemmas that saturated the current suite and
  transfer across tasks; stall-time lookahead predicted low-yield
  outside FD. Falsifiable revisit-triggers recorded.
  `...-211500-cdcl-evaluation.md`.

- ~~Why is check-every=1 catastrophic?~~ — it isn't, except under fair
  search: chain-growth falsified (worklists bounded at 3–4, flat
  per-trigger cost); the blowup decomposes into ~20–30× linear firing
  cost × fair-search trajectory perturbation. Under ID, ce1 *solves
  faster and with less main work* than ce20. Pure-Andorra is right in
  the enumerative regime; the per-fire rebuild constant is now the
  whole overhead story (→ first-order rep).
  `...-195900-ce1-catastrophe-resolved.md`.

- ~~Typechecker as the third view (rung 3)~~ — built (`type-ofo/d`),
  gates pass; −7.5% unify on top of rungs 1+2, and the project's
  first *propagation* signal (type-forcing of holes; examples can't
  force, many-to-one). Marginal returns decreasing — next lever is
  explicit search, not a fourth view. Includes the counter-
  contamination incident + fix (`without-unify-counting`).
  `...-194500-rung3-types-and-counter-contamination.md`.

- ~~Rung 2: structurally-decreasing recursion~~ — built
  (`decreasing-recursiono/d`, fixed-position via conde/d over
  positions); rember ID 57.6M → 2.62M unify (22×, 69× wall);
  depth-cut 0 everywhere; **size-guaranteed search now cheaper than
  fair search on both tasks** (2.62M vs 3.2M; 248k vs 443k). Fair-
  search probe: refutes there too (5,629) but flat work — refutation
  converts only where candidates are paid in full.
  `...-193500-rung2-decreasing-recursion.md`.
- ~~Guard-robustness tests~~ — 8 tests added (suite 42); invariants
  hold; one sound generalization found and documented (sole-survivor
  commit with retained nondet-guard obligation).
  `...-192500-guard-robustness-sole-survivor-rule.md`.
- ~~Fair-search population w/ view (Michael's sampling round 2)~~ —
  rung 1 OR-neutralized by the committed clean base case; work
  concentrates in the e2 slot; rung-2 prediction made and confirmed.
  `...-190500-fair-population-view-neutralized.md`.

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
