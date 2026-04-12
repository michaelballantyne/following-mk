;; Rember synthesis comparison: with and without follower, in easy-first
;; and hard-first example orderings. Run via `./run.sh ex2.scm`.

;; Rember with follower: leader has both examples, follower also has
;; the hard example. Compare work with and without follower.
(time-example "rember with follower"
  (run 1 (q)
    (absento 'closure q)
    (absento 3 q)
    (absento 4 q)
    (follower
      q
      (evalo/d `(letrec ([rember (lambda (e l) : ((number list) -> list)
                                   ,q)])
                  (rember 6 (cons 5 (cons 6 '()))))
               '(5)))
    (evalo `(letrec ([rember (lambda (e l) : ((number list) -> list)
                               ,q)])
              (rember 5 '()))
           '())
    (evalo `(letrec ([rember (lambda (e l) : ((number list) -> list)
                               ,q)])
              (rember 6 (cons 5 (cons 6 '()))))
           '(5))))

;; Rember without follower: both examples in the leader, easy first.
(time-example "rember without follower (easy first)"
  (run 1 (q)
    (absento 'closure q)
    (absento 3 q)
    (absento 4 q)
    (evalo `(letrec ([rember (lambda (e l) : ((number list) -> list)
                               ,q)])
              (rember 5 '()))
           '())
    (evalo `(letrec ([rember (lambda (e l) : ((number list) -> list)
                               ,q)])
              (rember 6 (cons 5 (cons 6 '()))))
           '(5))))

;; Rember with follower, hard example first in leader.
(time-example "rember with follower (hard first)"
  (run 1 (q)
    (absento 'closure q)
    (absento 3 q)
    (absento 4 q)
    (follower
      q
      (evalo/d `(letrec ([rember (lambda (e l) : ((number list) -> list)
                                   ,q)])
                  (rember 6 (cons 5 (cons 6 '()))))
               '(5)))
    (evalo `(letrec ([rember (lambda (e l) : ((number list) -> list)
                               ,q)])
              (rember 6 (cons 5 (cons 6 '()))))
           '(5))
    (evalo `(letrec ([rember (lambda (e l) : ((number list) -> list)
                               ,q)])
              (rember 5 '()))
           '())))

;; Rember without follower, hard example first in leader.
(time-example "rember without follower (hard first)"
  (run 1 (q)
    (absento 'closure q)
    (absento 3 q)
    (absento 4 q)
    (evalo `(letrec ([rember (lambda (e l) : ((number list) -> list)
                               ,q)])
              (rember 6 (cons 5 (cons 6 '()))))
           '(5))
    (evalo `(letrec ([rember (lambda (e l) : ((number list) -> list)
                               ,q)])
              (rember 5 '()))
           '())))
