;; duplicate-full-id-views-r2p-residual.scm --- duplicate with R2 REPLACED by R2P
;; (permuted-decreasing-recursiono/d).  Identical to duplicate-full-id-views.scm
;; otherwise (R1 + TY + NV + evalo/d, same examples/bounds, check-every 1).  A
;; MARGINAL-COST probe of wholesale replacement on a fixed-position task R2
;; already handled.  Compare TOTAL against duplicate-full-id-views.scm (53,812
;; unify(main), answer at bound 39).
;;
;; R2P accepts duplicate's canonical (arity 1, identity: d<-l strict).
;;
;; Residual-engine port of duplicate-full-id-views-r2p.scm (backlog 3b).
;;   ./run.sh --check-follower-every 1 --timeout 240 experiments/duplicate-full-id-views-r2p-residual.scm
(load "experiments/id-harness.scm")
(load "residual-views.scm") ; R1 + R2 + R2P + TY + NV view definitions (residual)
(load "residual-interp-following.scm")

(define (duplicate-prog q body)
  `(letrec ([duplicate (lambda (l) : ((list) -> list)
                          ,q)])
     ,body))

(define duplicate-tyenv '((duplicate . ((list) -> list)) (l . list)))

(run-id "duplicate-full/views-r2p/residual" '(11 15 19 23 27 31 35 39 43 47) 1000
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
            (permuted-decreasing-recursiono/d-res 'duplicate '(l) q)
            (type-ofo/d-res duplicate-tyenv q 'list)
            (non-vacuous-testso/d-res q)
            (evalo/d-res (duplicate-prog q '(duplicate '())) '())
            (evalo/d-res (duplicate-prog q '(duplicate (cons 5 '()))) '(5 5))
            (evalo/d-res (duplicate-prog q '(duplicate (cons 3 (cons 4 '())))) '(3 3 4 4)))))
      (evalo (duplicate-prog q '(duplicate '())) '())
      (evalo (duplicate-prog q '(duplicate (cons 5 '()))) '(5 5))
      (evalo (duplicate-prog q '(duplicate (cons 3 (cons 4 '())))) '(3 3 4 4)))))
