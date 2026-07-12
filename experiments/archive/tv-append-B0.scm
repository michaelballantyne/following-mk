;; Arm B0: append-full, existing follower (evalo/d of both examples only).
(define (append-prog q body)
  `(letrec ([append (lambda (l s) : ((list list) -> list)
                      ,q)])
     ,body))

(printf "=== ARM B0: append-full, evalo/d follower ===\n")
(time
 (printf "ANSWER: ~s\n"
   (run 1 (q)
     (absento 3 q) (absento 4 q) (absento 5 q) (absento 6 q) (absento 7 q)
     (follower q
       (fresh/d ()
         (evalo/d (append-prog q '(append '() (cons 5 (cons 6 '())))) '(5 6))
         (evalo/d (append-prog q '(append (cons 3 (cons 4 (cons 5 '()))) (cons 6 (cons 7 '()))))
                  '(3 4 5 6 7))))
     (evalo (append-prog q '(append '() (cons 5 (cons 6 '())))) '(5 6))
     (evalo (append-prog q '(append (cons 3 (cons 4 (cons 5 '()))) (cons 6 (cons 7 '()))))
            '(3 4 5 6 7)))))
