# Backlog

Roughly-prioritized open questions and experiments. Draw new items from
recent [`claude/`](claude/) notebook entries, `TODO.md`, and the research-goal
framing in [`README.md`](README.md). An item resolves when answered *either
way*; move it to Resolved with a one-line answer + link to the `claude/` entry.

Research goal (from `TODO.md`): determine whether determinacy-directed
propagation can produce **orders-of-magnitude** search savings in *some*
context, ignoring overhead cost. Only if yes do we invest in lowering
overhead and generalizing to harder interpreters. Current evidence:
pruning is real but modest (~4–5× unification reduction in ex3, and it
made the answer *worse*), while propagation demonstrably steers the
search to the intended answer in rember-2. The leading hypothesis
(`claude/2026-04-12-search-order.md`) is that mk's fair interleaving is
what keeps pruning from paying off: refuting a branch never *closes off*
a subspace, it just redistributes scheduler slots size-disordered.

Methodology update (2026-07-12, see
`claude/2026-07-12-161259-search-order-constraint-relaxed.md`):
perturbing the search order (size bounds, iterative deepening, etc.) is
now in scope, under one rule — **every perturbed search order also runs
without pruning as its own baseline**, so the follower's effect is
isolated from the search-order effect. Steering is secondary to
performance gains.

## Now

- [ ] **Size-bounded search × follower — the central hypothesis test.**
  Implement a structural size bound on the query term (option 1 in
  `claude/2026-04-12-search-order.md`: a `max-term-size` goal), and run
  iterative deepening on size over the rember/append benchmarks with
  two arms per size bound: bounded search alone, and bounded search +
  follower — the two-baseline rule from the 2026-07-12 direction note.
  Hypothesis: under a size-closed search each refutation finishes a
  finite subspace, so the follower's pruned fraction converts into real
  work savings — possibly the orders-of-magnitude regime the goal asks
  for. Either outcome is a major resolution: "yes, with the right search
  shape" redirects the project to search strategy; "no, even
  size-bounded" says the ceiling is refutation power itself (see the
  oracle item below).

- [ ] **A fair cross-arm work metric.** `*==-counter*` undercounts (mk
  internals bypass the wrapper) and `==` vs `==/d` aren't comparable.
  Plan: count where both arms share a code path — main-search conde
  expansions, plus unifications ticked inside the unifier itself
  (`unify`/`subst-add` level) rather than at the `==` wrapper —
  and report both, with wall-clock recorded for context (it becomes the
  target metric once the overhead phase starts). Restate the ex2/ex3
  numbers in the new metric. Prerequisite to trusting any headline
  number the item above produces.

- [ ] **Where does the follower's deep unfolding come from?** Suspend-depth
  cutoffs still fire even with the grammar restrictions that were supposed
  to remove unbounded expansions (TODO: "I don't understand where else the
  follower will have the opportunity to unfold unboundedly"). Add
  lightweight tracing (capture goal source syntax at conde/d entry and
  print the stack on cutoff) and identify the unfolding pattern. This
  gates the pruning ceiling: refutations missed for depth reasons look
  identical to refutations that don't exist.

## Next

- [ ] **Weighted resumption (KL framing, rung 2).** If size-bounded ID
  shows pruning converting to real savings, replace round-robin
  interleaving with a priority queue keyed by accumulated cost (−log₂
  of a size prior), so a refuted branch's budget flows to its neighbors
  under the measure ("renormalize on refutation"). If ID results are
  ambiguous, first do the mass-accounting instrument: measure whether
  pruning reduces remaining probability mass faster than scheduler
  slots. See `claude/2026-07-12-163000-guanxi-recon-kl-framing.md`.

- [ ] **Pruning-ceiling oracle experiment.** Run with `check-every=1` and a
  very large suspend depth, ignoring all cost: what fraction of
  main-search branches *can* the follower refute on rember-full /
  append-full? If the unthrottled ceiling is low, no search reordering
  will make pruning big, and the project should pivot to propagation/
  steering as the primary value story.

- [ ] **Turn ex2/ex3 into reproducible experiments.** An `experiments/`
  home with expected qualitative outcomes (and counter snapshots in
  comments), so the findings in `claude/2026-04-12-search-order.md`
  survive future changes and regressions are visible. (TODO item 1.)

- [ ] **Guard-robustness tests.** The soundness argument's load-bearing
  invariant is that `evaluate-guard` reports `'nondet` on any real
  ambiguity. Test the sharp cases: guards that diverge (depth limit as
  sole survivor), guards with multiple answers, guards that extend the
  store then fail on a later conjunct. (TODO item on guard properties.)

- [ ] **Document the /d sharp corners, fix or fence them.** Recursion not
  passing through `conde/d` diverges in follower evaluation even under
  `fresh/d`; end-of-run trigger does not force a suspended follower
  (deliberately — divergence risk). Write the "follower guarantees"
  note covering the intended `(run n (q) (follower q g/d) g)` pattern.

## Later / ideas

- Characterize the steering effect (rember-2 finds `(rember e d)` where
  baseline finds a nested-match trick): smallest hole exhibiting it,
  robustness across `check-every`, whether knobs turn rember-full
  timeouts into steered successes. Demoted 2026-07-12: steering is
  secondary to performance gains, but the answer-quality story is worth
  having once the performance question is settled.
- First-order representation of the /d search — better debuggability
  (printable trees), avoids rebuilding closure structure per trigger,
  and enables saving guard progress across triggers. Revisit after the
  Now items say whether the mechanism is worth optimizing.
- Tag applications / remove `not-in-envo` to make guard evaluation
  cheaper in the restricted language.
- Related-work positioning note: dKanren, Lozov's work, mkcdcl,
  backjumping-miniKanren, underconstraints, Andorra — framed against
  this project's narrower, more measurable goal.
- Name and document the inf/d return type (it is not a stream — never
  splits into multiple answers); rename `case-inf/d` and the `stream`
  variable names to match.
- Separate interpreter and typechecker for the same language as
  leader/follower — which should lead?
- Remove `*unsound-fail-depth*`? Unused in practice; keep as a cheap
  diagnostic at least until tracing/first-order tools replace it.
- Verify and document that `set-var-val!` is genuinely disabled on the
  /d path (the fixpoint note's change detection depends on it); the
  larger "remove it from base faster-mk" question belongs upstream.
- Racket port (timeouts, arg parsing, match, saner macro layer) — only
  if Chez friction keeps hurting; it's a big perturbation.

## Resolved

- ~~Enhance test-check to summarize at end of test-all.scm~~ — already
  done; `test-all.scm` prints a final tally ("All 34 tests passed").
