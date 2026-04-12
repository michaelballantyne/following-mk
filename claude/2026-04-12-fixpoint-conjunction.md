# Fixpoint conjunction and hard-suspend

## Problem

The /d evaluator runs conjunctions of goals determinately. When two
adjacent conjuncts each learn information the other could use, we want
them to iterate: run g1, run g2, if g2 learned something, run g1 again
on the refined state, and so on until no progress.

But determinate evaluation can also diverge. A recursive goal can
unfold forever without producing externally relevant constraints. We
need a depth limit that bounds this, without preventing the useful
cross-conjunct information flow.

## Two kinds of suspension

The depth limit (via `check-suspend-depth` in `conde/d-runtime`)
produces a **hard-suspended** result: a `(hard-suspended state thunk)`
record that is distinct from normal `(state . resume)` soft-suspension.

- **Soft-suspend** `(c . f)`: the goal committed state `c` and has
  more work `f`. Conjunction iteration can re-run `f` to see if
  refined information helps it make further progress.

- **Hard-suspend** `(make-hard-suspended ch fh)`: the goal hit the
  depth limit. The thunk `fh` is the conde/d goal that was never
  entered (check-suspend-depth cut it off before the body ran). The
  conjunction must not re-enter `fh` during this trigger — only a
  fresh follower retrigger may open it.

`case-inf/d` has four branches to distinguish these:

```scheme
(case-inf/d stream
  [()       ...]    ; failure
  [(c)      ...]    ; singleton success
  [(c f)    ...]    ; soft-suspend
  [(ch fh)  ...])   ; hard-suspend
```

## Why hard-suspend must be opaque to conjunction

The depth limit fires inside a deeply nested conde/d. As the
hard-suspended result propagates up through the call chain, each level
of `conj/d-run` wraps `fh` into a resume lambda — but never *calls*
it. This builds a chain that, when eventually fired by
`run-and-set-follower`, reconstructs the path all the way back to the
exact leaf conde/d that was too deep.

If the conjunction were allowed to call `fh` directly (e.g., to bounce
refined information into it), it would re-enter the depth-limited goal
with whatever `suspend-depth` the conjunction happens to have — which
may be much lower than the depth at which the limit fired. The depth
limit would be meaningless: the conjunction could repeatedly re-enter
the deep goal with fresh budget.

Making hard-suspend opaque ensures that the depth limit means what it
says: this branch is sealed for this trigger. Only a fresh follower
retrigger (which legitimately provides fresh budget) may open it.

## conj/d-run: worklist-based conjunction

`conj/d-run` takes a list of goals and processes them sequentially
against a state, collecting results into three categories:

- **Done** (singleton): goal finished, drop it, update state.
- **Soft-suspended**: goal returned `(c f)`, put `f` in the soft list.
- **Hard-suspended**: goal returned `(ch fh)`, put `fh` in the hard list.

After one pass through all goals, check whether the state changed
(by `eq?` on `state-C` and `subst-map`). If it did and soft goals
remain, iterate: re-run the soft goals on the refined state. Repeat
until no progress.

When iteration settles:
- If only soft goals remain: return `(cons st resume)` (soft-suspend).
- If any hard goals remain: return `(make-hard-suspended st resume)`.
- The resume, when fired, calls `conj/d-run` with all remaining
  goals (soft + hard) moved to the active list.

## Change detection

Progress is detected by comparing `(state-C st)` and
`(subst-map (state-S st))` by `eq?` before and after a pass. This
works because:

- The constraint store (`state-C`) uses an intmap that allocates fresh
  structure on every `intmap-set`, so identity changes iff the store
  changed.
- The substitution map similarly allocates on every binding.
- `set-var-val!` is disabled (forced `#f` in `subst-add`), so all
  bindings go through the map — no silent mutations.

Internal fresh variables (from `fresh/d`) do extend the map, which
can cause spurious change detection. However, this does not cause
divergence: any re-entry of a goal that creates fresh variables must
go through a `conde/d`, which goes through `check-suspend-depth`, which
increments `suspend-depth`. After enough re-entries, the depth limit
fires and the goal hard-suspends, terminating iteration.

## Depth budget accounting

`suspend-depth` is incremented only by `check-suspend-depth` (once per
`conde/d` entry). `conj/d-run` does *not* increment it on iteration
rounds. This is correct because every useful recursion pattern that
re-enters a `fresh/d` (allocating new variables) must pass through a
`conde/d` to get there. The depth limit in `check-suspend-depth` alone
is sufficient to bound both vertical descent and horizontal iteration.

## evaluate-guard and singleton commitment

`evaluate-guard` commits to a clause whenever exactly one clause's
guard is non-failing — even if that guard returned `(c f)` or
`(ch fh)`. The full guard stream (not just the committed state) is
passed to `conj/d-run` alongside the body goal, with any guard
suspension placed in the initial soft or hard worklist. This means:

- A depth-limited guard whose clause is the sole survivor still gets
  committed. The guard's `fh` goes to the hard list; the body runs on
  the guard's committed state; the hard-suspend propagates upward for
  eventual retrigger.
- A non-deterministic guard (multiple clauses survive) still triggers
  `(nondeterministic)`, falling back to the standard mk search.

## Follower retrigger

`run-and-set-follower` fires the stored resume with `suspend-depth = 0`,
giving full fresh depth budget. The resume chain unwinds back to the
leaf that was too deep, and the leaf's conde/d goal gets its first
real evaluation. Each trigger extends exploration one depth-budget
deeper, on a state that may have been refined by the main search
since the last trigger.
