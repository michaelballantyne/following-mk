;; duplicate-full-id-views-dfs.scm --- size-closed ID synthesis of `duplicate`,
;; the full follower stack (R1 base-case + R2 decreasing-recursion + TY types +
;; NV non-vacuous) PLUS evalo/d over the examples, check-every 1. IDDFS variant
;; of experiments/duplicate-full-id-views.scm: same everything, but the
;; per-level search is depth-first (dfs-search.scm's mplus) instead of fair
;; interleaving. Mirrors experiments/rember-full-id-views.scm.  This is the
;; typed-full arm the ablation cites (53,812 unify(main), answer at bound 39;
;; see experiments/ablation.md, duplicate/full row).
;;
;; Task: duplicate : ((list) -> list).  Double every element.
;;   (a b) -> (a a b b).
;; Canonical body (answer):
;;   (match l ['() l] [(cons a d) (cons a (cons a (duplicate d)))])
;; Expected answer at bound 39 (bounds 11..47 step 4; 39 is on the grid).
;;
;;   ./run.sh --check-follower-every 1 --timeout 500 experiments/duplicate-full-id-views-dfs.scm
(load "experiments/id-harness.scm")
(load "views.scm") ; R1+R2+TY+NV view definitions
(load "dfs-search.scm") ; per-level search: depth-first instead of fair interleaving

(define (duplicate-prog q body)
  `(letrec ([duplicate (lambda (l) : ((list) -> list)
                          ,q)])
     ,body))

(define duplicate-tyenv '((duplicate . ((list) -> list)) (l . list)))

(run-id "duplicate-full/views/dfs" '(11 15 19 23 27 31 35 39 43 47) 1000
  (lambda (bound)
    (run 1 (q)
      (watch-size q)
      (absento 3 q)
      (absento 4 q)
      (absento 5 q)
      (follower
        q
        (fresh/d ()
          (base-case-patho/d 'duplicate q)
          (decreasing-recursiono/d 'duplicate '(l) q)
          (type-ofo/d duplicate-tyenv q 'list)
          (non-vacuous-testso/d q)
          (evalo/d (duplicate-prog q '(duplicate '())) '())
          (evalo/d (duplicate-prog q '(duplicate (cons 5 '()))) '(5 5))
          (evalo/d (duplicate-prog q '(duplicate (cons 3 (cons 4 '())))) '(3 3 4 4))))
      (evalo (duplicate-prog q '(duplicate '())) '())
      (evalo (duplicate-prog q '(duplicate (cons 5 '()))) '(5 5))
      (evalo (duplicate-prog q '(duplicate (cons 3 (cons 4 '())))) '(3 3 4 4)))))
