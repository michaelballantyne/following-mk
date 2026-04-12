# following-mk

> ⚠️ Lots of vibecoding, including the documentation and research notes.

A research prototype exploring a determinacy-directed "follower"
mechanism on top of faster-miniKanren. This is a fresh re-build that
grew out of Will Byrd's
[underconstraints](https://github.com/webyrd/underconstraints) work,
specifically my extension of it in the
[condg-one-unsound-depth-limit](https://github.com/webyrd/underconstraints/tree/condg-one-unsound-depth-limit)
branch, which is where the `conde/d` + depth-limit machinery here was
originally prototyped (under different names).

## What is a follower?

A **follower** is a conjunct that follows the main miniKanren search,
re-evaluating at each choice point in a *determinacy-directed* mode: step
forward only where the current state uniquely forces a choice, and stall
(rather than branch) everywhere else. This is the
[Andorra Principle](https://en.wikipedia.org/wiki/Andorra_Kernel_Language)
from Andorra Prolog, applied locally to one wrapped goal.

You wrap a goal with `(follower term goal)`. The goal runs in
determinacy mode against the current state. Three outcomes:

- **fail** — the outer search fails on this branch
- **singleton success** — commit extensions, drop the follower, continue
- **suspended** — commit extensions made so far, stash a resume thunk in
  the state so the follower re-fires at later choice points as the main
  search learns more

Extensions made by the follower's committed work *do* flow out to the outer
search state. This is a meaningful departure from classical "underconstraints"
(necessary-but-not-sufficient checks with no store effect): if a `conde/d`
inside the follower uniquely commits, any extensions its body makes are
extensions the main search would make too on that branch, so it's sound to
commit them early.

## conde/d and /d primitives

Inside a follower, goals must be written using determinacy-mode variants
suffixed `/d`:

```
conde/d  fresh/d  ==/d  =/=/d  symbolo/d  absento/d  numbero/d  stringo/d
```

A `conde/d` clause has the shape `([fresh-vars] [guards] [body])`. The
guards are evaluated first; the clause commits only if exactly one clause's
guards succeed singleton-style. If guards of multiple clauses succeed, or
any guard has residual nondeterminism, the whole `conde/d` stalls rather
than branches.

"Singleton" here means the guard produces *one* result state — it's fine
for the guard to unify variables, add disequalities, or pin types along
the way. Those extensions travel with the commit.

`restricted-interp-following.scm` has a worked example: a relational
interpreter written entirely in `/d` goals, so it can run inside a follower
and evaluate a partial program forward wherever determinacy allows.

## Depth parameters

Two depth knobs on `conde/d` evaluation, both thread through `bind/d*`
and `fresh/d`:

- **`*unsound-fail-depth*`** — *unsound* cutoff inside the follower.
  When exceeded, the follower fails outright. Defaults to `+inf.0`
  (disabled). Intended as a diagnostic knob: starve a diverging branch
  out of the scheduler so pruning on the surviving branch becomes
  observable. Not an optimization — a pure debugging tool, and
  **it can break correctness**.
- **`*suspend-depth*`** — *sound* cutoff inside the follower. When
  exceeded, the follower suspends (same recovery as genuine incomplete
  work). Defaults to 10. Lower to make the follower give up more
  readily; raise to let it run deeper before suspending.

Two more parameters govern the *main* miniKanren search (threaded
through outer state, not inside the follower):

- **`*main-unsound-depth*`** — *unsound* cutoff on the main search,
  counted per `conde` entry. When exceeded, the branch fails outright.
  Parallel to `*unsound-fail-depth*`, same caveat: diagnostic only,
  **can break correctness**. Defaults to `+inf.0` (disabled).
- **`*check-follower-every*`** — throttle on how often the follower
  fires from the main search's conde hook. Default 1 means "fire on
  every conde" (original behavior). Setting it to 10 means "fire on
  every 10th conde" — less follower overhead, at the cost of firing
  later and possibly missing pruning opportunities.

Two other parameters tune instrumentation:

- **`*print-follower-term*`** — when true, every `trigger-followers` call
  prints the reified follower term. Useful for watching what the follower
  is narrowing down during search.
- `install-interrupt-counter-dump!` — not a parameter but a function.
  Call it to install a Ctrl-C handler that dumps the counter snapshot
  before exit. Opt-in because it replaces chez's default keyboard
  interrupt behavior, which you want for interactive REPL use.

## Repo layout

```
mk/                               upstream faster-miniKanren, minimal patches
load.scm                          loads mk/ + following.scm
following.scm                     conde/d, follower, counters, /d wrappers
restricted-interp.scm             plain relational interpreter (Osera/Zdancewic)
restricted-interp-following.scm   /d version of the same interpreter
test-all.scm                      loads and runs all test files
tests/determinacy-goal-forms.scm  /d primitives: conde/d, fresh/d, conjunction, depth
tests/following-interpreter.scm   evalo/d: ground eval, partial eval, suspend/resume
tests/finite-refutation.scm       follower refutation with finite candidate sets
tests/leading-following.scm       leader (evalo) + follower (evalo/d) interaction
synthesis/                        synthesis benchmarks (drive via run.sh)
run.sh                            driver for synthesis experiments
claude/                           design notes
```

Only three spots in `mk/mk.scm` are patched to support followers: the
`state` shape gains an `F` (follower) slot alongside `S` and `C`, `==`
threads `F` through, and `conde` calls `(trigger-followers)` before
branching so stashed followers can re-fire at each choice point.

## Running

Chez resolves `load` paths against the working directory, so always run
chez from the repo root.

The tests load everything themselves:

```
chez --script test-all.scm
```

The synthesis benchmarks don't — use `run.sh`:

```
./run.sh synthesis/append-full.scm
```

`run.sh` flags (all optional; unset flags leave the make-parameter
defaults in place):

```
--unsound-fail-depth N    set *unsound-fail-depth*     (follower, UNSOUND)
--suspend-depth N         set *suspend-depth*          (follower, sound)
--main-unsound-depth N    set *main-unsound-depth*     (main search, UNSOUND)
--check-follower-every N  set *check-follower-every*   (main search throttle)
--print-follower          enable *print-follower-term*
--dump-on-interrupt       install Ctrl-C counter-dump handler
--timeout SECS            kill the chez process after SECS wall-clock seconds,
                          print "TIMEOUT after SECS" to stderr, exit 124
```

Example: run the synthesis file with a lower suspend depth and the
interrupt handler installed, so Ctrl-C dumps counters before exit:

```
./run.sh --suspend-depth 20 --dump-on-interrupt synthesis/rember-full.scm
```

## Notes

Design notes and reflections live in [`claude/`](claude/), one markdown
file per entry. Read those for deeper context on semantics, mk.scm
patches, and naming history.
