;; rember-full-id-views-dfs.scm --- the current best configuration: size-closed ID
;; with all four structural/type views PLUS evalo/d over the examples, check-every
;; 1. IDDFS variant of experiments/rember-full-id-views.scm: same everything, but
;; the per-level search is depth-first (dfs-search.scm's mplus) instead of fair
;; interleaving. Total to canonical answer: 312,236 unify(main) — 10.3x
;; below the fair-search baseline. See
;; claude/2026-07-12-204500-examples-earn-after-cleanup.md.
;;   ./run.sh --check-follower-every 1 --timeout 500 experiments/rember-full-id-views-dfs.scm
(load "experiments/id-harness.scm")
(load "views.scm") ; R1+R2+TY+NV view definitions
(load "dfs-search.scm") ; per-level search: depth-first instead of fair interleaving

(define (rember-prog q body)
  `(letrec ([rember (lambda (e l) : ((number list) -> list)
                      ,q)])
     ,body))

(run-id "rember-full/views/dfs" '(15 19 23 27 31 35 39 43 47 51) 1000
  (lambda (bound)
    (run 1 (q)
      (watch-size q)
      (absento 3 q)
      (absento 4 q)
      (absento 5 q)
      (absento 6 q)
      (absento 7 q)
      (follower
        q
        (fresh/d ()
          (base-case-patho/d 'rember q)
          (decreasing-recursiono/d 'rember '(e l) q)
          (type-ofo/d rember-tyenv q 'list)
          (non-vacuous-testso/d q)
          (evalo/d (rember-prog q '(rember 5 '())) '())
          (evalo/d (rember-prog q '(rember 6 (cons 6 '()))) '())
          (evalo/d (rember-prog q '(rember 7 (cons 3 (cons 4 (cons 7 (cons 6 '())))))) '(3 4 6))
          (evalo/d (rember-prog q '(rember 5 (cons 3 (cons 4 (cons 6 (cons 7 '())))))) '(3 4 6 7))))
      (evalo (rember-prog q '(rember 5 '())) '())
      (evalo (rember-prog q '(rember 6 (cons 6 '()))) '())
      (evalo (rember-prog q '(rember 7 (cons 3 (cons 4 (cons 7 (cons 6 '())))))) '(3 4 6))
      (evalo (rember-prog q '(rember 5 (cons 3 (cons 4 (cons 6 (cons 7 '())))))) '(3 4 6 7)))))
