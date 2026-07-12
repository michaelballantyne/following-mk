;; rev-acc-full-id-views-r2t.scm --- R2T variant: terminating-recursiono/d
;; (R2 OR R2P) in place of R2.  rev-acc is the R2P-refuted canonical (growing
;; accumulator), so this measures the both-walks cost where only the R2
;; disjunct accepts.
(load "experiments/id-harness.scm")
(load "views.scm") ; R1+R2+TY+NV view definitions

(define (rev-prog q body)
  `(letrec ([rev (lambda (l acc) : ((list list) -> list)
                   ,q)])
     ,body))

(define rev-tyenv '((rev . ((list list) -> list)) (l . list) (acc . list)))

(run-id "rev-acc-full/views-r2t" '(11 15 19 23 27 31 35 39) 1000
  (lambda (bound)
    (run 1 (q)
      (watch-size q)
      (absento 5 q)
      (absento 6 q)
      (absento 7 q)
      (follower
        q
        (fresh/d ()
          (base-case-patho/d 'rev q)
          (terminating-recursiono/d 'rev '(l acc) q)
          (type-ofo/d rev-tyenv q 'list)
          (non-vacuous-testso/d q)
          (evalo/d (rev-prog q '(rev '() '())) '())
          (evalo/d (rev-prog q '(rev (cons 5 '()) '())) '(5))
          (evalo/d (rev-prog q '(rev (cons 5 (cons 6 '())) '())) '(6 5))
          (evalo/d (rev-prog q '(rev (cons 5 (cons 6 (cons 7 '()))) '())) '(7 6 5))))
      (evalo (rev-prog q '(rev '() '())) '())
      (evalo (rev-prog q '(rev (cons 5 '()) '())) '(5))
      (evalo (rev-prog q '(rev (cons 5 (cons 6 '())) '())) '(6 5))
      (evalo (rev-prog q '(rev (cons 5 (cons 6 (cons 7 '()))) '())) '(7 6 5)))))
