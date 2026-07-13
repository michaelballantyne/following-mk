;; rember-symbolic-id-nofollower.scm --- WAVE 2a baseline: the symbolic-example
;; spec of rember-symbolic-id-ty.scm with NO follower.  Tests prediction 4 of
;; the wave-2 design: does the main search ALONE handle symbolic-example specs,
;; or does it (like every ground-spec baseline) stay infeasible?  Same symbolic
;; examples, bounds, absento, and untyped template as the follower arm.

(load "restricted-interp-untyped.scm")
(load "restricted-interp-untyped-following.scm")
(load "experiments/id-harness.scm")
(load "views.scm")

(define (rember-prog-u q body)
  `(letrec ([rember (lambda (e l)
                      ,q)])
     ,body))

(run-id "rember-symbolic/no-follower" '(15 19 23 27 31 35 39 43 47 51) 1000
  (lambda (bound)
    (run 1 (q)
      (fresh (x1 x2 x3 ea eb)
        (watch-size q)
        (absento 3 q)
        (absento 4 q)
        (absento 5 q)
        (absento 6 q)
        (absento 7 q)
        (numbero x1)
        (numbero x2)
        (numbero x3)
        (numbero ea)
        (numbero eb)
        (=/= ea x1)
        (=/= ea x2)
        (=/= eb x3)
        (=/= x1 x2)
        (evalo-u (rember-prog-u q `(rember ,ea (cons ,x1 (cons ,x2 '())))) `(,x1 ,x2))
        (evalo-u (rember-prog-u q `(rember ,eb (cons ,eb (cons ,x3 '())))) `(,x3))
        (evalo-u (rember-prog-u q `(rember ,x1 (cons ,x1 (cons ,x2 '())))) `(,x2))))))
