;; duplicate-full-id-views-residual.scm --- size-closed ID synthesis of `duplicate`, the
;; full follower stack (R1 base-case + R2 decreasing-recursion + TY types + NV
;; non-vacuous) PLUS evalo/d over the examples, check-every 1.  Mirrors
;; experiments/rember-full-id-views.scm.  This is the typed-full arm the
;; ablation cites (53,812 unify(main), answer at bound 39; see
;; experiments/ablation.md, duplicate/full row).
;;
;; Task: duplicate : ((list) -> list).  Double every element.
;;   (a b) -> (a a b b).
;; Canonical body (answer):
;;   (match l ['() l] [(cons a d) (cons a (cons a (duplicate d)))])
;; Expected answer at bound 39 (bounds 11..47 step 4; 39 is on the grid).
;;
;; Residual-engine port of duplicate-full-id-views.scm (backlog 3b).
;;   ./run.sh --check-follower-every 1 --timeout 500 experiments/duplicate-full-id-views-residual.scm
(load "experiments/id-harness.scm")
(load "residual-views.scm") ; R1+R2+TY+NV view definitions (residual)
(load "residual-interp-following.scm")

(define (duplicate-prog q body)
  `(letrec ([duplicate (lambda (l) : ((list) -> list)
                          ,q)])
     ,body))

(define duplicate-tyenv '((duplicate . ((list) -> list)) (l . list)))

(run-id "duplicate-full/views/residual" '(11 15 19 23 27 31 35 39 43 47) 1000
  (lambda (bound)
    (run 1 (q)
      (watch-size q)
      (absento 3 q)
      (absento 4 q)
      (absento 5 q)
      (follower
        q
        (follower-residual-goal
          (rfresh/d ()
            (base-case-patho/d-res 'duplicate q)
            (decreasing-recursiono/d-res 'duplicate '(l) q)
            (type-ofo/d-res duplicate-tyenv q 'list)
            (non-vacuous-testso/d-res q)
            (evalo/d-res (duplicate-prog q '(duplicate '())) '())
            (evalo/d-res (duplicate-prog q '(duplicate (cons 5 '()))) '(5 5))
            (evalo/d-res (duplicate-prog q '(duplicate (cons 3 (cons 4 '())))) '(3 3 4 4)))))
      (evalo (duplicate-prog q '(duplicate '())) '())
      (evalo (duplicate-prog q '(duplicate (cons 5 '()))) '(5 5))
      (evalo (duplicate-prog q '(duplicate (cons 3 (cons 4 '())))) '(3 3 4 4)))))
