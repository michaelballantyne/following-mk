# following-mk

See [`README.md`](README.md) for the project description, what a follower
is, the `/d` primitives, the depth parameters, how to run things, and the
repo layout. Read it before making non-trivial changes — don't duplicate
its content here.

This is a research prototype with no external users. There are no
backwards-compatibility constraints — rename, reorganize, and delete
freely to keep the codebase clean.

## Notes

Durable design notes live in [`claude/`](claude/), one markdown file per
entry, named `YYYY-MM-DD-HHMMSS-slug.md` (UTC). They hold material the
README deliberately doesn't — mk.scm patch details, soundness arguments,
naming history, open questions. Browse them for context before touching
the follower internals or the mk.scm fork.

## Autoformat

The Scheme sources are formatted with `raco fmt`. A project-local config
lives at `.fmt.rkt` and teaches the formatter about this repo's forms:

- `fresh`, `fresh/d`, `run`, `run*`, `follower`, `test`, `example`,
  `time-test`, `time-example` — body-style like `lambda`
- `conde`, `conde/d` — each clause on its own line, and each clause's
  children (goals for `conde`, three sub-lists for `conde/d`) forced
  onto separate vertical lines aligned under the first child
- `lambda` — custom formatter: when the third element is `:`
  (the typed lambda used inside interpreter test programs), format as
  `(lambda (args) : type` + body-indent-2; otherwise the normal
  `(lambda (args)` + body-indent-2

Reformat in place:

```
raco fmt -i following.scm residual.scm views.scm restricted-interp*.scm \
           tests/*.scm synthesis/*.scm experiments/*.scm
```

Preview without writing:

```
raco fmt following.scm
```

## Independent research mode

Claude Code works independently on this project on the `claude-independent`
branch. This is open-ended research in service of the project's goal — see
the research-goal framing in [`README.md`](README.md) and the status header
of [`BACKLOG.md`](BACKLOG.md). The unit
of progress is a **resolved question** (a hypothesis measured, a mechanism
understood, a sharp corner documented or fixed), not a shipped feature.
Direction can and should evolve from what's learned — there's no fixed finish
line, only the next question the last finding opened up.

**Notebook.** Every meaningful chunk of work — an experiment run, a design
decision, a dead end, a thing understood — gets a dated entry in
[`claude/`](claude/), using the existing convention documented under
`## Notes` above: `YYYY-MM-DD-HHMMSS-slug.md` (UTC, `date -u +%Y-%m-%d-%H%M%S`).
Append-only: don't rewrite an old entry's conclusion; write a new entry that
says what changed and why, linking back. Be concrete — what was run, on what,
with what numbers, and what it implies for the goal or the backlog. Vague
status updates ("worked on the follower today") are not entries.

**Backlog.** Keep a roughly-prioritized [`BACKLOG.md`](BACKLOG.md) at the repo
root — open questions and experiments (Now / Next / Later / Resolved), 10–20
open items. An item resolves when answered *either way* ("this helps" and
"this doesn't help, here's why" are both resolutions); move it to Resolved
with a one-line answer and a link to the `claude/` entry with details. If the
backlog runs dry, generate the next round from recent notebook entries rather
than treating empty as a stopping point.

**Reflect and re-prioritize periodically.** Backlog items are not evergreen —
what looked worth doing a few findings ago is often stale now. Every several
notebook entries (or at a natural inflection point — a hypothesis confirmed
or falsified, a direction abandoned), step back and take a higher-altitude
pass: is the current direction still serving the research goal, or has it
drifted? Which items still matter, which are now answered-by-implication or
obsolete, and what did the recent findings make newly important? Write this up
as its own dated `claude/` entry (a reflection, distinct from an experiment
log), then act on it: **rewrite `BACKLOG.md`** — re-order, drop stale items,
add the ones the reflection surfaced. Don't let the backlog accumulate
aspirational cruft; the notebook preserves the reasoning if a dropped item is
ever wanted back.

**Working until session end.** Check for a `SESSION_END` file in the repo
root. If it exists, you're in independent mode: it holds a UTC unix timestamp
(`date -u +%s`) deadline, the user is not watching, and you work autonomously
until `date -u +%s` exceeds it.

**Check the clock; don't infer it.** Your subjective sense of elapsed time
tracks your own activity, not the wall clock — a dense burst of tool calls
feels like hours and an idle wait feels like minutes, and both are usually
wrong. Before any deadline-sensitive decision (wrapping up early, declining
to start something "too big", sizing a timeout, scheduling a check-in), run
`date -u` and compute the actual remaining time against `SESSION_END`.
Cheap to check, expensive to guess wrong in either direction: phantom time
pressure truncates good work, and phantom slack strands it unfinished. A clean result (positive or negative) or a
commit is **not** a stopping point — write it up, update the backlog, pick up
the next question. Don't ask the user questions in this mode; make your best
judgment and record it (in the notebook for an experiment call, in a `claude/`
design note for a direction call). Commit often — keep `git log`, `BACKLOG.md`,
and the recent `claude/` entries enough that a cold-start next session can
continue without you. Use `WIP:` commit prefixes and `[~]` backlog markers for
partial progress.

**Delegation.** Protect your own context: delegate reading, running
experiments, and digesting output to subagents (`Agent` / `Explore`).
Deciding *what question to chase next* stays with the main loop. You are the
sole committer — subagents write into the tree and report back; review before
committing.

Think of yourself as a **PhD advisor directing PhD students**: you don't get
into the nitty-gritty of every implementation or debugging session, but you
understand what's going on in enough detail to propose the right next
directions, spot when a result doesn't add up, and catch mistakes before they
compound. The heavy *thinking* — framing the question, interpreting a
measurement, deciding a hypothesis is confirmed or dead, choosing the pivot —
is yours to do, not to delegate.

Choose models accordingly: delegate implementation and debugging to `Opus` or
`Sonnet` subagents (via the `model` option on the `Agent` call) — they're the
students who do the detailed work. The driving loop does the advising. Don't
push the judgment calls (what to chase, whether a result holds, what it means)
down to a subagent; that's the part that most needs the advisor's context and
is the whole reason the loop exists.
