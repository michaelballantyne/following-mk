# First-order rep, step 1 — implementation map (registry + per-site constructors)

Terrain map for the now-top-priority item 3 (promoted by the
`...-041925-reflection...` re-prioritization). Design note:
`...-200500-first-order-rep-design.md`. This is the *step 1* map — registry +
per-site guard/body constructor registration, keyed by the label that
already exists — with file:line anchors so the next session implements
without re-reading the whole engine. All refs are `following.scm` unless
noted; line numbers current as of this entry.

## Advisor framing (read before touching code)

Step 1 is **pure infrastructure and must be behavior-neutral**: it *adds* a
side-table description of each `conde/d` site in parallel to the live
closure evaluator, and changes nothing the evaluator runs. The whole value
of doing it as its own increment is the cheap, decisive regression proof:
**tv2/tv3 counter dumps must stay byte-identical.** If any counter moves,
step 1 did something it shouldn't. The risky part (swapping the interpreter
to run off the registry) is step 2 and is explicitly allowed to be
~neutral on speed; the wins are steps 3–4 (store-version fast path,
explicit scheduler). Don't let step 1 scope-creep into step 2.

## The pieces

**1. `conde/d` macro** — `following.scm:484-542`; runtime `conde/d-runtime`
`:544-578`. Each clause expands to a `(guard-stream . body-thunk)` pair
(`:522-542`): guard = `(conj/d* g ...)` through the depth thunks; body =
`(lambda (suspend-depth) ... (conj/d* b ...))`. Captured fresh vars
`(x ...)` (`:533`) are the `env` the design note's `(disj site-label env)`
node references. **This clause pair is exactly "the guard/body constructors
per site."**

**2. The label ("exists already")** — `following.scm:489-521`. Preferred
`"basename:line"` from the syntax source object (`:510-520`), unique per
call site; fallback `"conde/d?[op,...]"` from first-clause guard operators
(`:499-509`), which **can collide across distinct sites** — the one
correctness hazard for a keyed registry. Label is threaded to
`conde/d-runtime` as a literal (`:527`) and already keys three per-site
tables (`:152-172`, bumped at `:554`/`:478`, dumped by `print-depth-tally!`
`:177-203`). Reuse this same key.

**3. `conj/d-run`** — `following.scm:588-622`; `conj/d-resume` `:624-634`.
Closure worklist = 4 positional args `goals`/`soft`/`hard` + entry snapshots
`entry-C`/`entry-M` (`:589-590`) for the `changed?` fixpoint test. Core loop
`:591-622` (the note's `(conj st pending soft hard)` node: `pending`↔`goals`).
Not touched in step 1.

**4. `inf/d` is single-answer** — `following.scm:425-435`: four cases only
(`#f` / bare `state` / `(state . resume)` / `hard-suspended` `:432`). No
`mplus`, no stream pair — `conde/d` *commits* one clause. `case-inf/d`
4-way dispatch `:437-451`. `fresh/d` `:659-669` carries no label; feeds
straight into `conj/d*`→`conj/d-run` (`:642-657`).

**5. Counters (byte-identical invariant)** — defs `:108-136`; unify counters
in `mk/mk.scm:217-219,229-230` gated by `*in-follower-eval?*` (set/reset
around follower eval `:785,808`). `/d`-path increments: `*conde/d-counter*`
`:553`, `*==/d-counter*` `:689`, suspend/fail cutoffs `:477/:465`, fail/
singleton/non-singleton `:791/:795/:800,805`, productivity `:838-839`.
**Registration must perform zero unifications** — keep it pure table
insertion, or wrap in `without-unify-counting` (`:816-822`) if it must reify.

**6. Regression harness ("tv" = termination views)** — driver files under
`experiments/archive/`: `rember-full-id-tv2.scm`, `...-tv3.scm`,
`append-full-id-tv2.scm`, `duplicate-id-tv3.scm`. Commands (from headers):
- tv2: `./run.sh --check-follower-every 20 --timeout 850 experiments/archive/rember-full-id-tv2.scm`
- tv3: `./run.sh --check-follower-every 20 --timeout 400 experiments/archive/rember-full-id-tv3.scm`
- dup tv3: `./run.sh --check-follower-every 1 --timeout 600 experiments/archive/duplicate-id-tv3.scm`

  (paths confirmed present in `experiments/archive/`; tv4–tv6 also there.
  Note these are archived arms kept as deterministic regression fixtures —
  `test-all.scm` is the primary suite, tv2/tv3 the byte-identical check.)
Counter output comes from the overridden `run` macro `:365-392`
(`reset-counters!:369`, `print-counters!`/`print-view-tallies` `:383-385`;
format via `counter-descriptors :231-279`). Plus `test-all.scm` green and
the `/d` tests: `tests/{determinacy-goal-forms,guard-robustness,view-tallies,following-interpreter}.scm`.
Known determinism anchor: tv2 reproduces exactly 2,615,131 unify (rung3 note).

## Ordered checklist (step 1)

1. Add `*conde/d-registry*` hashtable near `:152-154`, keyed by the label
   string; value = per-site record { clause constructors = list of
   `(guard-ctor . body-ctor)`, clause count, env/fresh-var arity }.
2. Extend the macro (`:522-542`) to *also* emit a registration form
   installing the site's constructors under `#,label`. Keep the emitted
   guard/body closures exactly as today; the registered constructors just
   produce those same closures, parameterized by
   `unsound-fail-depth`/`suspend-depth`/`st`/`env`.
3. Record env-vector width (count of `(x ...)`) per site; no runtime var
   allocation change (`var scope` stays inside the emitted closure `:533`).
4. **Do not touch** `conde/d-runtime`, `conj/d-run`, `conj/d-resume`,
   `case-inf/d`, `inf/d`, `fresh/d`, or any counter increment.
5. Resolve fallback-label collisions (`:499-509`): choose registry
   semantics (append vs last-wins) so two sites sharing a fallback label
   don't silently overwrite. Annotation labels (`basename:line`) are safe;
   fallback is the risk — consider erroring on collision to force disjoint
   labels.
6. Regression: tests + `test-all.scm` green; tv2/tv3/dup counter dumps
   byte-identical; confirm no unify counters moved (the cheap proof of
   neutrality before step 2).

The registry is the substrate for step 2's `(disj site-label env)` nodes:
label indexes it, `env` is the `(x ...)` vector, stored constructors are
what the step-2 interpreter loop invokes in place of the live closures.
