- Related to the previous, turn the recent experiments (ex.scm, ex2.scm, ex3.scm) into tests or reproducible experiment files that explain things we've learned and let us see when other changes invalidate this knowledge.
    - With the mK search we interleave explorations of terms of very different size---ex. after testing a term of size 31, we go back to a term of size 3.
    - With search driven by the interpreter we are (somewhat) exploring in terms of evaluation effort, not term size. Vague hypothesis: some term shapes make a lot more evaluation work than others (with some of the degenerate cases like nested applications being cheap?).
    - The pruning benefits of the follower seem very low (one example, I forget which was 12k vs 16k main search unifications) when the examples are ordered smallest to largest, but somewhat larger (60k vs 277k in ex3.scm with --check-follower-every 20) when the larger example appears before the smaller in the main search. That's still only a 4-5x improvement---not order's of magnitude.
    - If we allow nested applications, the interpreter degenerately synthesizes deeply nested applications when other routes have been refuted. Similarly, if we allow letrec forms in the expression to be synthesized, the interpreter can always fall back to adding more of those.

- We can probably remove the unsound-fail-depth; I haven't been using it and don't currently have a hypothesis where I might use it. Though I'm a little worried I'll remove it and want to restore it later!

- Document the research goal: explore how much pruning we can get, ignoring the overhead cost. Work in a context where it's easy to compare to baseline faster-miniKanren. Avoid perturbing the search order other than by failure and by propagation of determined information. Simplify the interpreters we're working with as necessary to avoid degenerate cases and see if there exists a scenario where propagation gets us big wins. Determine whether the search strategy needs to be different for this to be the case---I have hypothesized that pruning with the standard mK search often doesn't actually let us spend less time on fruitless branches because we can often never close things off entirely. If we can show that following-mk's propagation can get us orders-of-magnitude search savings in some context, *then* we can figure out how to lower the overhead and generalize to harder interpreters.

- Document the return type from /d goals and find an appropriate name for it. It isn't a stream---we never split into multiple answers! When we get a (c f), *every* answer produced by f will be an extension of the store `c`. Refactor to eliminate `stream` as a variable name and rename the `case-inf/d` form.

- Document the new implementation of conjunction and disjunction and its refutation capabilities. Make more tests. See if the implementation can be simplified at all.

- Make sure we have documented (and I just understand well) what makes the hard suspend at depth limit vs resumable suspend on nondeterminism system work and still converge. I think the idea is that refining resumptions don't give more depth limit, only the top level resume of the hard suspend does.

- Explore whether there are any properties that the programmer must ensure of their conde/d guards. I think it is now okay if they (conceptually) diverge or return multiple answers, as the depth limit and nondeterminism handling address both, but it would be good to test. Relatedly, can we describe how the programmer has to think about splitting between the guard and the body to maximize determinate progress, and what happens if they make the wrong choices, and how they can debug?

- Document the guarantees that `follower` provides and doesn't provide. We're mostly expecting it to be used in a particular pattern: `(run n (q) (follower q g/d) g)` where g/d is like g but using the /d forms. Document that the idea is to eventually abstract over this pattern with something like staged minikanren's multiple compilations from one syntax. But we sometimes write tests and benchmarks that don't follow the pattern. And right now at the end of the search we trigger the follower once, but if it suspends either because it is indeterminate or hits the depth limit we don't force it again. We thought about forcing it further, but realized that this could lead to divergence through guards, such that the main search doing a run 1 query has the follower diverge as the overall query would in a run*.

- Document other sharp corners of the /d language---for example, if you write a recursion that doesn't go through a conde/d it can diverge in follower evaluation (even if it goes through a fresh/d---in normal faster miniKanren that's enough to get interleaves). Consider fixing such sharp corners.

- Understand why the follower ends up doing enough unfolding to hit its suspend-depth limit. It seems like we've cut off the opportunities to unfold synthesis subproblems that should always fail with nested applications or letrecs, so I don't understand where else the follower will have the opporrtunity to unfold unboundedly.

- Explore tagging applications and removing not-in-envo; we're working with a super restricted language anyway, and this could make our guard evaluation a lot cheaper.

- Document the relationship to closely related work like dKanren (https://github.com/gregr/dKanren/tree/master), Petr Lozov's work (https://minikanren.org/workshop/2020/minikanren-2020-paper1.pdf and https://dl.acm.org/doi/10.1145/3441296.3441397), mkcdcl (https://github.com/michaelballantyne/mkcdcl), backjumping (https://github.com/michaelballantyne/backjumping-miniKanren), my also "dKanren" (https://github.com/michaelballantyne/backjumping-miniKanren). Also underconstraints, Andora. Contrast the fair conjunction problem generally with the more limited goal of complete unit propagation (Which is the Andora principle?). Frame this WRT the research goal above---these other systems tackled more general problems, but that also made them harder to evaluate and predict.

- Note the conde/d lineage from condg in earlier staged-miniKanren work, and explore whether we can use something more like the latest staged-miniKanren approach to remove the syntactic overhead.

- Consider removing the set-var-val! optimization from the implementation entirely. But maybe we want to do that in base faster-mk too or first? Will thinks it has negative value on the ecosystem.

- Explore using a first-order representation for the /d part of the search. It might make it easier to flatten away unneeded structure, like nested conjunctions that show up after a determinate conde simplifies. Then we could spend less just in rebuilding tree structure each time we run the follower. Similarly we might also be able to save the state of each branch's guard in a nondeterminate conde, so we don't have to re-do work on progressing it next time.

- Write examples or tests illustrating limitations---in what way is this not full fair conjunction? Things that would terminate with CDCL or Petr Lozov's work but don't here.

- A more ambitious future idea: this might compose easily with mkcdcl! And maybe you could even restrict the provenance and search tree structure tracking to the infrequently-executed follower search, with some cleverness.

- I'm not sure if I understand whether once something has failed or been forced in the follower that equivalent work in the leader will always be avoided. Learned constraints are communicated via the constraint store, but that may not correspond to cutting off all related unnecessary exploration of goals. 

- Enhance test-check to give us a summary at the end of test-all.scm.