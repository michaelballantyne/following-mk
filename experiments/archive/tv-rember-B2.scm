;; Arm B2: rember-full, follower = base-case-patho/d ONLY (no evalo/d).
;; Isolates the termination view's contribution: the leader still checks the
;; 4 examples via evalo; the follower only refutes caseless bodies.
;; Loads experiments/termination-view.scm (definitions + self-checks) first.
(load "views.scm")
(define (rember-prog q body)
  `(letrec ([rember (lambda (e l) : ((number list) -> list)
                      ,q)])
     ,body))

(printf "=== ARM B2: rember-full, base-case-patho/d-only follower ===\n")
(time
 (printf "ANSWER: ~s\n"
   (run 1 (q)
     (absento 3 q) (absento 4 q) (absento 5 q) (absento 6 q) (absento 7 q)
     (follower q (base-case-patho/d 'rember q))
     (evalo (rember-prog q '(rember 5 '())) '())
     (evalo (rember-prog q '(rember 6 (cons 6 '()))) '())
     (evalo (rember-prog q '(rember 7 (cons 3 (cons 4 (cons 7 (cons 6 '())))))) '(3 4 6))
     (evalo (rember-prog q '(rember 5 (cons 3 (cons 4 (cons 6 (cons 7 '())))))) '(3 4 6 7)))))
