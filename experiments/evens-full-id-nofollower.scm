;; evens-full-id-nofollower.scm --- enumerative baseline arm: same task,
;; examples, bounds, and absento exclusions as evens-full-id-views.scm,
;; NO follower. Generated mechanically from that file; see it for the
;; task documentation.
(load "experiments/id-harness.scm")
(load "views.scm") ; R1+R2+TY+NV view definitions

(define (evens-prog q body)
  `(letrec ([evens (lambda (l) : ((list) -> list)
                     ,q)])
     ,body))

(define evens-tyenv '((evens . ((list) -> list)) (l . list)))

(run-id "evens-full/no-follower" '(39 43 47 51 55 59 63 67 71 75) 1000
  (lambda (bound)
    (run 1 (q)
      (watch-size q)
      (absento 5 q)
      (absento 6 q)
      (absento 7 q)
      (absento 8 q)
      (evalo (evens-prog q '(evens '())) '())
      (evalo (evens-prog q '(evens (cons 5 '()))) '(5))
      (evalo (evens-prog q '(evens (cons 5 (cons 6 '())))) '(5))
      (evalo (evens-prog q '(evens (cons 5 (cons 6 (cons 7 '()))))) '(5 7))
      (evalo (evens-prog q '(evens (cons 5 (cons 6 (cons 7 (cons 8 '())))))) '(5 7)))))
