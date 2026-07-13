# Wave 2 results: bidirectionality-essential specs — the flagship is *property* specs, not weaker examples

Task 2. Three arms built to the design note
(`...-223500-wave2-bidirectional-design.md`), run under the untyped+TY
default stack, ce1, 240s, with per-view tally/d attribution. All arms
first passed the ground gates (experiments/wave2-gates.scm, 9/9).
Comparators are the concrete-example untyped+TY arms measured earlier
this session/the factoring session.

## Results

| arm | spec kind | answer | bound | unify(main) | vs concrete | unify(follower) |
|---|---|---|---:|---:|---|---:|
| rember-symbolic/ty | W2a symbolic examples | **degenerate** head-only | 39 | 103,054 | rember concrete 305,891 @47 | 5.0M |
| swap-partial/ty | W2b partial outputs | **degenerate** tail-return | 47 | 52,588 | swap concrete 446,949 @63 | 2.6M |
| rev-involution/ty | W2c property (rev∘rev=id) | **TRUE rev-acc** | 35 | 149,241 | rev-acc concrete 126,853 @35 | 71.4M |
| rember-symbolic/no-follower | W2a, no follower | none | — | infeasible >240s (died in bound 15) | — |

depth-cut 0 everywhere. Per-view tally at the answer level (refute/force):
- W2a: EX 32/354, TY 107/60, NV 6/31 (R1/R2 only stalled — no bump).
- W2b: EX 29/430, TY 103/86, NV 4/36.
- W2c: EX 138/1256, TY 201/105, NV 2/42.

## The dominant finding: weaker examples admit MORE degenerates, not fewer

Two of three arms returned a *smaller, wrong* program that the
bidirectional spec nonetheless satisfies — minimality-first ID caught
under-specification, exactly as it did for evens in wave 1, now in the
bidirectional setting:

- **W2a rember-symbolic** returned `(match l ['() l] [(cons a d)
  (if (= a e) d l)])` at bound 39 — a NON-recursive head-only remove.
  It satisfies all three symbolic examples because every one has `e`
  absent or at the *head* (examples (a) absent, (b)/(c) e = head).
  None requires removing an element from *deeper* in the list, so
  recursion is never forced. The built example set dropped the
  middle-`e` case the design's probe used
  (`(rember e (x e y)) = (x y)`); with only head/absent cases the
  spec is under-constrained.
- **W2b swap-partial** returned `(match l ['() l] [(cons a d)
  (match d ['() l] [(cons b dd) d])])` at bound 47 (< the full-spec
  swap answer at 63) — "return the tail," whose head is the input's
  second element = swap's known output head. The partial outputs
  pinned only the head, so a head-matching degenerate satisfies them.

The naive hope — "a symbolic/partial example denotes a family, so it
constrains more" — is **backwards for pinning the answer**: relaxing a
per-example constraint (symbolic elements, holed tails) admits *more*
programs, so under minimality-first search the first answer is a
degenerate unless the spec still forces the target's structure. What a
symbolic example *does* buy is killing constant-coincidence
(the reason it denotes a family), but that is orthogonal to forcing
recursion/structure.

## The real flagship: property specs (W2c), which ARE strongly pinning

**rev-involution succeeded cleanly**: `(rev (rev X '()) '()) = X` over
symbolic X (lengths 0/1/2) plus one ground anchor synthesized the TRUE
rev-acc canonical at bound 35 — the same bound and within 1.18× the
unify of the concrete-example arm (149,241 vs 126,853), with no
divergence despite the doubled evaluation depth (71.4M follower unify,
depth-cut 0). This is the identity-#1 demonstration the project wanted:
the **same** interpreter run forward-composed-with-itself, no
per-operator inverse semantics, no unevaluation — and it is exactly the
class enumerate-and-test cannot enter (you cannot check `rev∘rev=id` on
symbolic X by ground forward runs; the no-follower arm confirms the
main search alone is infeasible on such specs, dying in the first
bound).

The reframing this forces on the design note: the differentiating power
is **not** "symbolic/partial examples" (those weaken pinning) but
**universal/relational property specs** — a constraint quantified over
all inputs of a shape, which the interpreter can only discharge by
running in entangled directions. That is the sharp edge of identity #1,
and W2c is its first measured instance.

## Predictions, scored

1. W2a "refutation up, forcing down, feasibility retained": **feasibility
   yes; forcing PREDICTION WRONG.** EX forced heavily (354) — symbolic
   *elements* still leave list *structure* concrete, so evaluation
   forces structure; only the `(= a e)` numeric test stalls. And
   "refutation up" did not pin the answer — see the dominant finding.
2. W2b "first substantial EX forcing, weaker refutation, maybe
   infeasible": **forcing CONFIRMED** (430 EX forces from the known
   head); **weaker refutation CONFIRMED** (degenerate at 47); feasible
   (not infeasible — the head anchor plus TY/structure kept it bounded).
3. W2c "hardest; flagship if feasible; suspend pressure": **CONFIRMED
   on all counts** — feasible, true answer, and the 71.4M follower
   unify / doubled depth is the predicted pressure (stayed under the
   ceiling).
4. No-follower comparator infeasible: **CONFIRMED** — symbolic-rember
   no-follower died in bound 15 (no level completed).

## Consequences / backlog

- The wave-2 arms as built are a **methodology artifact**, not a clean
  benchmark suite yet: W2a needs the middle-`e` example (and generally,
  symbolic specs need an example that forces each structural case); W2b
  needs enough of the output pinned to force the recursion. Cheap fixes,
  worth doing before these arms count as solved tasks. Recorded rather
  than hot-fixed this session.
- **Property/relational specs are the direction that matters** for the
  Burst/Trio/SMyth comparison — promote a small suite of them
  (involution done; idempotence `rember e (rember e l) = rember e l`;
  `append` associativity; `length (append a b) = length a + length b`)
  to the next wave, since they are both strongly-pinning AND
  E&T-inaccessible. This is where identity #1 is defended.
- tally/d earned its keep: it distinguished "EX forces structure but
  the spec still under-pins" (W2a/b) from a genuine refutation win, a
  distinction unify(follower) alone cannot make.
