;; Arm A: rember-full, NO follower (pure leader, 4 evalo examples).
;; Baseline; known not to terminate in reasonable time.
(define (rember-prog q body)
  `(letrec ([rember (lambda (e l) : ((number list) -> list)
                      ,q)])
     ,body))

(printf "=== ARM A: rember-full, no follower ===\n")
(time
 (printf "ANSWER: ~s\n"
   (run 1 (q)
     (absento 3 q) (absento 4 q) (absento 5 q) (absento 6 q) (absento 7 q)
     (evalo (rember-prog q '(rember 5 '())) '())
     (evalo (rember-prog q '(rember 6 (cons 6 '()))) '())
     (evalo (rember-prog q '(rember 7 (cons 3 (cons 4 (cons 7 (cons 6 '())))))) '(3 4 6))
     (evalo (rember-prog q '(rember 5 (cons 3 (cons 4 (cons 6 (cons 7 '())))))) '(3 4 6 7)))))
