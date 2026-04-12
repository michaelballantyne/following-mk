- Document the research goal: explore how much pruning we can get, ignoring the overhead cost. Work in a context where it's easy to compare to baseline faster-miniKanren. Avoid perturbing the search order other than by failure and by propagation of determined information. Simplify the interpreters we're working with as necessary to avoid degenerate cases and see if there exists a scenario where propagation gets us big wins. Determine whether the search strategy needs to be different for this to be the case---I have hypothesized that pruning with the standard mK search often doesn't actually let us spend less time on fruitless branches because we can often never close things off entirely. If we can show that following-mk's propagation can get us orders-of-magnitude search savings in some context, *then* we can figure out how to lower the overhead and generalize to harder interpreters.

- Document the relationship to closely related work like dKanren (https://github.com/gregr/dKanren/tree/master), Petr Lozov's work (https://minikanren.org/workshop/2020/minikanren-2020-paper1.pdf and https://dl.acm.org/doi/10.1145/3441296.3441397), mkcdcl (https://github.com/michaelballantyne/mkcdcl), backjumping (https://github.com/michaelballantyne/backjumping-miniKanren), my also "dKanren" (https://github.com/michaelballantyne/backjumping-miniKanren). Also underconstraints, Andora. Contrast the fair conjunction problem generally with the more limited goal of complete unit propagation (Which is the Andora principle?). Frame this WRT the research goal above---these other systems tackled more general problems, but that also made them harder to evaluate and predict.

- Note the conde/d lineage from condg in earlier staged-miniKanren work, and explore whether we can use something more like the latest staged-miniKanren approach to remove the syntactic overhead.

- Split out tests for the /d language vs tests for evalo/d's refutation behavior with finite sets of expression options vs tests where a following evaluator refutes examples proposed by a leading interpreter.

- Related to the previous, turn the recent experiments (ex.scm, ex2.scm, ex3.scm) into tests or reproducible experiment files that explain things we've learned and let us see when other changes invalidate this knowledge.
    - With the mK search we interleave explorations of terms of very different size---ex. after testing a term of size 31, we go back to a term of size 3.
    - With search driven by the interpreter we are (somewhat) exploring in terms of evaluation effort, not term size. Vague hypothesis: some term shapes make a lot more evaluation work than others (with some of the degenerate cases like nested applications being cheap?).
    - The pruning benefits of the follower seem very low (one example, I forget which was 12k vs 16k main search unifications) when the examples are ordered smallest to largest, but somewhat larger (60k vs 277k in ex3.scm with --check-follower-every 20) when the larger example appears before the smaller in the main search. That's still only a 4-5x improvement---not order's of magnitude.
    - If we allow nested applications, the interpreter degenerately synthesizes deeply nested applications when other routes have been refuted. Similarly, if we allow letrec forms in the expression to be synthesized, the interpreter can always fall back to adding more of those.

- Understand why the follower ends up doing enough unfolding to hit its suspend-depth limit. It seems like we've cut off the opportunities to unfold synthesis subproblems that should always fail with nested applications or letrecs, so I don't understand where else the follower will have the opporrtunity to unfold unboundedly.

- Explore tagging applications and removing not-in-envo; we're working with a super restricted language anyway, and this could make our guard evaluation a lot cheaper.

- We can probably remove the unsound-fail-depth; I haven't been using it and don't currently have a hypothesis where I might use it. Though I'm a little worried I'll remove it and want to restore it later!

- Turn the parameter prints into a pretty table.

