;; interleave-full-id-views-r2t.scm --- R2T variant: the production combined termination
;; view terminating-recursiono/d (R2 OR R2P, whole-body disjunction) in place
;; of the single measure.  Generated from the -r2p arm; measures the pruning
;; cost of the weaker (union-accepting) combined view.
(load "experiments/id-harness.scm")
(load "views.scm") ; R1 + R2 + R2P + TY + NV view definitions

(define (interleave-prog q body)
  `(letrec ([interleave (lambda (l1 l2) : ((list list) -> list)
                          ,q)])
     ,body))

(define interleave-tyenv
  '((interleave . ((list list) -> list)) (l1 . list) (l2 . list)))

(run-id "interleave-full/views-r2t" '(11 15 19 23 27 31 35 39) 1000
  (lambda (bound)
    (run 1 (q)
      (watch-size q)
      (absento 5 q)
      (absento 6 q)
      (absento 7 q)
      (absento 8 q)
      (follower
        q
        (fresh/d ()
          (base-case-patho/d 'interleave q)
          (terminating-recursiono/d 'interleave '(l1 l2) q)
          (type-ofo/d interleave-tyenv q 'list)
          (non-vacuous-testso/d q)
          (evalo/d (interleave-prog q '(interleave '() '())) '())
          (evalo/d (interleave-prog q '(interleave '() (cons 6 '()))) '(6))
          (evalo/d (interleave-prog q '(interleave (cons 5 '()) (cons 6 '()))) '(5 6))
          (evalo/d (interleave-prog q '(interleave (cons 5 (cons 7 '())) (cons 6 (cons 8 '())))) '(5 6 7 8))))
      (evalo (interleave-prog q '(interleave '() '())) '())
      (evalo (interleave-prog q '(interleave '() (cons 6 '()))) '(6))
      (evalo (interleave-prog q '(interleave (cons 5 '()) (cons 6 '()))) '(5 6))
      (evalo (interleave-prog q '(interleave (cons 5 (cons 7 '())) (cons 6 (cons 8 '())))) '(5 6 7 8)))))
