# Reflection: bidirectionality is an expressiveness win, not a search-efficiency win

Prompted by the 2b correction (`...-041637-property-specs-are-anchor-carried.md`).
That result is narrow but it undercuts a direction the last two sessions
leaned on, so a higher-altitude pass is due before picking the next question.

## What the correction does and does not say

**Does:** for a function that has a cheap forward ground example, a
relational/property spec (involution, associativity, idempotence) never
pins *better* and always costs *more* — 5–64× more follower work on
append/rember/rev, same answer, same bound. The entangled nested evaluation
is the cost and it buys no extra pinning.

**Does not:** it does not retract the follower/views themselves. Those are
load-bearing under ID and that's established across a dozen entries (the
no-follower arms time out; the views convert divergence to feasibility).
The correction is specifically about *property spec vs ground example* as
the information source, holding the follower fixed. Two different axes.

## The hole in the "find the profit regime" plan (2d as first written)

I wrote 2d as "find tasks where a pinning ground example is structurally
unavailable." Thinking it through, that is weak in *this* experimental
setup: the spec author always has a ground oracle here (we know reverse, we
know append), so we can always write a forward example, and by the
correction it wins. "Ground example unavailable" is really the oracle-free
PBE regime — a different problem than the one this prototype is set up to
study.

The two candidate profit-regimes that survive scrutiny:
1. **Nondeterministic relations**, where a functional ground example
   *over-commits* (insert-anywhere, permutation, any-splitting). Here the
   relation IS the natural spec and an example is wrong, not just weaker.
   But the object language synthesizes *deterministic functions* (letrec
   lambda), and lacks `<`/arithmetic, so the clean instances (sort,
   permutation) aren't expressible. Building this means changing the object
   language, not just picking a task.
2. **Oracle-free / genuinely-backward tasks** — out of scope for controlled
   measurement (no ground truth to score against).

So 2d as an *efficiency* hunt is likely a dead end in the current object
language. Recording that rather than spending runs discovering it arm by arm.

## The precise standing of identity #1

Identity #1 ("write once, run all directions; backward propagation for free,
no per-operator inverse semantics") is **real as an expressiveness /
engineering property** and the rev-involution arm demonstrates the
*capability* cleanly: the same interpreter ran `rev∘rev` composed, entangled,
with zero inverse code. What the correction removes is the *efficiency*
gloss: that capability is not a search-cost advantage — it is strictly more
expensive than the forward example that pins the same function. The honest
one-liner: **bidirectionality lets you say things you otherwise couldn't say
without hand-writing inverses; it does not make the search cheaper.**

That is still a genuine advantage — it's just an expressiveness claim,
measured in author effort / lines-of-inverse-code-avoided, not in unify
counts. If the project wants to defend identity #1 externally, the right
artifact is a task where the forward+backward+inverse would be onerous to
write by hand (a multi-operator little language, an evaluator with several
elimination forms) and the relational interpreter delivers all directions
from one definition — reported as expressiveness, with search cost stated
honestly as a *cost*, not spun as a win.

## Re-prioritization

- **Demote** the property/relational-spec-as-efficiency line. 2b resolved
  it; 2d as an efficiency hunt is downgraded to a Later note with the
  object-language-change caveat.
- **Promote** item 3 (first-order representation of the /d search, then the
  explicit scheduler). This is where the *measured* wins live (168×–11,092×
  on FD; 731× on append via the termination view) and where the regime call
  said the mainline work is: explicit search where measurements are
  perturbation-immune. The correction removes a distraction from it.
- **Keep** 1b (unified termination view) as the live views-side item — it's
  a real structural negative (R2T diverges) with a principled fix, and the
  termination view is the one that actually delivered the append win.
- Identity #1 defense becomes an *expressiveness* write-up task (Later),
  decoupled from search-cost claims.

Net: the next question is item 3 (first-order rep, step 1), not another
spec-shape arm. The spec-information-source axis is now well-mapped
(examples > properties for pinning; views load-bearing for feasibility;
minimality exposes under-pinning); the open leverage is search strategy.
