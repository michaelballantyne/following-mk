# Related synthesis systems: cross-example / cross-interpretation integration

*Draft — assembled from web search + model knowledge on 2026-07-12. Citations
are to primary sources (venue + year + link) but have NOT been human-verified;
treat quantitative claims (benchmark %s, speedups) as "as reported." Main
session reviews before committing.*

The question: are there specialized synthesizers doing following-mk's kind of
cross-example, cross-interpretation integration of partial information, and
what is the state of the art? Below, one paragraph per system family, then an
honest placement of following-mk.

## VSA / FlashFill / PROSE — intersection as the integration mechanism

FlashFill and the PROSE (FlashMeta) framework represent the set of all
DSL programs consistent with an example as a **version-space algebra (VSA)** —
a shared DAG that can hold 10^100+ programs succinctly. Cross-example
integration is literally **VSA intersection**: one example yields one VSA,
and the consistent set for N examples is the intersection of the N VSAs, done
structurally on the DAG. The deductive engine decomposes a spec on an
expression into specs on subexpressions using **witness functions** — the DSL
author's hand-written *inverse semantics* for each operator (given a desired
output of `Concat`, what must the arguments be?). This matches the from-memory
map. What the DSL author must supply: the grammar, forward semantics, a witness
function per operator, and a ranking function. Sharpest contrast: PROSE's
propagation is *backward and deductive* through author-supplied inverses, and
integration is a batch set-intersection; following-mk propagates *forward*
through one ordinary (non-inverted) relational interpreter, and integration is
incremental constraint accumulation in the shared substitution rather than a
product of pre-built spaces. (FlashMeta, OOPSLA 2015,
https://www.microsoft.com/en-us/research/publication/flashmeta-framework-inductive-program-synthesis/;
VSA↔tree-automata equivalence, Koppel, https://arxiv.org/pdf/2107.12568.)

## FTA-based: DACE and Blaze — abstract product + CEGAR

DACE (Wang, Dillig, Dillig, OOPSLA 2017, https://arxiv.org/pdf/1707.01469)
builds a **finite tree automaton** whose accepted trees are exactly the
programs consistent with the examples; multi-example consistency is FTA
intersection (the automaton product). Blaze (Wang, Dillig, Singh, "Program
Synthesis using Abstraction Refinement," POPL 2018,
https://arxiv.org/pdf/1710.07740) generalizes this to **abstract FTA**: states
are elements of a predicate-abstraction domain, so many concretely-distinct
programs collapse to one abstract state, shrinking the search. It runs
**CEGAR**: start coarse, and when the abstract FTA accepts a spurious program,
build a proof of incorrectness and refine the abstraction to exclude it *and
many siblings*. The map's characterization is accurate. Author burden:
DSL + concrete semantics + an abstract domain with abstract transformers.
Contrast with following-mk: Blaze's abstraction is a designed static domain and
refinement is offline between search rounds; following-mk's "abstraction" is
whatever the concrete interpreter forces to be unique at a choice point, applied
online, and its second "view" (termination check) is another concrete
interpretation composed at runtime rather than a lattice.

## Myth → SMyth → Scrybe / Trio — example propagation in typed functional PBE

Myth (Osera & Zdancewic, PLDI 2015) is type-and-example-directed: it pushes I/O
examples *into* holes via type-directed refinement, but requires **trace-complete**
example sets and enforces **structural recursion**. SMyth (Lubin, Collins, Omar,
Chugh, ICFP 2020, https://arxiv.org/pdf/1911.00583) introduces **live
bidirectional evaluation**: it evaluates a sketch forward, then runs evaluation
*backward* ("unevaluation") to push output examples through partially-evaluated
code onto holes, which removes the trace-completeness requirement and lets
interdependent goals constrain each other. This is the closest classical analogue
to following-mk's forward-incremental idea, and the map states it correctly.
Two successors the map should add: **Scrybe** (Mulleners, Jeuring, Heeren, PADL
2023, https://arxiv.org/abs/2210.13873) combines λ²-style top-down *deductive*
reasoning with SMyth-style live bidirectional evaluation, propagating example
constraints through sketches to prune, and covers the union of the λ² and Myth
benchmarks; and **Trio** (Lee & Cho, "Inductive Synthesis of Structurally
Recursive Functional Programs from Non-recursive Expressions," POPL 2023,
https://psl.hanyang.ac.kr/assets/pdf/popl23.pdf) does **block-based pruning** —
synthesize straight-line "blocks" per example first, then prune recursive
candidates inconsistent with them (~98% of its suite). Author burden across this
family: a typed functional language + examples; recursion structure is baked into
the search. Contrast: they are all committed to a *specific* typed functional
target language and evaluation relation; following-mk's leader/follower are meant
to be *compiled from one user-written relational interpreter*, so the target
language is not privileged machinery.

## Bottom-up observational-equivalence and angelic recursion — Burst / Probe / SyRup

Bottom-up enumeration (originated by **Transit**, Udupa et al. PLDI 2013, and
**Escher**, Albarghouthi et al. 2013) grows a bank of subprograms and dedups by
**observational equivalence** on the example inputs — the integration mechanism
is "collapse anything that agrees on all examples." **Burst** (Miltner, Nystrom,
et al., POPL 2022, https://www.cs.utexas.edu/~isil/burst.pdf) extends bottom-up
to *recursive* functions via **angelic semantics** (guess recursive-call results,
reconcile later), reportedly solving 94% of its suite. **Probe** (Barke, Peleg,
Polikarpova, OOPSLA 2020, https://shraddhabarke.github.io/raw/probe.pdf) adds
just-in-time learning of a guiding grammar from partial solutions. **SyRup**
(Yuan et al., PLDI 2023 distinguished paper,
https://par.nsf.gov/servlets/purl/10498880) augments the space with **recursion
traces** and uses a VSA over (trace, program) pairs — a direct fusion of the VSA
and trace-guided lines. Contrast: observational equivalence is a *retrospective*
merge over already-enumerated programs on fixed inputs; following-mk's forcing is
*prospective* — it commits shared structure before the subprograms are fully
built, and its examples are run through the *same* interpreter that defines
meaning rather than a separate concrete evaluator.

## Solver-side and conflict-driven — CEGIS/Sketch, Rosette, Neo

CEGIS/Sketch (Solar-Lezama) and Rosette (Torlak & Bodík, PLDI 2014) integrate
all constraints *inside an SMT/SAT solver*: examples and the spec become one
formula, and cross-example reasoning is whatever the solver's theory propagation
and conflict analysis do. **Neo** (Feng, Martins, Bastani, Dillig, PLDI 2018,
https://arxiv.org/pdf/1711.08029) lifts CDCL to synthesis: from a failing
candidate it computes the conflict's root cause and learns **lemmas**
("equivalence modulo conflict") that prune many future candidates. The map is
right. Contrast: this is learning-from-failure at the *spec* level via a solver;
following-mk carries no learned lemma store — its "propagation" is unit-style
forcing in the constraint substitution during one shared derivation.

## Inductive logic programming — Popper, ILASP

Popper (Cropper & Morel, "Learning programs by learning from failures," MLJ
2021, https://arxiv.org/pdf/2005.02259) runs **generate–test–constrain**: an ASP
solver generates a hypothesis, Prolog tests it against positive/negative
examples, and failures are turned into **constraints** (ASP clauses) that prune
the hypothesis space — a very direct "integrate across examples by accumulating
refutation constraints" loop. ILASP (Law et al.) is ASP-based and learns under
the answer-set semantics; it grounds the program (Popper avoids grounding, so
scales better with domain size). Author burden: background knowledge predicates
+ a language bias. Contrast: ILP integrates *logical entailment* facts across
examples via a symbolic solver; following-mk integrates *operational* facts
(what the interpreter forces) across examples via shared unification state.

## e-graphs / equality saturation — mostly adjacent, not cross-example PBE

Equality saturation over e-graphs (egg; Willsey et al., POPL 2021) is exploding
(EGRAPHS workshop 2024–2026) but is overwhelmingly used for
**rewrite-driven optimization/superoptimization and lemma discovery**
(Guided Equality Saturation POPL 2024; CCLemma ICFP 2024; SEER ASPLOS 2024), not
example-driven functional synthesis. The e-graph is a congruence-closure product
much like a VSA, so it *could* host cross-example intersection, but I found no
mainstream PBE synthesizer whose primary integration mechanism is equality
saturation over examples. Worth noting as a structurally-related data structure,
not a competitor. (Awesome-egraphs: https://github.com/philzook58/awesome-egraphs.)

## LLM-hybrid deductive synthesis — the deductive half rarely does cross-example propagation

Current neuro-symbolic code work (LLM proposes, symbolic component checks/repairs)
mostly uses the symbolic side as a *verifier or top-down proof search*
(SymBa, LOGIPT, AlphaGeometry-style), not as a cross-example constraint
propagator. I did **not** find a well-known 2024–2026 system where an LLM
proposes and a deductive engine integrates multiple I/O examples by propagation
in following-mk's sense; this looks like a genuine gap / opportunity rather than
a crowded field. (Survey: https://arxiv.org/html/2508.13678v1.)

## Relational / miniKanren machinery beyond Barliman & dKanren

The most relevant is **Neural-Guided Constraint Logic Programming for Program
Synthesis** (Zhang, Rosenblatt, ... Byrd, NeurIPS 2018,
https://arxiv.org/pdf/1809.02840): it keeps miniKanren's relational interpreter
running backward but learns a neural policy to pick which constraint/branch to
expand — a *learned* scheduler over the same substrate following-mk schedules by
determinacy. Byrd's line continued through "Relational Interpreters, Conversion,
and Synthesis" (miniKanren 2022) and **Walrus** (miniKanren 2025,
https://www.arxiv.org/pdf/2510.02579v2), a typed relational language in Haskell
aimed at relational compilers/decompilation. None of these adds an
Andorra-style determinacy-directed follower; following-mk's forward-follower
over faster-miniKanren appears to be a distinct point. The classical ancestor of
the mechanism is the **Andorra principle** (run determinate subgoals first) and
the Extended Andorra Model from parallel LP (Warren; Costa; Santos Costa et al.);
following-mk is essentially Andorra determinacy applied as a *synthesis* steering
signal, which the LP literature did not pursue.

## What following-mk's angle adds / where it's behind

**Adds.** (1) *One source, two runners.* Every system above hand-builds its
integration machinery — witness functions (PROSE), abstract transformers (Blaze),
unevaluation (SMyth), conflict lemmas (Neo). following-mk's bet is that leader
and follower are *compiled from a single plain relational interpreter*, so the
DSL author writes forward semantics once and gets deductive propagation for free.
That is a real ergonomic/soundness story nobody in the list offers. (2)
*Composable second views.* Integrating an evaluator with a syntactic termination
check (and prospectively types) as co-running followers over one shared state is
close to Neo's multi-source pruning and Blaze's abstraction but done *online and
uniformly* — and today's finding (98% of whole-body search is unconditionally
divergent, refutable structurally not by examples) is exactly the case where a
second view should dominate; that's a sharper, better-instrumented version of the
same lesson Burst/SMyth encode structurally.

**Behind.** (1) *Forcing density is the whole game and the competition engineers
it in.* PROSE/Blaze/SyRup get their leverage from carefully-built product
structures (VSA/FTA/trace-VSA) that guarantee dense cross-example collapse;
following-mk gets density only where the interpreter happens to force uniqueness,
and the null result of the day is that whole-body interpreter synthesis is *forcing-sparse*.
(2) *No learned pruning.* Neo's lemmas, Probe's learned grammar, and neural-guided
CLP all accumulate cross-attempt knowledge; following-mk currently forgets between
choice points. (3) *No abstraction lattice.* Blaze can prune with abstract states
that following-mk's purely-concrete forcing can't see. (4) *Structural recursion
handling* is a solved-ish problem (Myth/Burst/Trio/SyRup) that following-mk is
only now reaching via the termination view. The honest read: following-mk's
*compile-from-one-source* framing and Andorra-as-synthesis-signal are genuinely
novel and under-explored; its raw pruning power on general functional synthesis
is, so far, behind the FTA/VSA and angelic-bottom-up state of the art, and the
project's own measurements say so.

## Worth reading first (shortlist)

1. **SMyth** — Lubin et al., ICFP 2020 (https://arxiv.org/pdf/1911.00583).
   The nearest philosophical cousin: forward+backward example propagation
   through partial programs; read for both the mechanism and its limits.
2. **Blaze** — Wang, Dillig, Singh, POPL 2018 (https://arxiv.org/pdf/1710.07740).
   The cleanest statement of abstraction + CEGAR over FTAs; the "abstraction
   as forcing-density amplifier" idea following-mk lacks.
3. **Burst** — Miltner et al., POPL 2022 (https://www.cs.utexas.edu/~isil/burst.pdf).
   How the bottom-up world handles recursion (angelic execution) — directly
   relevant to the divergent-candidate problem found today.
4. **SyRup** — Yuan et al., PLDI 2023 (https://par.nsf.gov/servlets/purl/10498880).
   State-of-the-art trace-guided VSA for recursive PBE; the current bar on the
   Myth suite and a template for integrating a second (trace) view.
5. **Neural-Guided CLP for Program Synthesis** — Zhang et al., NeurIPS 2018
   (https://arxiv.org/pdf/1809.02840). The other attempt to add a steering
   signal to backward-run miniKanren; contrast learned scheduling vs.
   determinacy-directed scheduling.
