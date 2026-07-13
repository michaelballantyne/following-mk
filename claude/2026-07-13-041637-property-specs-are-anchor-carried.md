# Property/relational specs are anchor-carried — the wave-2 flagship was confounded

Wave-2b (backlog item 2b) built the property-spec suite the last session
promoted as "the direction that differentiates vs Burst/Trio/SMyth."
Building it as a **controlled experiment** — property-only vs anchor-only
vs property+anchor — instead of just adding more property arms overturned
the wave-2 headline. Short version: **on every task tried, a single ground
anchor pins the answer at least as well as the relational property, and far
cheaper; the property is pure follower overhead.** rev-involution's wave-2
success was carried by its ground anchor, not the involution property.

All arms: untyped generator + full view stack (R1 base-case, R2 decreasing-
recursion, TY type-ofo, NV non-vacuous), ce1, `*main-unsound-depth* 1000`,
per-view `tally/d`. Degenerate landscape locked first in
`experiments/wave2b-property-gates.scm` (all gates green): the canonical
body satisfies property+anchor; every cheap degenerate (append return-l/
return-s/const-(); rember identity/head-only) satisfies the PROPERTY ALONE;
the single anchor kills each degenerate.

## Results

| task | arm | answer | bound | unify(main) | unify(follower) | wall-ms | EX ref/force |
|---|---|---|---:|---:|---:|---:|---|
| append | assoc-only (property, no anchor) | **`s` degenerate** | 11 | 4,958 | 98,965 | 55 | — |
| append | anchor-only | **canonical** | 35 | 98,084 | 2,730,767 | 2,201 | 105/258 |
| append | property+anchor | canonical (same) | 35 | 201,254 | **174,566,989** | **83,731** | 205/2610 |
| rev | anchor-only | **canonical rev-acc** | 35 | 61,454 | 3,906,396 | 2,651 | 50/203 |
| rev | property+anchor (wave-2) | canonical (same) | 35 | 149,241 | ~71,400,000 | — | — |
| rember | idem-only (property, no anchor) | **`l` identity** | 15 | 3,797 | 126,662 | 52 | — |
| rember | anchor-only | head-wrap degenerate | 35 | 30,031 | 785,444 | 515 | 10/49 |
| rember | property+anchor | head-wrap (same) | 35 | 54,366 | 4,249,035 | 2,049 | 42/634 |

depth-cut 0 everywhere. Property+anchor vs anchor-only, same answer & bound:
- append: unify(main) **2.05×**, follower **63.9×**, wall **38.0×**.
- rev:    unify(main) **2.43×**, follower **~18.3×**.
- rember: unify(main) **1.81×**, follower **5.4×**, wall **4.0×** (same *degenerate*).

## Three findings

**1. Property-only under-pins → smallest degenerate, every time.** append
assoc-only returned `s` (return-second-arg) at bound 11; rember idem-only
returned `l` (identity) at bound 15. Both properties have a *candidate-
dependent* RHS (`app(app(a,b),c)=app(a,app(b,c))`, `f(f(l))=f(l)`), so they
are satisfied by projections/identity/constants — proven in the gates. This
extends the wave-2 "weak spec admits degenerates" finding (W2a/W2b) to
relational properties. Crucially, involution `f(f(X))=X` looked *stronger*
(RHS fixed to the known input) — but see finding 3.

**2. The anchor determines the answer; the property changes nothing about
which program is found.** Where the anchor pins (append: canonical; rev:
canonical rev-acc), property+anchor returns the identical program at the
identical bound. Where the anchor under-pins (rember: one anchor
`(rember 5 (6 5))=(6)` admits the "wrap head of l in a one-element list"
degenerate `(cons (match l ['() V] [(cons a d) a]) '())`), property+anchor
returns the **same degenerate** — idempotence did NOT rescue the
under-pinned anchor.

**3. The property is pure follower overhead.** The cost is the entangled
nested evaluation: the candidate is applied 2–3× per example (rev∘rev,
app∘app, rember∘rember), and the follower re-runs the interpreter through
all of it. The `tally/d` EX force count balloons — append 258→2610, rember
49→634 — but this forcing re-derives structure the anchor already forced;
it produces no additional *pinning refutation*, so the answer is unchanged
while follower unify explodes (append 64×). The interpreter genuinely runs
`rev∘rev` composed with no inverse semantics — identity #1 is real — but
here that capability is unprofitable: it costs 18–64× more than the forward
ground anchor that pins the same function.

## The correction to the wave-2 headline

The decisive arm is `rev-anchor-only-id-ty.scm`: the ground anchor
`(rev (5 6) ()) = (6 5)` **alone**, no involution examples, synthesizes the
TRUE accumulator-reverse at bound 35 for 61,454 unify(main) / 3.9M follower
— vs 149,241 / 71.4M for the wave-2 involution arm at the same bound. So the
wave-2 claim "rev-involution is the flagship demonstrating property specs
pin the answer" was **confounded**: the anchor did the pinning, the
involution property added ~18× follower cost and pinned nothing extra. No
task tried supports "property specs are strongly-pinning" — a single ground
example wins on all of them.

## Reframed research question

The real differentiator for the relational substrate is **not** "property
vs example for a function that has cheap ground examples" — the forward
ground example always wins there. It is tasks where a pinning ground
example is *structurally unavailable*:
- **true relation synthesis** (no functional I/O to write a ground anchor for);
- **run-backward-only / partial-input specs** where the forward ground point
  doesn't exist or doesn't pin;
- **specs over a domain with no single ground witness** — e.g. Michael's
  Peano-length idea, `length(append(a,b)) = append(length(a),length(b))`
  with `length` producing a unary list and `+`=append at the object level:
  the object program must *construct structured output*, and this is
  multi-function (co-synthesize length, or fix append) so no single forward
  I/O pair pins it.

append/rember/rev are all ordinary forward functions with cheap ground
examples, so none of them is in the profit regime. Identity #1 stands as a
*capability* (write once, run entangled, no inverse semantics); it is not
yet shown to be *profitable*. Finding a task where it is profitable is the
next question — and it is a task-selection problem, not a view/engine
problem.

## Artifacts

- Gates: `experiments/wave2b-property-gates.scm` (green).
- append: `append-{assoc-property,anchor-only,assoc-only}-id-ty.scm`.
- rember: `rember-{idem-property,anchor-only,idem-only}-id-ty.scm`.
- rev:   `rev-anchor-only-id-ty.scm` (the decisive comparator).
- Raw run logs in this session's scratchpad (not committed).
