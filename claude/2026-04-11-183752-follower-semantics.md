# Followers and conde/d: what they are and why they exist

A **follower** is a conjunct that follows the main search, re-evaluating
at each choice point in a *determinacy-directed* mode: step forward only
where the current state uniquely forces a choice, and stall (rather than
branch) everywhere else.

## Framing

This is essentially the **Andorra Principle** from Andorra Prolog (D. H. D.
Warren and collaborators, 1990s): determinate goals — those with at most
one candidate clause given current info — run first, and non-determinate
goals wait until they become determinate. The same idea shows up under
other names in other communities:

- **Unit propagation** (SAT/SMT): apply every implication that's forced
  by the current partial assignment; defer anything that still has real
  choice.
- **And-parallelism / coroutining** (Prolog): run conjuncts that don't
  yet have an ambiguous goal ahead of the scheduler's linear march
  through them.
- **Determinacy-directed evaluation**: interpret the program
  relationally, but only take steps where the interpreter has enough
  info to commit.

"Determinacy-directed" is the phrase used in this repo's docs as the
general descriptive term; "Andorra" is the standard reference for the
precise mechanism.

The classical "underconstraint" from Will Byrd's notes (the name these
files grew out of) was a *necessary-but-not-sufficient check* with no
constraint-store effect. What's here is different — see "Extensions are
committed" below. It's a cheap prototype of an Andorra-style propagation
mechanism, not a faithful underconstraint. In particular, the propagation
only happens where a `follower` was explicitly wrapped around a goal; it
isn't yet built-in to every conjunction.

## conde/d clause shape

```scheme
(conde/d
 ([x ...] [g ...] [b ...])  ; clause: fresh vars, guard goals, body goals
 ...)
```

The `(g ...)` are the clause's **guards**; the `(b ...)` are its body.
This is the one place the `g` in the older `condg` name was accurate —
`conde/d` really does have explicit guard clauses — but it isn't the only
thing going on, so the new name prefers the determinacy framing.

## Semantics

For each clause, run its guards against the current state and classify
the resulting stream:

- **empty stream** → clause is ruled out
- **singleton stream** → clause is a candidate to commit
- **multi-answer stream** → `'nondet` (ambiguous)

Then decide:

- exactly one candidate, no ambiguity → **commit**: run that clause's body
- ≥2 candidates, or any `'nondet` → call `(nondeterministic)`, which
  returns `(cons st g-thunk)` — i.e. hand back the *entry* state paired
  with a thunk that re-runs the whole `conde/d` later, when more info is
  known
- zero candidates → **fail**

The key property: a conde/d that can't commit *stalls* rather than
branches. It says "I don't yet know enough to step forward, come back
when you do." That suspension is what makes it safe to run a relational
interpreter on a partial program without spawning exponential branches.

## Why this is useful

The motivating use case: a relational interpreter like `eval-expo/d` in
`restricted-interp-following.scm` is one big `conde/d` where each
clause's guard unifies the `expr` with a particular syntactic form
(`cons`, `letrec`, `match`, `if`, `(rator . rands)`, etc.). On a ground
input, exactly one guard commits and the interpreter steps normally. On a
partial input where the syntactic shape is still free, no clause commits
and the conde/d stalls — so the follower returns its entry state with
the conde/d thunk tagged for re-firing later. No fan-out.

Guards should depend only on *locally available info* — what's in the
state right now. A guard that recurses over structure with fresh tails
risks becoming a nondet-emitter that poisons whatever outer guard
contained it. See the fresh-tails note for the painful specific case.

Every primitive goal used *inside* a conde/d guard or body has to be a
depth-threaded `/d` variant (`==/d`, `=/=/d`, `symbolo/d`, `absento/d`,
...). They're produced by `wrap-for-depth-limit` and take two extra
`depth1` / `depth2` arguments that conde/d threads through via `bind/d*`
/ `fresh/d`.

## Extensions are committed

**Important, and non-obvious:** when a `conde/d` wrapped in a follower
commits a clause, the substitution and constraint-store extensions made
by the committed body *do* flow out to the outer search state. Look at
`run-and-set-follower` in `following.scm`:

```scheme
(case-inf/d $
  (() #f)
  ((c^) (state-with-F c^ #f))
  ((c^ f^) (state-with-F c^ (cons f^ t))))
```

`c^` is the state *resulting from* running the follower's goal. Only the
F slot is updated; S and C pass through unchanged. There's no rollback to
the entry state.

This is a meaningful departure from classical one-shot/general
underconstraints, where the whole point was that they're checked
*without* extending the store so they can be evaluated independently of
constraint interaction. What's here is closer to a `onceo`-wrapped
interpreter step: extensions that conde/d is *forced* to make (because
exactly one clause committed given current info) flow out to the outer
store.

The soundness argument for this design: if `conde/d` only commits when a
clause is uniquely determined by the current state, the extensions that
committed body makes are extensions any sound evaluation of the same
relation on the same state would also make. Committing them to the outer
store is sound in exactly the same sense the committed step is sound.
This depends on `evaluate-guard` correctly reporting `'nondet` whenever
there's real ambiguity — a bug there would leak unforced extensions.

## The re-trigger story

An `(follower name term goal)` call runs `goal` once immediately, in a
fresh scope, and classifies the result:

- fail → fail the outer search
- singleton success → commit extensions, drop the follower, continue
- suspended stream → commit extensions made so far, stash
  `(resume-thunk . term)` in `state-F` so that `trigger-followers` can
  re-run the remainder later

`trigger-followers` is called from two places:

1. `conde` in `mk/mk.scm` — before each branch, so re-firing happens
   during search as new info appears on each path
2. `run` in `following.scm` — once at the end, just before reification,
   as a final sanity check

Failure of the re-fired follower cuts the outer search state on which it
was triggered — which is the whole point: prune branches that have
become inconsistent with the interpreter's deductions.
