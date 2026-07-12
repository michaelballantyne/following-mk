;; Arm B2: append-full, follower = base-case-patho/d ONLY (no evalo/d).
(load "views.scm")
(define (append-prog q body)
  `(letrec ([append (lambda (l s) : ((list list) -> list)
                      ,q)])
     ,body))

(printf "=== ARM B2: append-full, base-case-patho/d-only follower ===\n")
(time
 (printf "ANSWER: ~s\n"
   (run 1 (q)
     (absento 3 q) (absento 4 q) (absento 5 q) (absento 6 q) (absento 7 q)
     (follower q (base-case-patho/d 'append q))
     (evalo (append-prog q '(append '() (cons 5 (cons 6 '())))) '(5 6))
     (evalo (append-prog q '(append (cons 3 (cons 4 (cons 5 '()))) (cons 6 (cons 7 '()))))
            '(3 4 5 6 7)))))
