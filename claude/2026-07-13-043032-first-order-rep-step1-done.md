# First-order rep step 1 DONE: conde/d site registry, behavior-neutral

Implemented step 1 of the first-order-rep migration
(`...-200500-first-order-rep-design.md`, map in
`...-042503-first-order-rep-step1-implementation-map.md`): a static registry
of every `conde/d` call site, keyed by the label the depth-tally already
computes, populated by an idempotent unify-free insert when each site first
evaluates.

## Change (`following.scm`)

- `*conde/d-registry*` hashtable + `register-conde/d-site!` (near the
  depth-tally tables, ~`:174`). Value = list of per-clause fresh-var
  (env-vector) arities. Idempotent; a fallback-label collision with a
  *different* clause shape errors rather than silently overwriting (the one
  correctness hazard the map flagged). NOT cleared by `reset-depth-tally!` —
  the site inventory is per-program, not per-run.
- `conde/d` macro: computes `env-arities` at expansion time
  (`(length (x ...))` per clause) and wraps the existing template in
  `(begin (register-conde/d-site! label 'arities) <original>)`. The live
  closure evaluator is otherwise untouched — registration is a side-table
  only, so step 1 is pure infrastructure.

## Validation (the whole point of doing it as its own increment)

- **Byte-identical counters**: `rember-full-id-tv2` totals **unify-main =
  2,615,131** — exactly the rung-3 note's recorded baseline; per-level
  counters and the canonical rember answer unchanged. This is the decisive
  neutrality proof (registration does zero unifications).
- **Full suite green**: `test-all.scm` 120/120; `wave2b-property-gates`
  61/61.
- **Registry populated**: a one-shot follower run registers 24 sites, e.g.
  `"views.scm:433" -> (0 0 0 2 4 5 2)`, `"views.scm:116" -> (0 0)` —
  label → per-clause env-arities, exactly the substrate step 2's
  `(disj site-label env)` nodes will index.

## Next (step 2, not started)

Reify `conj/d-run`'s closure worklist into `(conj st pending soft hard)`
nodes + an interpreter loop over the registered constructors; verify
byte-identical counters again (same tv2 == 2,615,131 check). Risk per the
design note: interpreter dispatch vs Chez closures could eat constant-factor
gains — step 2 is allowed to be ~neutral; the wins are steps 3–4 (store-
version fast path, explicit scheduler). NOTE for step 2: to hold the
constructors the interpreter invokes, registration will need to capture the
runtime clause constructors (they close over `unsound-fail-depth`), not just
the static arities — extend the registry value then; the label key and
collision guard stay.
