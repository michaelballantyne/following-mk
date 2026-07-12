# Cross-reference: combining this project's top-down approach with bottom-up OE synthesis

A literature review and feasibility analysis of combining following-mk's
top-down, determinacy-propagating synthesis with bottom-up
observational-equivalence synthesis on a Datalog substrate lives in the
sibling repo:

- `bottom-up-synth-datalog/notebook/2026-07-12-2116Z-topdown-bottomup-feasibility-synthesis.md`
  (the synthesis; answers "can they combine," "can top-down be encoded in
  Datalog via demand transform," "can it be derived from a relational
  interpreter/typechecker spec")
- three same-day litcheck entries cited therein (hybrid synthesizers;
  magic sets / demand transformation; one-spec-many-modes precedent).

Findings that bear directly on this repo:

1. **Simba (Yoon, Lee, Yi, PLDI 2023) is the closest published analogue of
   the follower mechanism**: alternating forward/backward abstract
   interpretation over a shared annotation of a partial program, iterated to
   a local fixpoint — structurally the follower's "propagate whatever either
   source forces" loop, with abstract domains in place of the constraint
   store. Worth a direct cross-read before designing any combined system,
   and a candidate comparison point for evaluating follower pruning.

2. **The TODO item "separate interpreter and typechecker for the same
   language — can they work together?" is a genuinely open question.** A
   targeted search found no published system running one spec through
   evaluate + typecheck + synthesize with real cross-source fusion. The
   fine-grained (per-fact, mid-derivation) fusion the follower does has no
   Datalog analogue — semi-naive evaluation propagates per-stratum — so this
   repo's mechanism is the differentiated piece, not something the
   relational substrate subsumes. Raises, not lowers, that experiment's
   priority.

3. **In a combined architecture, the follower's natural home is the schedule
   layer**: a determinacy pass over the demand frontier between cost levels
   of a bottom-up bank — a per-level batched approximation of Andorra —
   rather than trying to make a saturating engine do per-fact wakeups.
