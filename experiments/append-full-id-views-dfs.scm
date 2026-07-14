;; append-full-id-views-dfs.scm --- size-closed ID synthesis of `append`, the
;; current best configuration: full follower stack (R1 base-case + R2
;; decreasing-recursion + TY types + NV non-vacuous) PLUS evalo/d over the
;; examples, check-every 1. IDDFS variant of experiments/append-full-id-views.scm:
;; same everything, but the per-level search is depth-first (dfs-search.scm's
;; mplus) instead of fair interleaving. Mirrors experiments/rember-full-id-views.scm.
;; append-tyenv is defined in views.scm; reused here rather than redefined.
;;
;;   ./run.sh --check-follower-every 1 --timeout 500 experiments/append-full-id-views-dfs.scm
(load "experiments/id-harness.scm")
(load "views.scm") ; R1+R2+TY+NV view definitions; defines append-tyenv
(load "dfs-search.scm") ; per-level search: depth-first instead of fair interleaving

(define (append-prog q body)
  `(letrec ([append (lambda (l s) : ((list list) -> list)
                      ,q)])
     ,body))

(run-id "append-full/views/dfs" '(11 15 19 23 27 31 35 39) 1000
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
          (base-case-patho/d 'append q)
          (decreasing-recursiono/d 'append '(l s) q)
          (type-ofo/d append-tyenv q 'list)
          (non-vacuous-testso/d q)
          (evalo/d (append-prog q '(append '() (cons 5 (cons 6 '())))) '(5 6))
          (evalo/d (append-prog q '(append (cons 3 (cons 4 (cons 5 '()))) (cons 6 (cons 7 '()))))
                   '(3 4 5 6 7))))
      (evalo (append-prog q '(append '() (cons 5 (cons 6 '())))) '(5 6))
      (evalo (append-prog q '(append (cons 3 (cons 4 (cons 5 '()))) (cons 6 (cons 7 '()))))
             '(3 4 5 6 7)))))
