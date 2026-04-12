;; One example in the leader (main search), another in the follower.
;; The leader's evalo finds candidates that satisfy example 1.
;; The follower's evalo/d checks example 2 and should filter out
;; candidates that pass example 1 but fail example 2.

(*check-follower-every* 1)

;; q is the body of f. Leader checks f('()) = '().
;; Follower checks f((1)) = (1).
;; '() satisfies the leader (returns '() for empty input) but the
;; follower should reject it (can't return (1) for non-empty input).
;; l satisfies both.
(example "leader: f('')='(), follower: f((1))=(1)"
  (run 1 (q)
    (absento 'closure q)
    (follower
      q
      (evalo/d `(letrec ([f (lambda (l) : ((list) -> list)
                              ,q)])
                  (f (cons 1 '())))
               '(1)))
    (evalo `(letrec ([f (lambda (l) : ((list) -> list)
                          ,q)])
              (f '()))
           '())))

;; Same idea but with cons: leader checks f('()) = (1).
;; Follower checks f((2)) = (1 2).
;; (cons 1 '()) satisfies the leader but follower rejects it.
;; (cons 1 l) satisfies both.
(example "leader: f('')=(1), follower: f((2))=(1 2)"
  (run 1 (q)
    (absento 'closure q)
    (follower
      q
      (evalo/d `(letrec ([f (lambda (l) : ((list) -> list)
                              ,q)])
                  (f (cons 2 '())))
               '(1 2)))
    (evalo `(letrec ([f (lambda (l) : ((list) -> list)
                          ,q)])
              (f '()))
           '(1))
    (evalo `(letrec ([f (lambda (l) : ((list) -> list)
                          ,q)])
              (f (cons 2 '())))
           '(1 2))))

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
