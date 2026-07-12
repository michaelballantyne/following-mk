;; rember-full-id-views-r2t.scm --- R2T variant: the production combined termination
;; view terminating-recursiono/d (R2 OR R2P, whole-body disjunction) in place
;; of the single measure.  Generated from the -r2p arm; measures the pruning
;; cost of the weaker (union-accepting) combined view.
(load "experiments/id-harness.scm")
(load "views.scm") ; R1 + R2 + R2P + TY + NV view definitions

(define (rember-prog q body)
  `(letrec ([rember (lambda (e l) : ((number list) -> list)
                      ,q)])
     ,body))

(run-id "rember-full/views-r2t" '(15 19 23 27 31 35 39 43 47 51) 1000
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
          (terminating-recursiono/d 'rember '(e l) q)
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
