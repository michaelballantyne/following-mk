# Addendum to the top-down×bottom-up cross-reference note

`claude/2026-07-12-211613-topdown-bottomup-crossref.md` (written minutes
before the untyped-factoring results landed) says the
interpreter+typechecker multi-source experiment is "a genuinely open
question... worth prioritizing." Point 2 of that note is now stale by one
commit: the experiment was run and answered the same evening —
`claude/2026-07-12-212000-untyped-factoring-results.md`.

What the answer does to the cross-repo story:

- The literature-side claim stands (no *published* system fuses
  interpreter + typechecker as independent composed sources in one
  synthesis search), but it is no longer unmeasured in-house: untyped
  interpreter + `type-ofo/d` view matches the typed-full interpreter
  within ~2%, with the type view's marginal value task-structural (8.3×
  on rember, ~1.1× where the grammar admits little ill-typed junk).
- This is the first measured evidence for the backlog's "Project
  identity" factor 2 (composable information sources) applied to the
  interpreter itself, and it strengthens the contrast with the hybrid
  synthesizers surveyed in the sibling repo (DUET/Simba pay per-operator
  inverse semantics or hand-designed abstract domains for their
  top-down information; here backward/typed propagation came from
  factoring a relational spec, with no per-operator machinery).
- The sibling repo's litcheck line "no typechecker fusion published"
  (`bottom-up-synth-datalog/notebook/2026-07-12-2111Z-relational-spec-multisource-litcheck.md`)
  should be read alongside this result rather than corrected — the
  entry is about published precedent, and this repo's measurement is
  the in-house answer it called for.
