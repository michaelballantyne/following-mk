;; Arm B1: rember-full, follower = base-case-patho/d + evalo/d (all 4 examples).
;; The termination view AND the example evaluator both run in the follower.
;; Loads experiments/termination-view.scm (definitions + self-checks) first.
(load "views.scm")
(define (rember-prog q body)
  `(letrec ([rember (lambda (e l) : ((number list) -> list)
                      ,q)])
     ,body))

(printf "=== ARM B1: rember-full, base-case-patho/d + evalo/d follower ===\n")
(time
 (printf "ANSWER: ~s\n"
   (run 1 (q)
     (absento 3 q) (absento 4 q) (absento 5 q) (absento 6 q) (absento 7 q)
     (follower q
       (fresh/d ()
         (base-case-patho/d 'rember q)
         (evalo/d (rember-prog q '(rember 5 '())) '())
         (evalo/d (rember-prog q '(rember 6 (cons 6 '()))) '())
         (evalo/d (rember-prog q '(rember 7 (cons 3 (cons 4 (cons 7 (cons 6 '())))))) '(3 4 6))
         (evalo/d (rember-prog q '(rember 5 (cons 3 (cons 4 (cons 6 (cons 7 '())))))) '(3 4 6 7))))
     (evalo (rember-prog q '(rember 5 '())) '())
     (evalo (rember-prog q '(rember 6 (cons 6 '()))) '())
     (evalo (rember-prog q '(rember 7 (cons 3 (cons 4 (cons 7 (cons 6 '())))))) '(3 4 6))
     (evalo (rember-prog q '(rember 5 (cons 3 (cons 4 (cons 6 (cons 7 '())))))) '(3 4 6 7)))))
