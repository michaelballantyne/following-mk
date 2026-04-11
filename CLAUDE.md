# following-mk

Research prototype: a determinacy-directed "follower" mechanism for
miniKanren, built on top of faster-miniKanren. A *follower* is a conjunct
that follows the main search, re-evaluating at each choice point and
committing only deductions that are uniquely forced by the current state —
the Andorra Principle from Andorra Prolog, applied locally to one wrapped
goal.

The upstream faster-miniKanren sources live under `mk/`. The follower
add-on is layered on top from files in the repo root (`following.scm`,
`load.scm`, `restricted-interp*.scm`, `test-following*.scm`). Run chez from
the repo root.

The form `(follower name term goal)` installs a follower around `goal`.
Inside the follower, the usual goal constructors are available in
determinacy-mode variants with `/d` suffixes: `conde/d`, `fresh/d`, `==/d`,
`=/=/d`, `symbolo/d`, `absento/d`, `numbero/d`, `stringo/d`. The
`restricted-interp-following.scm` file gives an example: a relational
interpreter written entirely in these `/d` goals so that it can be run
inside a follower and evaluate a partial program forward only where
determinacy allows.

## Notes

Ongoing notes and reflections live in [`claude/`](claude/), one markdown
file per entry, named `YYYY-MM-DD-HHMMSS-slug.md` (UTC). These are durable
notes about design, mechanics, and open questions — not a changelog.
Browse them for context on why things are the way they are before making
non-trivial changes.
