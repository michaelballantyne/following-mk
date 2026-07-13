# Fair search + the same composed views closes the wall-clock gap, but silently reintroduces wrong answers on 2-4 of 9 tasks

Follow-up to `...-152035-classic-search-vs-current-best.md`. The proposed
experiment: run the identical, already-sound view stack (R1/R2 or R2P/TY/NV
+ examples) under classic fair-interleaving search instead of size-closed
ID, to see whether the views' soundness benefit survives without paying
ID's minimality-exhaustion tax. Swept `*check-follower-every*` at 1, 20,
100 across all 9 tasks (27 runs). Built and run by a delegated agent; the
agent's own final report never materialized (ended its turn mid-wait, same
failure mode as an earlier round this session) — **every result below was
independently hand-traced by the advisor from the raw logs**, not taken on
the agent's word. This is exactly why: the naive read of "test passed" or
"test failed (probably reification noise)" would have missed a real
correctness regression.

## The wall-clock question: answered, resoundingly yes

| task | ce1 (unify/wall) | ce20 (unify/wall) | ce100 (unify/wall) |
|---|---:|---:|---:|
| rember | 1,582,277 / 4m52s | 2,393,953 / 44.0s | 2,530,111 / 11.0s |
| append | 623,096 / 1m14s | 488,501 / 3.3s | 428,237 / 0.6s |
| duplicate | 178,464 / 17.8s | 181,522 / 1.3s | 108,245 / 0.4s |
| evens | 123,190 / 12.7s | 101,232 / 0.65s | 106,774 / 0.4s |
| last | 54,171 / 3.8s | 98,119 / 0.65s | 68,722 / 0.4s |
| member | 51,884 / 3.5s | 68,078 / 0.62s | 72,249 / 0.4s |
| swap | 268,335 / 31.0s | 206,957 / 1.4s | 188,645 / 0.5s |
| rev-acc | 510,489 / 2m21s | 451,868 / 7.2s | 163,732 / 0.7s |
| interleave | 467,540 / 1m6s | 647,946 / 8.3s | 390,120 / 0.7s |

Checking the follower less often (`ce1` → `ce100`) buys a 10–50× wall-clock
win uniformly, with unify(main) usually flat or improving too. At `ce100`
every task lands at or under 11 seconds, most under a second — genuinely
competitive with classic search's raw speed (compare the previous entry's
classic-search-alone wall times: sub-second to low single digits
everywhere except rev-acc's 25.7s overfit-computation outlier). The
hypothesis that avoiding ID's exhaustion tax recovers most of the wall-clock
gap is confirmed cleanly.

## The correctness question: NOT answered the way it was expected to be

Every "Failed" and "passed" result across all 27 runs was hand-traced
(substitution on a length-4 input, checked against the task's actual
semantics) rather than trusted from the test-check output alone, because a
"Failed" can mean either a harmless reification difference (same program,
extra sound `=/=` facts from a different derivation order) or a genuinely
wrong program — and the two look identical in the log until you actually
trace the computed term.

**Five tasks are correct at every check-follower-every setting tested**
(rember, append, evens, swap, interleave) — some with extra harmless
disequality noise (rember, append), some as different-but-general variants
matching tricks already on record (evens, swap, interleave).

**Four tasks are NOT uniformly correct, and the pattern is genuinely
concerning:**

| task | ce1 | ce20 | ce100 |
|---|---|---|---|
| duplicate | ✗ wrong | ✗ wrong (identical term) | ✓ correct |
| rev-acc | ✗ wrong | ✗ wrong (identical term) | ✓ correct |
| last | ✗ wrong | ✗ wrong (identical term) | ✗ wrong (identical term) |
| member | ✗ wrong | ✗ wrong (identical term) | ✗ wrong (identical term) |

Every "wrong" answer traced to the same failure shape: **a non-recursive
program with zero self-calls to the function being defined**, hardcoded to
the depths the (shallow, length ≤3) examples happen to probe. Traced
concretely:
- `duplicate` (ce1/ce20): 4-level nested match, silently drops the final
  element's duplicate for length-3+ inputs (returns 5 elements instead of
  6).
- `last` (all three settings): the *identical* wrong program classic
  search alone produced in the previous entry — returns the 3rd element
  for any length-≥4 list.
- `member` (all three settings): the *identical* wrong program from
  before — the else-branch hardcodes "nonempty tail ⇒ member," wrong on
  e.g. `(member 5 '(6 7))`.
- `rev-acc` (ce1/ce20): a 10-variable, 4-level-deep hardcoded term with no
  `rev` self-reference anywhere.

## Why this happens: the views were never the thing preventing these overfits

This is the load-bearing insight, and it revises something claimed a few
turns ago in conversation (that fair search + the same views should stay
sound). Trace *why* R1/R2/TY/NV fail to refute a non-recursive candidate:

- **R1** (`base-case-patho/d`) refutes bodies where *every* path applies
  `fname` (caseless, guaranteed-divergent bodies). A body with *zero*
  self-calls trivially has every path avoid `fname` — R1 has nothing to
  say against "give up on recursion entirely."
- **R2/R2P** (`decreasing-recursiono/d`/`permuted-...`) check that *every
  self-call* decreases at some position. With zero self-calls, "for all
  self-calls, X holds" is vacuously true. R2 also has nothing to say.
- **TY** (`type-ofo/d`): a non-recursive body built entirely from
  well-typed literals and library-provided sub-results type-checks fine.
- **NV** (`non-vacuous-testso/d`): no `if` nodes in these particular
  overfits, so nothing to check.
- **The examples themselves** (evalo/d over the 3-4 ground I/O pairs, all
  ≤3 elements deep): the overfits are specifically engineered by
  construction to satisfy exactly these shallow examples.

So **nothing in the composed stack ever refuted these candidates** — under
either search strategy. The reason ID+views never returns them isn't that
the views catch them; it's that **the correct, genuinely-recursive
canonical answer happens to be smaller** than these degenerate hardcoded
terms, and size-closed ID finds the smallest satisfying answer first,
never reaching the larger wrong one. Fair search has no notion of size
priority at all — mk's own interleaving order is what decides which
satisfying candidate turns up first, and for `last`/`member` (in every
configuration tried) and `duplicate`/`rev-acc` (except at `ce100`
specifically), that happens to be the wrong one.

**Minimality was doing more of the correctness-preserving work than the
composed views were, on this subset of tasks — a fact this project's
own numbers had not previously isolated.**

## What this means going forward

1. **Fair search + views cannot be recommended as a general drop-in
   replacement for size-closed ID.** It is a strict win when it works
   (5-9 of 9 tasks depending on `check-follower-every`), but the failure
   mode is *silent* — a wrong-answer run reports success identically to a
   correct one, with no signal in the counters or output that anything is
   amiss. Recommending this configuration without a way to detect the
   failure would be trading a known, honest cost (ID's wall-clock tax) for
   an unknown, silent one.
2. **`check-follower-every` is not a safe dial to tune for correctness.**
   `duplicate`/`rev-acc` recovering specifically at `ce100` (but not `ce1`
   or `ce20`) looks like it could invite exactly the wrong intuition —
   "just find the config that passes" — when `ce100`'s success here is an
   artifact of mk's own search order at that specific throttle, not a
   principled fix. `last`/`member` prove no throttle setting tried fixes
   the underlying gap.
3. **This sharpens the case for the coverage/adequacy view further** (already
   raised in priority by the previous entry). It's now demonstrated on
   *two independent search strategies* that the current example sets for
   `last`/`member` (and, throttle-dependently, `duplicate`/`rev-acc`) are
   inadequate to force genuine recursion, and nothing in the stack
   currently can tell you that — a run that returns a wrong answer looks
   exactly like a run that returns a right one.
4. **The honest per-task story, not a single number**: for tasks where
   fair search + views IS correct regardless of throttle (rember, append,
   evens, swap, interleave), it's a legitimate, much faster alternative to
   ID and worth adopting. For the other four, ID's minimality guarantee is
   currently load-bearing for correctness, not just optimality, and
   shouldn't be given up without first fixing the example sets (more/
   deeper examples per the existing "single ground anchors under-pin"
   backlog item 2c) or building a way to detect non-generalizing answers.
