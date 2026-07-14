;; dfs-search.scm --- swap the per-level search engine to depth-first.
;;
;; mk.scm's mplus (mk.scm:317) interleaves: on a suspension in the first
;; stream, it swaps to force the SECOND stream next time around, giving
;; fair round-robin interleaving between conde branches / bind's
;; multi-answer continuations. That round-robin is where the thunk churn
;; documented in claude/2026-07-14-012017-iddfs-search-design.md lives.
;;
;; This file redefines mplus to the "append"/DFS order instead: on a
;; suspension, keep forcing the FIRST stream's own continuation and defer
;; the second stream, so the first branch is drained depth-first before
;; ever backtracking to the second. The only difference from mk.scm's
;; mplus is `(mplus (f) f^)` -> `(mplus (f^) f)` in the two suspension
;; cases below (`((f^) ...)` and `((c f^) ...)`); case-inf, bind, take,
;; conde, run, etc. are all unchanged and continue to reference this
;; top-level `mplus` binding.
;;
;; This swaps the search order for the WHOLE leader (conde and bind's
;; multi-answer case are the only disjunction sources and both route
;; through mplus), but touches only the leader: the follower runs on
;; `settle` (residual.scm), which never calls mplus, so it is completely
;; unaffected.
;;
;; Loaded only by the IDDFS arms (experiments/*-full-id-views-dfs.scm),
;; each of which pairs this with the existing size-frontier iterative
;; deepening in run-id (experiments/id-harness.scm) to give size-bounded
;; IDDFS. NOT loaded by test-all.scm or any fair-search arm.
(define (mplus stream f)
  (case-inf stream
    (() (f))
    ((f^) (lambda () (mplus (f^) f)))
    ((c) (cons c f))
    ((c f^) (cons c (lambda () (mplus (f^) f))))))
