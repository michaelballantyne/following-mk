;; rember-full-id-views-r2p.scm --- rember with R2 REPLACED by R2P
;; (permuted-decreasing-recursiono/d).  Identical to rember-full-id-views.scm in
;; every other respect (R1 + TY + NV + evalo/d, same examples, same bounds,
;; check-every 1).  A MARGINAL-COST probe: what does wholesale replacement of
;; the fixed-position termination view by the permuted one cost on a task R2
;; already handled?  Compare TOTAL unify(main)/conde(main)/wall against the R2
;; version (rember-full-id-views.scm: 312,236 unify(main)).
;;
;; R2P accepts rember's canonical (identity assignment: e<-e same, d<-l strict).
;;
;;   ./run.sh --check-follower-every 1 --timeout 240 experiments/rember-full-id-views-r2p.scm
(load "experiments/id-harness.scm")
(load "views.scm") ; R1 + R2 + R2P + TY + NV view definitions

(define (rember-prog q body)
  `(letrec ([rember (lambda (e l) : ((number list) -> list)
                      ,q)])
     ,body))

(run-id "rember-full/views-r2p" '(15 19 23 27 31 35 39 43 47 51) 1000
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
          (permuted-decreasing-recursiono/d 'rember '(e l) q)
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
