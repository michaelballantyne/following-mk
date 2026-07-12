;; duplicate-full-id-views-r2t.scm --- R2T variant: the production combined termination
;; view terminating-recursiono/d (R2 OR R2P, whole-body disjunction) in place
;; of the single measure.  Generated from the -r2p arm; measures the pruning
;; cost of the weaker (union-accepting) combined view.
(load "experiments/id-harness.scm")
(load "views.scm") ; R1 + R2 + R2P + TY + NV view definitions

(define (duplicate-prog q body)
  `(letrec ([duplicate (lambda (l) : ((list) -> list)
                          ,q)])
     ,body))

(define duplicate-tyenv '((duplicate . ((list) -> list)) (l . list)))

(run-id "duplicate-full/views-r2t" '(11 15 19 23 27 31 35 39 43 47) 1000
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
          (terminating-recursiono/d 'duplicate '(l) q)
          (type-ofo/d duplicate-tyenv q 'list)
          (non-vacuous-testso/d q)
          (evalo/d (duplicate-prog q '(duplicate '())) '())
          (evalo/d (duplicate-prog q '(duplicate (cons 5 '()))) '(5 5))
          (evalo/d (duplicate-prog q '(duplicate (cons 3 (cons 4 '())))) '(3 3 4 4))))
      (evalo (duplicate-prog q '(duplicate '())) '())
      (evalo (duplicate-prog q '(duplicate (cons 5 '()))) '(5 5))
      (evalo (duplicate-prog q '(duplicate (cons 3 (cons 4 '())))) '(3 3 4 4)))))
