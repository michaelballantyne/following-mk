# Classic mk search + fused typechecker vs. current best: the real baseline, all 9 tasks

Michael's question: how competitive is the current approach (size-closed ID +
composed follower views) against the baseline that actually predates this
project — classic (fair-interleaving) miniKanren search, with a typed
relational interpreter as the sole check, no follower, no composed views?
Most of the project's headline multipliers (175×–2,380×, 731×) were measured
against a *weaker* strawman: size-closed ID *without* a follower, which pays
an artificial minimality-exhaustion tax classic search never agreed to pay.
This entry is the first full, fresh, apples-to-apples sweep against the
baseline Michael actually meant, all 9 tasks, both unify(main) and wall-clock.
Built and run by a delegated agent (7 new classic-search files + 1 missing
current-best arm for append), every number independently re-verified by hand
in the main loop before trusting it — including hand-tracing all three
disputed "wrong answer" programs against explicit counterexamples.

## Method

Classic-search files (`synthesis/*-full-classic.scm`, new except rember/
append which already existed): plain `(run 1 (q) (absento ...) (evalo
(<task>-prog q '(<call>)) <expected>) ...)` — the typed interpreter
(`evalo`), fair interleaving, no ID harness, no follower, no views. Same
examples and absento constraints as the corresponding current-best arm, so
only the search+views axis differs. Current-best files: the existing
`experiments/<task>-full-id-views.scm` (R2 default) or `-r2p.scm` for
interleave specifically (plain R2 refutes interleave's canonical
argument-swap, so R2P is the per-task-selected measure there), plus one new
file, `experiments/append-full-id-views.scm` (append never had a typed
ID+views arm before — only untyped ones).

## Results

| task | classic unify(main) | classic wall | classic answer | current-best unify(main) | current-best wall | current-best answer |
|---|---:|---:|---|---:|---:|---|
| append | 442,724 | 215ms | ✓ canonical | 145,134 | 5,345ms | ✓ canonical |
| rember | 3,229,244 | 3,016ms | ✓ canonical | 328,127 | 10,586ms | ✓ canonical |
| duplicate | 417,928 | 259ms | ✓ canonical | 57,837 | 762ms | ✓ canonical |
| evens | 102,650 | 50ms | ✓ correct, general, non-canonical (`l`-substitution trick) | 276,340 | 10,202ms | ✓ correct, smaller than predicted (55 vs header's 71) |
| **last** | 46,378 | 19ms | **✗ WRONG** — 3-level nested match, hardcodes lengths 1–3, no recursive call | 115,463 | 4,089ms | ✓ canonical |
| **member** | 66,523 | 32ms | **✗ WRONG** — else-branch hardcodes "nonempty tail ⇒ 1" at depth 1, no recursion past it | 100,425 | 2,465ms | ✓ canonical |
| swap | 229,915 | 113ms | ✓ correct, general — the same machine-minimal size-63 "return `l`" trick already on record | 504,535 | 27,216ms | ✓ same size-63 trick |
| **rev-acc** | 14,123,833 | 25,713ms | **✗ WRONG** — 4-level nested match hardcoding lengths 0–3, no recursive call | 133,262 | 35,215ms | ✓ canonical |
| interleave | 724,205 | 560ms | ✓ correct, general (extra provably-equivalent unfold layer, larger than canonical) | 115,939 | 2,826ms | ✓ canonical, via R2P |

No run needed more than one attempt; nothing came close to its timeout
(900s classic / 500s or 240s current-best).

## Hand-verification of the three disputed programs (do not skip this — it's the finding)

- **last**: `(match l ['() _.0] [(cons _.1 _.2) (match _.2 ['() _.1] [(cons
  _.3 _.4) (match _.4 ['() _.3] [(cons _.5 _.6) _.5])])])`. Traced on
  `l=(10 20 30 40)`: binds `_.1=10, _.3=20, _.5=30`, returns `_.5=30` — the
  *third* element, not the actual last (`40`). Wrong for any list of length
  ≥4; the three depth-≤3 examples never distinguish "return position 3" from
  "return the last position."
- **member**: `(match l ['() 0] [(cons _.0 _.1) (if (= _.0 e) 1 (match _.1
  ['() 0] [(cons _.2 _.3) 1]))])`. Traced on `(member 5 '(6 7))`: `_.0=6 ≠
  5`, falls to `(match _.1=(7) ...)`, hits the cons clause unconditionally,
  returns `1`. But 5 is not in `(6 7)` — should be `0`. The four depth-≤2
  examples never probe a non-member past the first position.
- **rev-acc**: nested match to depth 4, hardcoding the accumulator-cons
  pattern for lengths 0–3 with no call to `rev`. Traced on `l=(10 20 30 40),
  acc='()`: the four-or-more-element case falls into the length-3 clause's
  `(cons _.4 _.5)` branch (since that clause only tests "is the tail
  non-empty," not "is the tail exactly one element"), returning `(30 20 10
  40)`. Correct reverse is `(40 30 20 10)`. Wrong for length ≥4.
- **evens** (control check, confirmed genuinely equivalent, not overfit):
  the single-element base case returns the outer `l` directly instead of
  rebuilding `(cons a '())` — valid because at that point `l` already *is*
  the singleton list being returned. Traced through all four example
  lengths plus length 5 by hand: matches canonical semantics exactly, no
  discrepancy.
- **interleave** (same control check): hardcodes "the second recursive
  call's second argument is empty ⇒ return the first argument" instead of
  taking one more level of recursion to discover the same fact. Provably
  true by induction on the canonical definition (`interleave(x, '()) = x`
  for any `x`, shown by unfolding the recursion twice) — confirmed correct,
  just a larger, less minimal — but still fully general — program.

## What this means, and how it revises the earlier headline numbers

**The efficiency picture is genuinely mixed when both sides are correct.**
Classic search is often *cheaper in raw unify count and always faster in
wall-clock* than the current approach on tasks where it happens to land on
something valid (evens, swap: classic actually costs less, because it
isn't paying the exhaustive-minimality tax and got lucky with mk's
interleaving order). On other tasks (rember ~10×, duplicate ~7×,
interleave ~6×) the composed views' refutation power visibly earns back
more than the tax costs. Wall-clock is uniformly in classic search's favor
on the correct-on-both-sides tasks — unsurprising, since it isn't required
to prove minimality. **The old multipliers (175×+) measured something
real, but the "no-follower ID" baseline they used is not this baseline; it
overstates the win against what miniKanren practitioners would actually
write.**

**The correctness picture is not mixed at all, and is the actual headline.**
On **3 of 9 tasks — exactly the ones with a dead branch (`last`), a
depth-bounded equality check (`member`), or an accumulator pattern
(`rev-acc`)** — classic search silently returns a program that is *wrong*,
not just non-minimal, and nothing about the classic-search run signals
this: it reports success, same as the correct runs do. The current
approach never does this, on any of the 9 tasks, with the same example
budget. This is the load-bearing result: the value the composed-views
architecture demonstrably buys isn't "faster" (that's task-dependent and
often false) — it's "sound," in a regime where the honest classic-search
alternative is silently unsound roughly a third of the time.

## Consequence for the project's self-story

The earlier "orders of magnitude" framing (research-goal-status,
BACKLOG.md) is not wrong, but it answered a narrower question (does
size-closed search + views beat size-closed search without views) than the
one that matters for positioning against the field (does this beat what
people actually do). Against the real baseline: efficiency is a wash,
sometimes favorable, sometimes not; the clear, consistent, previously-
unmeasured win is generalization correctness under a small example budget.
That is arguably a *better* result to have — it is not sensitive to the ID
apparatus at all, and it directly rebuts the "just enumerate and test"
alternative on grounds classic search cannot answer by trying harder
(more time would not fix `member`'s or `last`'s wrong answer; only a
structural check or more examples would, and choosing more examples
without a coverage-detection mechanism is exactly the gap the "fix the
productivity tally" / "coverage view" backlog items are already aimed at).
