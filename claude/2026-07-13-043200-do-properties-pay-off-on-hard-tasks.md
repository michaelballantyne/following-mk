# Do relational properties pay off on a HARDER task? (Michael's challenge)

Michael, on the 2b correction: "might [relational properties] pay off in a
more difficult example that's harder to pin down with examples? Of course,
that might also be beyond what our synthesizer can handle."

This is a fair scoping objection and it's right. The correction
(`...-041637-property-specs-are-anchor-carried.md`) tested only:
- append/rember with **weak** properties (associativity, idempotence —
  candidate-dependent RHS, satisfied by projections); and
- rev with a **strong** property (involution, RHS = known input) but on an
  **easy** task (one anchor pins canonical rev-acc at bound 35).

It did NOT test the cell that would vindicate properties: a **hard task ×
a strong, output-fixing property**. That is where a property could plausibly
win — not on cost per candidate (always worse; measured 5–64×), but on
**authoring economy and coverage**: a universal property pins ALL structural
cases at once, whereas a hard, many-cased function needs many examples and a
small example set under-pins (rember's single anchor already gave a
head-wrap degenerate; you needed 4).

## The tension this surfaces (the real insight)

The regime where a property would help — a hard, many-cased task that is
painful to pin with examples — is **exactly** the regime where the
property's cost is worst. The follower re-runs the interpreter for every
nested application; that cost scales with evaluation depth × task size. On
append (shallow, bound 35) the property already cost 64× and 84s. On a
genuinely hard task (swap-pairs canonical is ~bound 63; a deeper evaluator)
the entangled double-application may make the follower **infeasible before
it can pin anything** — the property becomes the first thing that breaks the
search, not the thing that rescues it. So Michael's own caveat ("beyond what
our synthesizer can handle") may be the load-bearing half: properties could
be *more informative* and *less usable* on the same tasks. That would be a
sharper, more honest conclusion than either "properties are the flagship" or
"properties are useless."

## The concrete probe (built, run, both arms finished — see "First data" below)

swap-pairs, strong involution `swap∘swap = id`:
- `experiments/swap-involution-id-ty.scm` — involution (symbolic X len 2,4)
  + one anchor `(swap (5 6 7 8)) = (6 5 8 7)`.
- `experiments/swap-anchor-only-id-ty.scm` — same anchor, no property.

Predictions / what to read off:
1. If **anchor-only pins canonical swap** → property redundant even on the
   harder task; correction holds, tighten it to "any task a single
   structure-forcing anchor pins."
2. If **anchor-only under-pins (degenerate)** AND **involution+anchor pins
   canonical** → Michael's payoff regime is real; properties earn their keep
   where examples genuinely can't, and the question flips to whether the
   entangled cost stays feasible.
3. If **involution arm is infeasible** (OOM/timeout before an answer while
   anchor-only finishes) → the tension above is confirmed: properties help
   authoring exactly where they break the follower.

Caveat on the probe's power: a single 4-element anchor `(5 6 7 8)→(6 5 8 7)`
already forces both-pair-swap + recursion, so swap-anchor-only may well pin
(outcome 1), leaving the hypothesis still untested. The genuinely decisive
task is one where **no single ground example forces all structural cases**
but a global property does — hard to construct in this 5-form object
language. If swap comes back as outcome 1, the next move is to find or build
such a task (or accept that within this object language the profit regime
doesn't materialize, which loops back to the reflection's conclusion).

## First data (this session)

**swap-anchor-only PINNED canonical swap-pairs at bound 63** — 343,232
unify(main), 14.2M follower, 23s. Answer:
`(match l ['() l] [(cons a d) (match d ['() V] [(cons b dd) (cons b (cons a (swap dd)))])])`
(the odd-leftover base case left as a free hole `V`, unexercised by the
even-length anchor — the same spec-dead-branch reification wave-1's `last`
showed). So **outcome 1 on the harder task**: a single 4-element anchor,
which forces both-pair-swap + recursion, pins canonical swap. The
correction holds and tightens: *any task a single structure-forcing anchor
pins, the property is redundant on* — and that now includes a genuinely
hard (bound-63, nested-match) task, not just easy ones.

**swap-involution (property + same anchor) FINISHED: identical canonical
answer at the identical bound 63** — 506,850 unify(main), 45.3M follower,
61.8s, i.e. **1.48× unify(main), 3.2× follower, 2.65× wall** over
anchor-only for the same program. Outcome 1, cleanly: the strong involution
property is redundant overhead even on the hard task. The follower ratio
(3.2×) is smaller than append's (64×) only because swap's canonical is
bigger, so the anchor's own follower cost is already large — the property's
extra entangled eval is a smaller multiple of a bigger base, not cheaper in
absolute terms (45.3M vs append-property's 174.5M is task size, not relief).

Reading: Michael's harder-task hypothesis is not vindicated by swap, because
swap is still *anchor-pinnable* — one example that forces every structural
case exists. The hypothesis genuinely needs a task where NO single example
forces all cases but a property does. In this 5-form object language, whether
such a task exists at a reachable synthesis bound is now the open question
(the reflection's "profit regime" restated concretely). Leaning toward: it
may not, within this language.
