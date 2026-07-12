# Reflection: where the project stands after the factoring result and benchmark wave 1

Higher-altitude pass (Michael asked for it directly; also due by the
several-entries convention — last reflection was `...-175500-reflection-
forcing-density.md`, nine entries ago).

## Where we are

The system has settled into a small, legible architecture: a
size-closed ID enumerator over one *untyped* relational interpreter,
plus a follower doing unit propagation over independently-written
views (termination, types, canonicity, examples). Today closed the
three strategic questions that were open this morning:

1. **Composition is free.** The typed interpreter factored into
   untyped evaluator + type view at ~0% cost — the strongest evidence
   yet for identity #2, and it upgraded TY from "pays no rent" to 8.3×
   where type information isn't spent elsewhere. The general lesson is
   bigger than types: *where* information lives is an engineering
   choice; *whether* it's present is what determines search cost.
2. **Reasoning strength is not the bottleneck; information is.** The
   CDCL evaluation found every gap either small (2.7× ID ceiling),
   already-covered (views = hand-learned position-generic lemmas that
   transfer), or belonging to a different mechanism (domain
   propagation in FD). The refined program stands: add information
   sources, then schedule them better.
3. **The stack transfers — within a narrow family.** 8/9 tasks solved
   by the same five views with zero per-task tuning, baselines
   infeasible everywhere. Honest caveat: all nine are small forward
   list functions in one tiny language. The transfer claim is real but
   local; suite diversity is now a validity concern, not just
   coverage.

A pattern worth naming across today's negatives and surprises: every
failure was an *information* failure, not a search failure. interleave
failed because the termination view can't express its measure; evens'
degenerate answer was a spec (example-set) failure; last's hole was
the spec being silent. And the machine beating two human canonicals
says minimality is functioning as an instrument (it surfaces spec
weakness immediately). The system is now good enough that its errors
are interesting — they point at the spec language and the view
vocabulary, not at bugs.

## What blocks the goal now (and the order I'd attack it)

**1. Generalize the termination measure (R2).** The only outright
feasibility hole found by wave 1, it gates benchmark breadth (any
non-fixed-position recursion is currently unreachable), and it's
well-scoped: a /d view over total-size or lexicographic-over-
argument-permutation decrease, gated on interleave + all existing
canonicals. Small, unblocking, first.

**2. Bidirectionality-essential benchmarks (wave 2) — before more
infrastructure.** Identity #1 (write once, run all directions) is the
project's moat against Burst/Trio/SyRup, and *nothing measured so far
exercises it* — every task is forward enumerate-and-test-able. Beyond
defending the story, backward/partial-output specs should change the
physics: backward information *forces* (the output shape propagates
into structure), whereas forward examples mostly refute. The
forcing-density program looks different under backward information,
so this should come before committing to view designs tuned on
forward tasks. Fold into its measurement pass: the untyped+TY port of
wave 1, surviving-stream sampling, and symbolic examples (they are
themselves a richer-spec mechanism, same theme).

**3. First-order rep, steps 1–2 of the migration plan.** Green-lit,
three motivations (overhead constant, memory/measurement-enabling,
provenance), and step 2's printable follower trees improve the
sampling loop itself. It's the biggest investment and everything
scheduler-shaped needs it — but it's infrastructure, so it goes after
the feasibility hole and the differentiator benchmarks, not before.

**Deliberately behind those:** the length-domain view (wave 1 added
the element-blind tasks it wants — swap, evens, rev-acc, interleave —
so it's better-targeted after wave 2's spec work), coverage view
(waits for branchier specs), env-plumbing (out of scope until
measurement-blocking under the standing regime), explicit scheduler
(needs the rep).

## Risks to keep visible

- **Suite overfitting**: the five-view stack was bred on three tasks
  and confirmed on six more of the same species. Wave 2's job is
  partly to break it.
- **Spec authoring is the real interface**: the evens incident will
  recur in every PBE-style task; symbolic examples are the structural
  fix, worth prototyping during wave 2 rather than later.
- **Human canonicals as ground truth**: twice wrong today. Task
  headers now say "hypothesis"; keep it that way.
