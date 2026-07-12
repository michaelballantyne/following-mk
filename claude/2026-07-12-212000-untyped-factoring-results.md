# Untyped-interpreter factoring: check-time types ≈ generation-time types, and TY flips to load-bearing

The TY-overlap diagnosis (backlog Now (a); rung-3/ablation finding that
LOO-TY ≈ full everywhere) made a testable claim: the type view pays in
proportion to how untyped the generator is, because the typed
interpreter spends type information at generation time. Built and
measured this session (implementation delegated; wiring, suite, and the
two headline numbers re-verified by hand in the main loop).

## What was built

- `restricted-interp-untyped.scm` (`evalo-u` …) and
  `restricted-interp-untyped-following.scm` (`evalo-u/d` …): the
  interpreter with the `type` argument removed everywhere. Honest
  dynamically-typed semantics: `cons` total, `=` requires both operands
  to evaluate to numbers (else stuck = relational failure), `match`
  requires a pair/'() scrutinee, env entries `(val . v)`/`(rec . lam)`,
  letrec template `(lambda (args) body)` — no annotation. Arity stays
  structural (it never was typing). E/I discipline kept; note literals
  are I-forms, so dynamic-stuckness only manifests on E-forms
  (variables/applications) evaluating to wrong-shaped values.
- Six arms: `{rember,append,duplicate}-untyped-id-{noty,ty}.scm` —
  tv4ex protocol exactly, untyped generator + untyped follower
  examples; the `ty` arms add `type-ofo/d` under a per-task tyenv.
  Types now live ONLY in the view.
- `tests/untyped-interp.scm` wired into `test-all.scm`; suite 42 → 79,
  all green.

## Results (ce1, main-unsound-depth 1000, 240s cap; typed-full rember
baseline re-reproduced at exactly 312,236 first)

| arm | unify(main) | conde(main) | answer | wall | unify(f) |
|---|---:|---:|---|---:|---:|
| rember typed-full | 312,236 | 7,899 | canonical @47 | 12.3s | 14.19M |
| rember untyped-noty | 2,552,810 | 50,144 | canonical @47 | 87.8s | 86.98M |
| rember untyped-ty | **305,891** | 8,024 | canonical @47 | 13.0s | 14.22M |
| append typed-full | 138,493 | 3,272 | canonical @35 | 4.1s | — |
| append untyped-noty | 160,810 | 3,826 | canonical @35 | 5.8s | 8.79M |
| append untyped-ty | 136,817 | 3,324 | canonical @35 | 5.5s | 8.48M |
| duplicate typed-full | 53,812 | 1,753 | canonical @39 | 0.8s | — |
| duplicate untyped-noty | 55,836 | 1,886 | canonical @39 | 0.8s | 1.34M |
| duplicate untyped-ty | 52,315 | 1,766 | canonical @39 | 1.1s | 1.35M |

(rember untyped-ty re-verified by hand: 305,891, canonical answer.
depth-cut 0 in every arm. Contamination fingerprint absent — conde and
unify move together on the noty blowup.)

## Findings

1. **Factoring is free.** untyped+TY ≈ typed-full within ~2% on all
   three tasks (some cells slightly below). Checking-time type
   information in a composed view is a near-perfect substitute for
   generation-time type information baked into the interpreter — the
   whole 8.2× noty penalty on rember is recovered by the view.
   Identity #2 applied to the interpreter itself, confirmed with
   attributable numbers.
2. **TY flips exactly as diagnosed, and the flip is task-specific.**
   Marginal value of TY against the untyped stack: rember **8.3×**
   (2.55M → 306k), append 1.18×, duplicate ~1.07×. rember is where
   ill-typed junk proliferates (the `(if (= _ _) …)` operand slots
   admit arbitrary E-forms the examples rarely execute); append and
   duplicate have almost no type-refutable junk that structure +
   examples don't already kill. The diagnosis "a type view pays in
   proportion to how untyped the generator is" now reads: …and in
   proportion to how much dynamically-dead ill-typed structure the
   task's grammar slots admit.
3. **TY is efficiency, not correctness, on this suite.** The predicted
   smaller-bound ill-typed answer never appeared: every noty arm found
   the canonical body at the canonical bound. Examples + R1/R2/NV
   already pin the answer; types only prune the road there.
4. **Where TY acts: before evaluation.** On rember it cuts follower
   work 6.1× (87.0M → 14.2M unify(f)) — syntactic refutation ahead of
   `evalo-u/d` executing the junk. (No per-view forcing counter exists
   yet; unify(f) is the proxy. A per-view attribution counter is a
   small instrumentation item if we want the forcing story precise.)

## Consequence: make untyped+TY the default architecture

Same cost, strictly better factoring: the interpreter becomes
type-free (simpler, reusable across differently-typed tasks, closer to
the write-once story), and the type discipline is a composable,
swappable view with measurable marginal value. Follow-ups now
unblocked/meaningful:

- Re-run the rung-4b relevance ablation against the *untyped* stack
  (the negative was recorded against the typed one and explicitly kept
  alive for this scenario).
- The benchmark-broadening wave-1 tasks were built on the typed
  template this session; port or dual-run them under untyped+TY when
  measuring, so the new suite speaks to the factored architecture.
