# Guard robustness pinned; the sole-survivor rule is more general than documented

`tests/guard-robustness.scm` (8 tests, suite now 42) pins the
soundness-critical guard-classification behavior. Seven cases behave
exactly as the design notes say: diverging sole-survivor guards commit
with the hard-suspension carried forward; any *cross-clause* ambiguity
stalls with zero store leakage; self-contradicting guards rule their
clause out cleanly; a unique singleton guard's extensions flow out;
stalled followers commit on retrigger once the main search grounds the
discriminator.

## The surprise, and the judgment: sound, and a better rule

Test 3: a conde/d whose *sole* clause has a genuinely multi-answer
nested guard **commits** rather than stalling. Mechanism:
`(nondeterministic)` returns `(cons entry-state retry-thunk)`, which is
structurally a soft-suspend, and `conde/d-runtime` classifies guard
streams only as failed/truthy — so with no sibling to collide with,
the clause commits, the body runs on the entry state, and the
ambiguous guard becomes a retained worklist obligation.

This contradicts the documented rule ("multi-answer → 'nondet →
stall") but is **sound**, by the following argument:

1. **Clause-taken-ness is forced.** Guard failure is monotone in the
   store (a positive relational goal with no solution over st has none
   over any extension of st), so refuted siblings stay refuted: any
   solution through this conde/d takes the surviving clause. For a
   literal sole clause it's immediate — a one-clause conde/d *is* a
   conjunction.
2. **No inner-branch extension leaks.** The nondet guard hands back
   the *entry* state; neither ambiguous branch's extensions flow.
   What flows is only the body's extensions — justified by
   clause-taken-ness alone.
3. **The obligation is retained.** The guard's retry thunk stays in
   the worklist/follower; if the guard is later refuted outright, the
   follower fails the branch and everything committed on it dies with
   it. Early commitment on a branch that later fails is not
   unsoundness; unsoundness would be dropping the obligation or
   committing a *particular* inner branch's extensions — neither
   happens.

So the implementation's actual principle, cleaner than the documented
one: **commit when clause-taken-ness is forced; a surviving guard's
own residual ambiguity (whether from depth cutoff or genuine
nondeterminism) becomes a retained obligation whose extensions do not
flow.** The documented "hard-suspended sole-survivor commits" rule is
the special case where the residual is a depth cutoff.

Left as-is deliberately (the behavior is desirable); this entry is the
documentation. The design note's classification table
(`claude/2026-04-11-200000-design.md`) should be read with this
generalization in mind.
