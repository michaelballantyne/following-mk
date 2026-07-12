;; Arm B0: rember-full, existing follower (evalo/d of all 4 examples only).
;; Baseline; known not to terminate in reasonable time.
(define (rember-prog q body)
  `(letrec ([rember (lambda (e l) : ((number list) -> list)
                      ,q)])
     ,body))

(printf "=== ARM B0: rember-full, evalo/d follower ===\n")
(time
 (printf "ANSWER: ~s\n"
   (run 1 (q)
     (absento 3 q) (absento 4 q) (absento 5 q) (absento 6 q) (absento 7 q)
     (follower q
       (fresh/d ()
         (evalo/d (rember-prog q '(rember 5 '())) '())
         (evalo/d (rember-prog q '(rember 6 (cons 6 '()))) '())
         (evalo/d (rember-prog q '(rember 7 (cons 3 (cons 4 (cons 7 (cons 6 '())))))) '(3 4 6))
         (evalo/d (rember-prog q '(rember 5 (cons 3 (cons 4 (cons 6 (cons 7 '())))))) '(3 4 6 7))))
     (evalo (rember-prog q '(rember 5 '())) '())
     (evalo (rember-prog q '(rember 6 (cons 6 '()))) '())
     (evalo (rember-prog q '(rember 7 (cons 3 (cons 4 (cons 7 (cons 6 '())))))) '(3 4 6))
     (evalo (rember-prog q '(rember 5 (cons 3 (cons 4 (cons 6 (cons 7 '())))))) '(3 4 6 7)))))
