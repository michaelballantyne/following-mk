# following-mk

See [`README.md`](README.md) for the project description, what a follower
is, the `/d` primitives, the depth parameters, how to run things, and the
repo layout. Read it before making non-trivial changes — don't duplicate
its content here.

## Notes

Durable design notes live in [`claude/`](claude/), one markdown file per
entry, named `YYYY-MM-DD-HHMMSS-slug.md` (UTC). They hold material the
README deliberately doesn't — mk.scm patch details, soundness arguments,
naming history, open questions. Browse them for context before touching
the follower internals or the mk.scm fork.

## Autoformat

The Scheme sources are formatted with `raco fmt`. A project-local config
lives at `.fmt.rkt` and teaches the formatter about this repo's forms:

- `fresh`, `fresh/d`, `run`, `run*`, `follower`, `test` — body-style
  like `lambda`
- `conde`, `conde/d` — each clause on its own line, and each clause's
  children (goals for `conde`, three sub-lists for `conde/d`) forced
  onto separate vertical lines aligned under the first child
- `case-inf/d` — one head arg + clauses, like `case`
- `lambda` — custom formatter: when the third element is `:`
  (the typed lambda used inside interpreter test programs), format as
  `(lambda (args) : type` + body-indent-2; otherwise the normal
  `(lambda (args)` + body-indent-2

Reformat in place:

```
raco fmt -i following.scm restricted-interp.scm restricted-interp-following.scm \
           tests.scm synthesis-benchmarks.scm
```

Preview without writing:

```
raco fmt following.scm
```
