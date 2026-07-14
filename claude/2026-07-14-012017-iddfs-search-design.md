# Design: size-bounded iterative-deepening DFS as the per-level search

Design note (Michael's direction, 2026-07-14). Goal: replace the
per-level *fair-interleaving* search inside size-closed ID with a
depth-first search, keeping the size-frontier iterative deepening on top.
Hypothesis: DFS's lower per-node overhead (no interleaving round-robin,
far less suspended-thunk churn) cuts wall-clock, while size-frontier
iterative deepening preserves the minimality guarantee that makes the
current approach correct. Michael cares about wall-clock here.

## What we have now vs. what we want

Today's "size-closed ID" (`experiments/*-full-id-views.scm` via
`run-id`) is already iterative deepening on program size: `run-id`
re-runs `(run 1 (q) ...)` at increasing `*max-term-size*`, and
`main-conde-hook` (following.scm) fails any branch whose watched-term
size lower bound exceeds the current bound. But the *per-level* search is
still mk's fair interleaving: `conde` combines branches with `mplus*` →
`mplus`, and `mplus` (mk.scm:317) interleaves by swapping to the other
branch on every suspension. That interleaving is where the thunk churn
lives — the fair-search-plus-views sweep measured tens of GB allocated
per run (append ce1: 60 GB), most of it round-robin suspension thunks.

The `2026-04-12-search-order.md` note already identified size-ordered
iterative deepening as the right strategy and picked "Option 1:
structural max-term-size constraint + re-run at increasing n" — which is
exactly what's built. What was *not* revisited then: the per-level engine
is still interleaving. This note swaps it for DFS.

## The mechanism: one function, two lines

DFS is a two-line change to `mplus`. Fair (current):

```scheme
(define (mplus stream f)
  (case-inf stream
    (() (f))
    ((f^)   (lambda () (mplus (f)  f^)))    ; swap -> pull the OTHER branch first
    ((c)    (cons c f))
    ((c f^) (cons c (lambda () (mplus (f)  f^))))))
```

DFS (append order):

```scheme
(define (mplus stream f)
  (case-inf stream
    (() (f))
    ((f^)   (lambda () (mplus (f^) f)))     ; dive -> continue THIS branch, defer the other
    ((c)    (cons c f))
    ((c f^) (cons c (lambda () (mplus (f^) f))))))
```

The only change is `(mplus (f) f^)` → `(mplus (f^) f)`: force the first
stream's own continuation (`f^`) and defer the second branch (`f`),
draining the first branch depth-first before backtracking to the second.
This is the classic `mplus` vs `mplusi` distinction. It converts the
whole *leader* search order to DFS in one place, because `conde` (via
`mplus*`) and `bind`'s multi-answer case are the only disjunction sources
and both route through `mplus`.

**Scope of the change — why it's safe and small.** mk.scm is flat
top-level `define`s (no library/module wrapper), and the repo already
top-level-shadows `==` and `run` from following.scm. Redefining `mplus`
in a loaded file is picked up by `bind`/`take`/`conde` because they
reference the top-level `mplus` binding. It touches **only the leader**:
the follower runs on `settle` (residual.scm), which never calls `mplus`,
so the follower — the project's whole point — is completely unaffected.
`test-all.scm` doesn't load the DFS file, so the suite and every existing
fair-search arm are unaffected. The IDDFS arms are standalone processes
that opt in with one extra `(load ...)`.

**One thing the implementer must verify empirically first** (before
building the arms): that redefining top-level `mplus` actually reaches
`bind`'s and `conde`'s internal calls. Flat top-level defines in Chez
resolve references at call time, so it should — but confirm with a
throwaway multi-answer query whose answer *order* distinguishes DFS from
interleaving (e.g. two `conde` clauses each producing an infinite stream
of tagged answers; fair interleaves the tags, DFS returns only the first
clause's tags). If redefinition does NOT reach them (module-linkage
surprise), fall back to editing mk.scm's `mplus` directly behind a
`(*dfs-search?*)` parameter guard. Report which path was taken.

## Why iterative deepening is essential here (and what bounds a level)

Plain DFS is incomplete: it can dive into an infinite branch and never
backtrack. Iterative deepening fixes this — bound each level, DFS to the
bound, deepen if no answer. Our deepening dimension is **program size**
(`*max-term-size*`), same as today, which is what gives minimality.

But size alone does NOT bound a single DFS level's termination: a
divergent candidate can have a small fixed `q` (e.g. `q = (rember e l)`,
size 3, recurses on the same arg) while `evalo` unfolds forever
internally. Under fair interleaving this never hung the search because
interleaving kept pulling other branches and `take 1` returned on the
first answer anywhere. **Under DFS a divergent branch reached before the
answer branch would hang the level.** Two mechanisms prevent this, both
already present:

1. **The termination views (R1/R2) + follower.** In the ID+views arms the
   follower fires (throttled by `*check-follower-every*`) and refutes
   divergent `q` *structurally* — R1 kills caseless bodies, R2 kills
   non-decreasing recursion — before `evalo` dives. The notebook's
   depth-cut = 0 on these arms confirms the views bound the population.
   Under DFS the follower fires the same way along the current path.

2. **`*main-unsound-depth*` (=1000 in the arms) as the hard backstop.**
   The leader's own conde-depth counter (`state-D`) fails any branch past
   1000, guaranteeing per-level termination even if a branch dives. The
   arms are calibrated so true answers evaluate within 1000; depth-cut 0
   means it never actually fires, but it's the safety net that makes each
   DFS level provably finite.

So: **size-bounded DFS per level, terminating via the views (in practice)
and main-unsound-depth (guaranteed), iteratively deepened on size by
run-id.** Completeness + minimality: at size bound B the level is finite
(terms of size-lb ≤ B, eval-depth ≤ 1000, divergents cut) and DFS is
exhaustive over it; run-id increments B from the minimum, so the first
answer found is size-minimal — the *same* guarantee as today's
size-closed ID. This should **restore the correctness** the
fair-search-plus-views sweep lost on last/member/duplicate/rev-acc (those
regressed precisely because fair search dropped minimality; IDDFS keeps
it) **while keeping DFS's speed** — the double win, if the hypothesis holds.

## What gets built

Near-zero new code — that's the elegance:

1. **`dfs-search.scm`** (repo root): redefines `mplus` to the DFS form
   above, with a header comment explaining it swaps the leader's search
   order to depth-first and why (this file is loaded only by IDDFS arms).
   Nothing else.

2. **`experiments/<task>-full-id-views-dfs.scm`** for each of the 9 tasks:
   byte-identical to the existing `experiments/<task>-full-id-views.scm`
   (or `-r2p.scm` for interleave), plus one `(load "dfs-search.scm")`
   after the views load, and `/dfs` appended to the `run-id` name string.
   Same views, same examples, same bounds, same `run-id` size loop, same
   follower. The *only* behavioral difference is mplus = DFS.

3. A tiny **order-verification** check (throwaway, per the empirical-check
   note above) confirming redefinition reached the search.

## Measurement plan

For each of the 9 tasks, run the new `-dfs` arm and compare against the
two references already on record this session (same machine): the fair
`-full-id-views` arm ("current best") and the classic-search baseline.
Report per task: unify(main), **wall-clock** (the metric of interest
here), answer, and answer-size. **Hand-verify the returned program is
correct** (substitution on a length-4+ input) — do not trust pass/fail
alone; the fair-search sweep taught us a "passing" run can hide a wrong
program, and a size-minimal answer at a given level could in principle
differ from the fair arm's if multiple minimal answers exist. The
prediction is: DFS returns the SAME minimal answer as the fair
`-id-views` arm (so correct on all 9, unlike the fair-search-plus-views
sweep), at lower wall-clock.

Sweep `*check-follower-every*` at 1 / 20 / 100: the DFS × follower-firing
interaction is a genuine open question. Under fair search, ce1 was slow
(interleaving thunk overhead × per-fire cost); under DFS the interleaving
overhead is gone, and frequent firing refutes divergent branches sooner
(letting DFS backtrack earlier), so ce1 might now be the *fastest* rather
than the slowest — worth measuring, not assuming.

## Risks / things to flag rather than paper over

- **Redefinition doesn't reach bind/conde** → fall back to a
  parameter-guarded edit of mk.scm's mplus; report it.
- **A level hangs** (divergent branch not cut before it's entered, and
  main-unsound-depth somehow not bounding it) → that's a real finding
  about DFS fragility vs. interleaving; report the task/bound and the
  wall-clock at which you killed it, don't crank timeouts to force it.
- **DFS returns a different or wrong answer** than the fair arm at the
  same task → a bug in the size-cutoff/exhaustiveness interaction, or a
  genuine multiple-minimal-answers case; hand-trace and flag prominently.
- **No wall-clock win** (DFS mplus removes interleaving but keeps the
  per-branch `suspend` thunks fresh/conde allocate) → then the residual
  overhead is the suspension machinery itself, and the next step would be
  a bespoke stack-based DFS driver with no `suspend` at all. Measuring the
  minimal change first tells us whether that bigger rewrite is warranted;
  don't pre-emptively build it.
