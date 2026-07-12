# archive/

Superseded experiment arms from earlier view rungs and search-strategy
probes. Kept runnable: all `(load ...)` paths are repo-root-relative, so
run each from the repo root, e.g.

```
./run.sh --timeout 60 experiments/archive/rember-full-id-tv4.scm
```

(`run.sh` `cd`s to the repo root itself, so the load paths resolve
regardless of where you invoke it.) The `claude/` notes reference these
files by their original names.

The old chain-loaded `termination-view{,2,3,4}.scm` files these arms used
have been consolidated into the repo-root `views.scm`; the two negative
views are now `experiments/negative-view-occurso.scm` and
`experiments/negative-view-branch-vacuity.scm`. Each archived arm's
`(load ...)` lines were updated to point at those, but the arm bodies are
otherwise verbatim.
