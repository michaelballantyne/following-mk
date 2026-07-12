# Design survey: additional information sources for follower views

Michael's direction (2026-07-12): what other sources of information could
constrain the search, composable as additional followers? This note
enumerates candidates, each assessed for (a) expressibility as a /d
relation in the current architecture, (b) expected refutation/forcing
density against the *converged* stream (the loop has converged on rember
at 312,236 unify(main); new cuts need new information, not more
canonicity syntax), (c) related-work anchor, (d) cost to prototype.
Companion to the untyped-factoring experiment (running now) and the CDCL
evaluation note (`2026-07-12-211500-cdcl-evaluation.md`).

## What makes a good view (criteria, from the rung-1..4c record)

- **Soundness class.** Three classes, worth naming once:
  - **A: spec-entailed** — semantically necessary given examples + declared
    types (EX, TY). Never loses any answer.
  - **B: minimal-answer-preserving canonicity** — cuts candidates for which
    an equivalent-or-smaller candidate is also enumerated (NV/rung 4a).
    Loses only redundant answers.
  - **C: answer-class restriction** — a commitment the user opts into
    (R1/R2 structural recursion; Myth makes the same one). Loses answers
    outside the class, by design.
- **Marginal-against-installed-stack is the only number that counts**
  (hardened rule from rungs 4b/4c: residue estimates against thinner
  stacks do not transfer).
- **Density mechanism**: a view pays either by *refuting* families the
  stack misses or by *forcing* (propagation). Forcing has been rare —
  only TY produced it, and only weakly under the typed generator.

## Candidates, ranked

### 1. Symbolic / parametric examples (class A) — cheapest, try first

Replace or augment concrete I/O examples with examples containing fresh
logic variables under `=/=`/`absento` constraints: e.g. for rember,
`(rember e (cons x (cons e (cons y '())))) = (cons x (cons y '()))` with
`(=/= x e)`, `(=/= y e)`, `symbolo`/`numbero` pinning as needed. One
symbolic example denotes a whole family of concrete ones, and — unlike
concrete examples — cannot be satisfied by constant tricks, so it refutes
strictly more per example. It also directly supplies the missing
same-`l`/different-`e` information (backlog: the current suite cannot
refute e-independence at all).

Expressibility: trivial — these are just `evalo`/`evalo/d` goals with
vars; zero new machinery. Both project identities untouched.

Risk: symbolic inputs *reduce* determinacy inside the follower — `=` on a
symbolic number stalls where a concrete one commits, so EX's forcing gets
weaker even as its refutation gets stronger; net sign unknown. That makes
it a real experiment, and a nearly free one.

Related work: parametric/parameterized examples are folklore in the PBE
literature (SMyth's "input-output *constraints*" generalize examples the
same way); in mk this is just goals-with-vars.

### 2. Abstract-domain example views (class A) — the Blaze idea, relationalized

Run the candidate not only on concrete examples but on *abstracted*
examples in a small domain, through a second, tiny relational
interpreter: identity #1 applied to an abstract semantics ("write the
abstract interpreter once as a relation; the follower runs it in
whatever direction determinacy allows").

- **Length domain**: rember examples abstract to length equations;
  append: `len(out) = len(l1)+len(l2)`; duplicate: `len(out) = 2·len(in)`.
  The abstract interpreter is `eval-lengtho/d`: cons is `succ`, match
  splits `zero/succ`, recursive calls thread abstract values, numbers/
  elements are erased.
- **Multiset/bag domain** (finer): rember's spec *is* a bag equation
  (out = in minus all e's); duplicate: every element's count doubles.

The honest tension, discovered while thinking this through: an abstract
domain pays exactly where abstraction makes evaluation *more*
deterministic. For duplicate and append (element-blind programs), the
length interpreter is fully deterministic — dense forcing (out-length
2n should *force* the double-cons shape early). For rember, the first
`(if (= x e) ...)` on an erased element stalls the length view — unknown
branch. Blaze resolves this with an abstract *join* (take both branches,
merge states); pure relational composition has no join — a `conde/d`
over both branches just stalls. Adding a hand-written join per domain is
exactly the abstract-transformer authoring burden identity #1 exists to
avoid. Two sub-options if the joinless version underwhelms:
  (a) interval/bound domains where "either branch" still yields a usable
      inequality (len(out) ≤ len(in) for rember) — inequalities over
      unary naturals are expressible as relations (`leo/d`);
  (b) accept task-dependence: deploy the length view only where the
      concrete examples reveal a deterministic length law (checkable
      automatically from the examples before search).

Cost: a new small interpreter (~half of type-ofo/d's size), abstract
examples derived automatically from concrete ones (no user burden).
Related: Blaze (POPL 2018) abstract FTA + CEGAR; iterative
forward-backward abstract interpretation for synthesis
(arXiv:2304.10768). Priority: high — first genuinely *new* information
channel since types, and the first candidate view with a shot at dense
forcing on element-blind subproblems.

### 3. Coverage / adequacy view (class B) — needs view-to-view communication

Claim: in a minimal answer, every branch (match clause, if arm) is either
exercised by at least one example's evaluation or is the canonical
minimal filler for its position. A candidate with an unexercised branch
containing non-minimal structure is refutable (an equivalent smaller
candidate exists). This is the one family the current stack provably
cannot see: EX is blind to unexecuted branches (dynamically dead code),
TY only kills it if ill-typed, size bound only caps it. The 4c
post-mortem found the completed no-op wrappers live *above* the answer
bound on rember — but that is a fact about rember's examples (which
exercise everything early); branchier tasks/specs will move the family
below the bound.

Expressibility: this is the architecturally interesting one — coverage is
a property of *EX's evaluation traces*, so the evalo/d view must reify
which branches it took into store terms a second view can read. Views
communicating through the shared store is exactly identity #2's promise,
so far exercised only via the substitution on `q` itself. Prototype:
extend eval-expo/d with an optional trace argument (a logic term the
evaluation unifies branch-markers into), and a `coveredo/d` view
conjoining over the per-example traces.

Cost: moderate (touches the follower interpreter's signature). Related:
Myth's trace-completeness/adequacy, Trio's block-based pruning.
Priority: medium now, high the moment benchmarks get branchier; also
worth doing *as* the architectural probe of store-mediated view
composition.

### 4. Relevance / dataflow view (class C) — revisit under the untyped generator

Rung 4b (syntactic occurso) measured NEGATIVE against the typed stack,
but the entry explicitly kept it for the untyped scenario: with typing
gone from generation, variable use is much less constrained, and
Myth-style relevance (every parameter dataflow-reaches the output) should
cut families the untyped stream newly contains. Blocked on today's
untyped-factoring results; if untyped+TY becomes a standard config, rerun
4b's ablation there before building the stronger dataflow version.

### 5. Property specs / algebraic laws (class A) — zero machinery, user-supplied

Laws like `rember(e, append(a,b)) = append(rember(e,a), rember(e,b))` or
idempotence, as additional follower goals over symbolic inputs (combines
with #1). No new machinery — more `evalo/d` conjuncts. The cost is user
burden (identity #2 explicitly welcomes extra relations, but the
research story is stronger when specs are derived, not hand-fed).
Priority: low as research, trivially available when a benchmark needs it.

### 6. Recursion-trace consistency (SyRup/Burst) — mostly subsumed here

Burst's angelic recursion and SyRup's traces solve a problem the
relational substrate doesn't have: mk unfolds recursive calls concretely,
so trace consistency is automatic. The part *not* subsumed — sharing
recursive-call results across candidates — is memoization/tabling, i.e. a
search-strategy concern (first-order rep / explicit search), not a view.
Recorded so we stop re-deriving it.

### 7. Learned/statistical priors (Probe, neural-guided CLP) — scheduler-side

Grammar statistics or learned policies order the search; they are not
/d views and belong to the explicit-search work (cost-frontier priority
queue), where a prior is just the cost function. Out of scope for view
composition; noted so the boundary is explicit.

## Recommendation

Order of attack: **#1 symbolic examples** (nearly free, richer-spec item
already in backlog), then **#2 length-domain view on duplicate/append**
(new information channel, dense-forcing hypothesis, join tension to be
measured not debated), then **#3 coverage** when benchmarks branch more
or when we want the store-mediated-composition demonstration. #4 waits
on the untyped results landing now.
