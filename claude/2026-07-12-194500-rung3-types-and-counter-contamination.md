# Rung 3 (types) lands — and an instrumentation-contamination incident

## The incident first (methodological lesson)

The rung-3 subagent flagged that the committed rung-2 total (2.62M
unify-main) "did not reproduce" — it measured 21.7M on identical code.
The tell in its own data: **conde(main) was byte-identical (73,107)**
— same search, inflated counter. Root cause: the productivity-tally
fix earlier today made the tally reify the watched term per trigger,
and mk.scm's `reify` is *not unify-free* (constraint reification runs
subsumption checks that call `unify`). The before-snapshot ran outside
the in-follower flag (+19.1M counted as main), the after-snapshot
inside it (+2M as follower). The instrumentation polluted the metric
it feeds.

Fix: `without-unify-counting` (snapshot/restore the two counters)
around every instrumentation-only reification — the tally, the
`*sample-term-every*` hook, and `*print-follower-term*`. Verified:
tv2 reproduces exactly 2,615,131 again. Timeline audit: all numbers
in committed entries were measured pre-contamination and stand
unchanged; the only contaminated measurements were inside the rung-3
agent's session (its *relative* comparison remains valid). The
fair-search rung-2 probe (3,257,509) predates the contamination and
re-verifies identically post-fix — its "flat" conclusion stands.

Lessons recorded: (1) instrumentation that feeds a metric must be
excluded from that metric — reify especially is a hidden unify
consumer; (2) the debugging fingerprint "identical conde counts,
inflated unify" distinguishes counter pollution from behavioral
change instantly; (3) the subagent did exactly right by refusing to
trust an unreproducible baseline and comparing same-machine instead.

## Rung 3: type-ofo/d as the third view

`experiments/termination-view3.scm`: a /d type checker for the
restricted language (number/list/arrows-from-annotation; tyenv as
assoc; lookup as nested conde/d that stalls on hole names). Design
choice, documented as a search-space restriction: recognized
constructs only — unrecognized forms (nested letrec, foreign
applications) are refuted rather than skipped, since an always-live
"skip" clause would stall everything. All gates pass: accepts both
canonical bodies, refutes `(rember e a)` (number at list position —
the case rung 2 admits) and `(cons l l)`, stalls on holes. Suite: 42.

**Clean ID results** (rember, ce20, three views conjoined —
`experiments/rember-full-id-tv3.scm`):

| | rungs 1+2 | +types | Δ |
|---|---:|---:|---:|
| total unify(main) | 2,615,131 | 2,417,933 | −7.5% |
| total conde(main) | 73,107 | 69,694 | −4.7% |

Same canonical answer at 47; depth-cut 0 throughout. Savings
concentrate in answer-free levels; the answer level itself gets
slightly costlier (view overhead on survivors) — same shape as rung
2's, much smaller magnitude.

**First propagation signal of the project**: the type view produces
nonzero productive triggers (per-level 1/1/1/4/14/23/30/67/33 in the
agent's run) — type-*forcing* of holes, which the purely structural
rungs never produced and which examples structurally cannot produce
(many-to-one). Small in count, conceptually important: all three
mechanisms of the original design (refutation, forcing, composition)
are now observed working in one follower.

## Standing

Three composed views (evaluator optional, termination rungs 1+2,
types) in one follower, written independently, conjoined by fresh/d —
identity #2 exercised at n=3. The marginal returns are decreasing
(rung 2: 22×; rung 3: 1.08×) because rungs 1+2 already eliminated the
divergent mass and types overlap heavily with what evaluation refutes
on these small examples. The next big lever is not a fourth view but
the explicit-search / first-order-representation work (backlog Now),
where the same views plug into a scheduler designed for them.
