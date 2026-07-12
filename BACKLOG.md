# Backlog

Roughly-prioritized open questions and experiments. Draw new items from
recent [`claude/`](claude/) notebook entries, `TODO.md`, and the research-goal
framing in [`README.md`](README.md). An item resolves when answered *either
way*; move it to Resolved with a one-line answer + link to the `claude/` entry.

Research goal (from `TODO.md`): determine whether determinacy-directed
propagation can produce **orders-of-magnitude** search savings in *some*
context, ignoring overhead cost. Only if yes do we invest in lowering
overhead and generalizing to harder interpreters.

Methodology (2026-07-12, see
`claude/2026-07-12-161259-search-order-constraint-relaxed.md`):
perturbing the search order (size bounds, iterative deepening, etc.) is
in scope, under one rule — **every perturbed search order also runs
without pruning as its own baseline**, so the follower's effect is
isolated from the search-order effect. Steering is secondary to
performance gains. Fair work metric: `unify (main)` / `conde (main)`
(see `claude/2026-07-12-162447-fair-work-metric.md`).

## Now

- [~] **Size-bounded search × follower — the central hypothesis test.**
  Machinery done (`*max-term-size*`, `watch-size`, `experiments/`
  ID harness + per-arm files). Runs in progress. Early signal is
  *against* the hypothesis: under size-closed search the follower's
  savings shrink (rember-2: 1.9× vs 5–6× under fair interleaving;
  append bound-11 with deep suspend depth: 1.5×), plausibly because
  the size bound itself already kills what the follower was killing.
  Remaining: complete the moderate-config follower arms
  (check-every=20), get append's total-work-to-answer comparison,
  write the verdict entry.

- [ ] **Why does follower state retain gigabytes?** Both check-every=1
  arms and both suspend-depth=200 arms OOM'd (8–10.6GB) on full-task
  ID levels, while ce=20/sd=20 configs run in tens of MB. Hypothesis:
  every live state in the (breadth-heavy) size-bounded frontier
  carries an F cell holding deep resume-closure chains; memory scales
  as live-states × suspend-depth. Confirm by instrumentation or
  analysis; this both blocks oracle-style experiments and is more
  evidence for the first-order representation. Interim oracle route:
  moderate suspend-depth steps (40, 60, 100) to find the memory-
  feasible ceiling.

- [ ] **Benchmark portfolio.** Current tasks (rember/append whole-body
  holes) are n=2 correlated instances of one schema, with
  leader/follower information symmetry and a grammar pre-sanitized of
  irrefutable junk — all of which cap what the follower can show
  (discussion with Michael 2026-07-12). Add:
  (a) an **existence-proof benchmark** where unit propagation is known
  to dominate — a finite-domain puzzle (zebra-style) in /d encoding;
  separates "mechanism can't win big" from "these benchmarks can't
  show it";
  (b) an **asymmetry-controlled family** — same task, varying which
  examples the follower holds vs the leader (systematizing the ex2 /
  rember-2 regime that produced the only clear wins). Note (Michael,
  2026-07-12): the product vision is *symmetric by construction* —
  leader and follower generated from one source, the user writes plain
  miniKanren and gets unit propagation under the hood. Asymmetric
  setups are diagnostic instruments for locating where the value comes
  from, not a direction.

## Next

- [ ] **Pruning-ceiling oracle, memory-feasible version.** What fraction
  of main-search branches *can* the follower refute when depth-unstarved?
  Blocked on the memory question above; approach via moderate
  suspend-depth steps rather than check-every=1 + huge depth (both
  OOM). If the ceiling is low even unthrottled, no search reordering
  will make pruning big → pivot to propagation/steering and asymmetric
  setups as the value story.

- [ ] **Remove `not-in-envo/d` via tagged applications.** Was a Later
  item; promoted by the depth-tally finding
  (`claude/2026-07-12-171500-suspend-depth-source-env-plumbing.md`):
  env plumbing is 95.7% of suspend cutoffs and `not-in-envo/d` alone
  is 37% of cutoffs + 134k entries. Removing it both cheapens guards
  massively and frees depth budget for actual refutation. The single
  highest-leverage implementation change identified so far.

- [ ] **Weighted resumption (KL framing, rung 2).** If size-bounded ID
  had shown pruning converting to real savings, replace round-robin
  interleaving with a priority queue keyed by accumulated cost (−log₂
  of a size prior) — "renormalize on refutation". Early ID results make
  this less likely to pay off for *pruning*; it may still matter as a
  search-order story independent of the follower. The mass-accounting
  instrument (does pruning reduce remaining probability mass faster
  than scheduler slots?) is the cheap first step.
  See `claude/2026-07-12-163000-guanxi-recon-kl-framing.md`.

- [ ] **Turn ex2/ex3 into reproducible experiments** under
  `experiments/`, with expected qualitative outcomes in comments.
  (TODO item 1; partially superseded by the ID experiment files, which
  now cover the same tasks in bounded form.)

- [ ] **Guard-robustness tests.** The soundness argument's load-bearing
  invariant is that guard evaluation reports `'nondet` on any real
  ambiguity. Test the sharp cases: guards that diverge (depth limit as
  sole survivor), guards with multiple answers, guards that extend the
  store then fail on a later conjunct.

- [ ] **Document the /d sharp corners, fix or fence them.** Recursion
  not passing through `conde/d` diverges in follower evaluation even
  under `fresh/d`; end-of-run trigger does not force a suspended
  follower (deliberately — divergence risk). Write the "follower
  guarantees" note covering the intended
  `(run n (q) (follower q g/d) g)` pattern.

## Later / ideas

- Characterize the steering effect (rember-2 finds `(rember e d)` where
  baseline finds a nested-match trick): smallest hole, robustness
  across `check-every`, does it appear on full tasks with knobs.
  Steering is secondary, but if the pruning story ends negative, this
  plus the asymmetry family becomes the mechanism's main demonstrated
  value.
- First-order representation of the /d search — debuggability,
  avoids rebuilding closures per trigger, and now also the leading fix
  candidate for the gigabyte-retention problem.
- Related-work positioning note: dKanren, Lozov's work, mkcdcl,
  backjumping-miniKanren, underconstraints, Andorra, guanxi.
- Name and document the inf/d return type (not a stream — never splits);
  rename `case-inf/d` and `stream` variable names to match.
- Separate interpreter and typechecker for the same language as
  leader/follower — which should lead? (A natural member of the
  asymmetry family above.)
- Remove `*unsound-fail-depth*`? Unused; keep as diagnostic until the
  tracing/first-order tools replace it.
- Verify and document that `set-var-val!` is genuinely disabled on the
  /d path (fixpoint-note change detection depends on it).
- Racket port — only if Chez friction keeps hurting.

## Resolved

- ~~A fair cross-arm work metric~~ — done 2026-07-12: unifier-level
  counters split main/follower + conde-entry counters; follower saves
  ~5–6× main work under fair interleaving.
  `claude/2026-07-12-162447-fair-work-metric.md`.
- ~~Where does the follower's deep unfolding come from?~~ — resolved
  2026-07-12: 95.7% of suspend cutoffs are env plumbing
  (`not-in-envo/d` + `lookupo/d` linear scans under one shared depth
  budget), not degenerate program expansion.
  `claude/2026-07-12-171500-suspend-depth-source-env-plumbing.md`.
- ~~Guanxi / KL-divergence recon~~ — done 2026-07-12: propagator
  fixpoint over plain DFS; KL remark reconstructed as
  "explore proportional to posterior mass, renormalize on refutation."
  `claude/2026-07-12-163000-guanxi-recon-kl-framing.md`.
- ~~check-every=1 follower arms on full ID tasks~~ — infeasible, OOM
  at ~8GB with zero levels completed (2026-07-12); throttling is
  mandatory. Folded into the memory-retention item above.
- ~~Enhance test-check to summarize at end of test-all.scm~~ — already
  done; `test-all.scm` prints a final tally.
