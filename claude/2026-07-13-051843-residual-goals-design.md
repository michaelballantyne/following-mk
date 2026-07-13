# Residual goals: the first-order representation of the /d search

Design note, agreed with Michael in discussion 2026-07-13. **Supersedes**
the defunctionalization plan in `2026-07-12-200500-first-order-rep-design.md`
and retires its step 1 (the `*conde/d-registry*` hashtable, implemented and
validated in `...-043032-first-order-rep-step1-done.md`, removed again in
the commit that adds this note — see "What happens to step 1" below). The
motivations from the old note stand unchanged; the representation is
redesigned from the semantics up rather than transcribed from the closure
implementation.

## The idea

**A suspended follower is a residual goal.** The follower's state between
triggers is a goal term — the parts that finished deleted, the parts that
failed pruned, the blocked parts still sitting there as syntax. Evaluation
is *settling*: rewriting a goal against the store as far as determinacy
allows.

```
settle : Goal × State × Depth → #f  |  (Goal′ × State′)
```

`#f` means the candidate is refuted. `⊤` (the empty conjunction) means
fully determinate success. Anything else is a suspension, and *which kind*
is a visible property of the residual term, not a type tag. The four-way
`inf/d`, the resume closures, `conj/d-resume`, and the hard-suspended
record all collapse into "a goal term and a store":

| today (`inf/d`)                  | residual-goal form                          |
|----------------------------------|---------------------------------------------|
| `#f`                             | `#f`                                        |
| bare state (singleton success)   | residual = ⊤, extended state                |
| `(state . resume)` (soft)        | residual contains a `g-disj` (store-blocked)|
| hard-suspended record            | residual contains a `g-call` (budget-blocked)|

Lineage, for orientation: this is the CCP/AKL configuration ⟨store, pool of
suspended agents⟩, Oz-style residuation, and partial evaluation's residual
program, with settling as propagator quiescence. The Andorra heritage of
the /d layer (determinacy-first, committed choice) is what makes the
representation this small.

## The datatype (all of it)

```scheme
(define-record-type g-==   (fields lhs rhs))           ; + leaves for =/=, absento,
                                                       ;   numbero, symbolo
(define-record-type g-conj (fields goals))             ; '() = ⊤
(define-record-type g-disj (fields alts))              ; alt: guard, body, alive?, stamp
(define-record-type g-call (fields name build args))   ; build : args → Goal
```

Naming (Michael): `g-conj`/`g-disj` match the codebase's `conj/d*`/`disj/d`
vocabulary and the mk lineage. One nuance for a source comment: `g-disj` is
*committed choice* — guarded alternatives that wait and commit, never a
search split. That is the same semantic license `conde/d` already takes
with the name "conde", so it is house style, not a new confusion.

There is **no fresh node**: variable allocation happens at construction
time, so binders exist only in source, never at runtime. (set-var-val! is
already disabled on the /d path, so scope-less allocation loses nothing.)

There is **no tally node** decided yet: `tally/d` becomes either an
optional label field on nodes or a thin wrapper node — an open question
below; either is easy.

## Two layers: construction and runtime

**Construction layer (Scheme).** Relations are ordinary Scheme functions
that return Goals. This preserves the staging the views rely on —
`tyenv-lookupo/d` recursing over a Scheme assoc list and *generating* goal
structure stays exactly as it is. The `conde/d` macro shrinks to "build a
`g-disj` whose alternatives pair the guard conjunction with the body
conjunction"; `fresh/d` allocates vars and returns a `g-conj`.

**The recursion knot.** Recursive self-reference must go through `g-call`,
whose `build` field is the relation's Scheme function — a closure, but a
*static* one: the pristine generator for the body, capturing nothing
dynamic. (Per the closure-at-the-call-boundary discussion: the schedulable
metadata — name, args — lives on the node; the closure holds only the
expansion.) All state that changes between triggers is data. The old sharp
corner "recursion not through conde/d diverges under fresh/d" becomes a
construction-layer rule — *recursion must go through g-call, or
construction itself loops* — statable, checkable, and documentable.

**Runtime layer (data).** Goals are the records above; `settle` interprets
them; residuals are Goals. Everything the engine holds between triggers is
data.

## The semantics on a postcard

```
(g-== t u)       unify. ⊤ or #f. Never residual.
                 (constraint leaves likewise: commit into the store or fail)

(g-conj gs)      settle children in order, threading the state; drop ⊤s;
                 #f if any child fails. If the store grew during the pass,
                 sweep the leftovers again (quiescence). Residual:
                 (g-conj leftovers), spliced flat into any parent conj.

(g-disj alts)    settle each live alt's guard speculatively from the
                 current base store.
                   guard fails → alt dies, PERMANENTLY (alive? := #f)
                   none live   → #f
                   one live    → COMMIT: adopt its state, then settle
                                 (g-conj guard-residual body)
                   several     → residual (g-disj survivors); state unchanged
                                 and speculative guard states discarded

(g-call r args)  budget left on this path? instantiate (build args) and
                 settle at depth+1. Otherwise leave the call residual —
                 an unexpanded g-call IS hard suspension.
```

The determinacy invariant — commit only when exactly one alternative
survives — is one visible line. The sole-survivor rule with retained guard
obligations (from the guard-robustness work) falls out as
`(g-conj guard-residual body)` in the commit case.

## The flatness invariant

The live residual is always a **flat conjunction of suspensions**:

```
residual  =  (g-conj s₁ … sₙ)               n ≥ 0; n = 0 is ⊤
sᵢ        =  g-disj with ≥2 alive alts       (store-blocked)
          |  unexpanded g-call               (budget-blocked)
```

Nothing else can be a live conjunct: `g-==` and constraint leaves never
survive settling; nested `g-conj` splices into its parent; a `g-disj` with
0 alive alts is failure and with 1 is a commit, so a residual disj has ≥2
by construction; a commit splices its guard residual and body residual
upward, so even the leftovers of a committed guard flatten into the
top-level pool.

The governing rule: **determinate progress flattens; only speculation
nests — and speculation is frozen source, not residual.** The follower
retains only information it has committed to, and committed information
always splices to the top. Inside a residual `g-disj`, the alternatives are
pristine source (guard + body), not partially-settled worlds.

So the shape is flatter than CNF in the live part: conjunction of
choices-and-calls, where the disjuncts are whole frozen subprograms rather
than literals. The picture is the CCP configuration: a store plus a flat
pool of suspended agents, each blocked at a choice or a call.

Assertable data invariants for the test suite:
- the residual conjunction is ⊤-free, ==-free, constraint-free, conj-free;
- every residual `g-disj` has ≥ 2 alive alternatives;
- `g-disj` and `g-call` appear only as top-level conjuncts of the residual;
- `alive?` flags are monotone (never resurrect).

## Guard progress policy: recompute uncommitted, keep post-commit

Uncommitted alternatives' guard progress is **not** kept across passes.
Two reasons, one empirical and one semantic:

**Parity — today's engine already discards it.** In `conde/d-runtime`, a
nondeterministic outcome suspends as a thunk that re-enters the whole
conde/d from scratch; all guard progress on uncommitted alternatives is
thrown away today. The only guard progress that persists is the
*post-commit* obligation — the sole survivor's unfinished guard joins the
soft worklist alongside the body. The residual design keeps progress in
exactly the same place (the commit rule splices `guard-residual`) and
recomputes exactly where today recomputes. Nothing is lost relative to the
current engine.

**Soundness asymmetry — failure is monotone, success is not.** The base
store only grows along a candidate's lifetime. A guard that fails against
S fails against every S′ ⊇ S (solutions only shrink), so the `alive?` flag
is a sound permanent memo. But partial guard *success* is speculative
bindings a later base extension can contradict; cached success must be
re-validated against the new base, and with triangular substitutions
re-validation is re-running — there is no cheap rebase of a speculative
extension onto a grown base. Cache death; recompute life.

Corollary: the alive-flag memo is sound only because failure is real
failure. It would be broken by `*unsound-fail-depth*` — a second,
principled reason for the removal the backlog already wants. If profiling
ever shows genuinely expensive guard recomputation, the escape hatch is
per-alternative worlds with rebasing; guards are by design the shallow
determinacy tests, and the stamp fast path (below) skips them entirely in
the common no-change case, so this is not expected to matter.

## Incrementality: stamps and alive flags

- Each node carries a **stamp**: the store version (subst-map + constraint
  store identity, as in today's `changed?` test) it last settled against.
  Unchanged store ⇒ compare, return — the O(1) re-fire, which the ce1
  profiling says is the common case and the whole per-fire rebuild story.
- Each alternative carries the monotone **alive?** flag — dead alts are
  free forever.
- Speculative guard states live only *within* one settle pass; nothing
  stale survives a trigger.
- Cheap things (guards) are recomputed on change; expensive things
  (committed body work — evalo/d unfoldings) persist as residuals in the
  top-level conjunction. That is the right line: recompute where it's
  cheap, retain where it's expensive.

## Budget semantics (the one decision to nail deliberately)

Budget counts **expansions per path per settle pass**: settling threads a
depth, `g-call` expansion consumes one level, and a call left residual is
exactly an out-of-budget frontier. Each trigger settles with a fresh
top-level budget, matching today's rule that only top-level re-fires
refresh depth while refining resumptions do not. The convergence argument
(hard-suspend vs resumable-suspend, from the sharp-corners item) becomes a
statement about a visible parameter instead of an emergent property of
closure nesting — fold it into the guarantees doc when written.

Possible bearing on backlog 1b: recompute-with-fresh-budget naturally
deepens the frontiers *inside* a residual `g-disj`'s alternatives on each
trigger, which is the single-frontier behavior R2T's OR-of-suspensions
couldn't get. To check, not to assert.

## What this buys, per the original four motivations

1. **Per-fire rebuild cost** → stamps + alive flags; unchanged store is a
   pointer comparison.
2. **Memory** → residuals are persistent trees sharing substructure; no
   captured environments, no per-live-state F-cells retaining closures;
   speculative states are pass-local.
3. **Schedulability** → the frontier for the explicit scheduler is
   literally the residual `g-call`/`g-disj` nodes, carrying name, args,
   and depth. Child ordering inside `g-conj` becomes a pluggable policy —
   backlog 1b's "cheap refuters before evalo/d" as a policy, not surgery.
4. **Printability/provenance** → residuals S-expr trivially
   (`print-follower-tree!` becomes honest); tally labels become fields;
   future provenance (mkcdcl-style) annotates nodes.

Main-search integration is untouched: `follower`, trigger throttling,
watch-size, the ID harness all stay; this swaps only what a follower *is*
between triggers.

## What happens to step 1

The `*conde/d-registry*` hashtable, its registration in the `conde/d`
macro, and its three gates (`tests/conde-d-registry.scm`) are **removed**
in the commit that adds this note. They were aimed at the superseded
`(disj site-label env)` shape, whose string-keyed indirection this design
rejects (nodes should be self-contained; a definitions reference is a
direct pointer/closure, not a source-location key). What survives:
- the **label** (source-location string the macro computes) becomes
  `g-call`'s / `g-disj`'s name field for tally and printing;
- the **byte-identical tv2 baseline** (unify-main = 2,615,131,
  `...-043032-...`) remains a validated reference point for the old
  engine, useful during migration;
- the methodology lesson: behavior-neutral increments are provable
  cheaply; re-architectures need differential testing instead (below).

## Migration plan

1. **Build the runtime layer in parallel**: records + `settle` in a new
   file (`residual.scm` or similar), leaving the closure engine untouched.
2. **Port one small view** (base-case-patho/d is the natural first) by
   hand to goal-constructing form; drive both engines on the same
   candidates.
3. **Differential harness**: compare *decisions* — refute / commit /
   suspend per trigger — and final answers across engines on the test
   suite and one ID benchmark. Byte-identical counters are the wrong bar
   for a re-architecture (evaluation order differs in the small); decision
   equivalence is the right one and is stronger than counter equality
   anyway.
4. **Port the conde/d / fresh/d macros** to construct nodes; ports of the
   remaining views then come for free (their Scheme bodies are unchanged).
5. **Cut over**; delete the closure engine (`inf/d`, `case-inf/d`,
   `conj/d-run`, `conj/d-resume`, hard-suspended); re-baseline counters as
   the natural new ones (settle passes, expansions, commits, alt deaths,
   stamp hits). Assert the flatness invariants in the suite.
6. **Then** steps 3–4 of the old plan land where the wins are: the stamp
   fast path is already built in; the explicit scheduler reads the
   residual frontier directly.

## Open questions

- **Tally placement**: label field on every node vs a thin `g-spy` wrapper
  node. Field is simpler; wrapper keeps the datatype minimal. Decide at
  port time.
- **Budget interaction with guards containing calls**: guards are
  recomputed per pass with the pass's budget; confirm this reproduces
  today's suspend-depth accounting on the tv suite (differential harness
  will tell).
- **Counter mapping for the notebook record**: decide the new
  counter set before cut-over so pre/post comparisons in old entries stay
  interpretable (one bridging table in the cut-over notebook entry).
- **Does the R2T/1b rescue fall out?** Flagged above; measure once the
  engine runs, before touching the unified-view design.
