# Rung 4c (branch vacuity): correct, zero marginal cut — the loop has converged on rember

`non-vacuous-brancheso/d` (`experiments/termination-view6.scm`):
refutes `(if (= c1 c2) t e)` where branches are textually identical
or {t,e} = {c1,c2} (no-op conditionals). All gates pass; canonical
answer accepted; holes stall. Measured against the full stack
(tv4ex): conde(main) IDENTICAL (7,899), unify(main) +1.6% (pure
walk overhead). Zero candidates cut.

Resolution of the "examples can't kill this family" argument: they
can't kill the *completed* correct-but-non-minimal wrappers — but
those live at sizes above the minimal answer, which size-closed ID
never reaches; and the partial vacuous-shaped candidates at bounds
35–43 die to examples for reasons in their surrounding structure.
The family was real in the post-4a-pre-EX stream and is empty in the
post-EX stream.

Second consecutive recorded negative (after 4b), same hardened rule:
residue estimates against any thinner stack do not transfer; only
marginal-against-installed-stack (the ablation protocol) measures a
view's value. Both cycles cost under an hour each — build-cheap-and-
ablate is working as intended.

The larger conclusion: **the sample→diagnose→refute loop has
converged on this benchmark.** rember work-to-answer stands at
312,236 unify(main) (tv4ex), and two independent principled new-view
attempts found nothing left to cut. Further reduction needs new
INFORMATION — richer specs (the missing same-l/different-e examples),
the untyped-interpreter factoring (where TY and relevance should
matter), harder/broader benchmarks — not more canonicity syntax over
this stream. Exactly where the backlog's Now section points next.
