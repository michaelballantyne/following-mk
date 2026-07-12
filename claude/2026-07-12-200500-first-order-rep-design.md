# Design note: first-order representation of the /d search

The top infrastructure item (backlog Now). What it must serve, ranked
by today's evidence, and a concrete shape for it. Design thinking only
— no code yet; written so the next session can start implementing.

## What it is for (and one thing it no longer needs to fix)

1. **The per-fire rebuild constant.** ce1 profiling showed per-trigger
   cost is flat but large (~240–7,300 unify per main-conde entry
   depending on throttle/task): every fire re-enters closure chains
   and re-runs guards from scratch. With pure-Andorra firing now known
   to be *correct* in the enumerative regime, this constant is the
   entire overhead story.
2. **Memory sharing/retention.** The (pre-view) enumerative OOMs came
   from per-live-state F-cells retaining closure environments. An
   explicit node can share structure across states and drop what a
   closure environment can't.
3. **Schedulability.** The explicit-search direction needs inspectable
   frontier nodes for a priority queue; closures are opaque.
4. **Debuggability + provenance** (the original TODO motivation; and
   the natural substrate if mkcdcl-style learning ever happens).

NOT needed: fixing resume-chain growth — falsified today, chains stay
at 3–4 items. The rep can assume short worklists.

## Shape: defunctionalize the /d layer only

The follower's /d search is the easy defunctionalization target: it is
single-answer (inf/d never splits), has exactly one conjunction
combinator (`conj/d-run`'s worklist), and every `conde/d` call site is
statically known to the macro. mk's own stream machinery stays
untouched — the fork remains three patches.

Node types (a sketch):

- `(disj site-label env)` — a conde/d occurrence: `site-label` indexes
  a global registry (built at macro expansion: label → guard/body
  constructors); `env` is a vector of the captured logic vars. This is
  the classic defunctionalization pair, and the macro already computes
  the label (the depth-tally work).
- `(conj st pending soft hard)` — `conj/d-run`'s state made data.
- `(guard-eval site clause-idx result stamp)` — a clause guard's last
  evaluation result, stamped with the store version it was computed
  against (subst-map + constraint-store identity, as in the fixpoint
  note's change detection).

The /d evaluator becomes an interpreter loop over these nodes. A
re-fire with an unchanged store is then O(1) (compare stamps, return),
and with a changed store re-runs only clause guards — with the option
later of per-clause stamps so unchanged clauses skip too. That is the
"save guard progress across triggers" item from the old TODO, which
closures made impossible.

## What deliberately stays out of scope

- **Var-watching** (re-run only guards whose variables changed): the
  old TODO's analysis stands — there is no small cheap watch set,
  because any var in any constraint of any guard can matter. Store
  version stamps give the coarse version at near-zero cost; measure
  before wanting more.
- **Replacing mk's outer search**: separate item. But the rep is what
  makes it possible — an enumerative driver owning a frontier of
  (state, follower-node) pairs, firing followers by schedule rather
  than by conde hook, with ID as the degenerate case and cost-frontier
  priority queues as the interesting one.

## Migration plan (increments, each testable against the tv suite)

1. Registry + labels: extend the existing conde/d macro to register
   guard/body constructors per site (labels exist already).
2. Reify the conjunction: replace conj/d-run's closure worklists with
   nodes + interpreter; verify counters identical on tests + tv2/tv3
   (the whole suite is deterministic — byte-identical counter output
   is the regression test).
3. Add store-version stamps; measure the no-change fast path on ce1
   enumerative runs (prediction: large — most fires see few changes).
4. Only then: the explicit scheduler.

Risks: interpreter dispatch vs Chez's fast closures could eat the
constant-factor gains at step 2 (measure before step 3; steps 3–4 are
where the wins are, step 2 is allowed to be ~neutral). Printability
arrives at step 2 for free — `print-follower-tree!` replaces guessing
at closure contents.
