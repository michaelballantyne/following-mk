;; Tests for the leading/following evaluator interaction: the main search drives
;; evaluation via evalo (the "leader"), and the follower runs evalo/d
;; to prune or propagate.

;;; --- full leader/follower rember evaluation (timed, for comparison)

(time-test "interp eval ground program rember all"
  (run 1 (v1 v2 v3 v4)
    (fresh (q)
      (== q
          '(match l
             ['() l]
             [(cons a d)
              (if (= a e)
                  d
                  (cons a (rember e d)))]))
      (absento 3 q)
      (absento 4 q)
      (absento 5 q)
      (absento 6 q)
      (absento 7 q)
      (evalo `(letrec ([rember (lambda (e l) : ((number list) -> list)
                                 (match l
                                   ['() l]
                                   [(cons a d)
                                    (if (= a e)
                                        d
                                        (cons a (rember e d)))]))])
                (rember 5 '()))
             v1)

      (evalo `(letrec ([rember (lambda (e l) : ((number list) -> list)
                                 ,q)])
                (rember 6 (cons 6 '())))
             v2)

      (evalo `(letrec ([rember (lambda (e l) : ((number list) -> list)
                                 ,q)])
                (rember 7 (cons 3 (cons 4 (cons 7 (cons 6 '()))))))
             v3)

      (evalo `(letrec ([rember (lambda (e l) : ((number list) -> list)
                                 ,q)])
                (rember 5 (cons 3 (cons 4 (cons 6 (cons 7 '()))))))
             v4)))
  '((() () (3 4 6) (3 4 6 7))))

(parameterize ([*suspend-depth* 1000])
  (time-test "conde/d interp eval ground program rember all"
    (run 1 (v1 v2 v3 v4)
      (fresh (q)
        (== q
            '(match l
               ['() l]
               [(cons a d)
                (if (= a e)
                    d
                    (cons a (rember e d)))]))
        (absento 3 q)
        (absento 4 q)
        (absento 5 q)
        (absento 6 q)
        (absento 7 q)
        (follower
          '()
          (fresh/d ()
            (evalo/d `(letrec ([rember (lambda (e l) : ((number list) -> list)
                                         (match l
                                           ['() l]
                                           [(cons a d)
                                            (if (= a e)
                                                d
                                                (cons a (rember e d)))]))])
                        (rember 5 '()))
                     v1)
            (evalo/d `(letrec ([rember (lambda (e l) : ((number list) -> list)
                                         ,q)])
                        (rember 6 (cons 6 '())))
                     v2)
            (evalo/d `(letrec ([rember (lambda (e l) : ((number list) -> list)
                                         ,q)])
                        (rember 7 (cons 3 (cons 4 (cons 7 (cons 6 '()))))))
                     v3)
            (evalo/d `(letrec ([rember (lambda (e l) : ((number list) -> list)
                                         ,q)])
                        (rember 5 (cons 3 (cons 4 (cons 6 (cons 7 '()))))))
                     v4)))))
    '((() () (3 4 6) (3 4 6 7)))))

;;; --- leader-driven search with follower pruning

(parameterize ([*check-follower-every* 1])
  (test "follower refutes wrong top-level form"
    (run 1 (q)
      (absento 'closure q)
      (follower
        q
        (fresh/d ()
          (evalo/d `(letrec ([f (lambda (l) : ((list) -> list)
                                  ,q)])
                      (f '()))
                   '())
          (evalo/d `(letrec ([f (lambda (l) : ((list) -> list)
                                  ,q)])
                      (f (cons 3 '())))
                   '(3))))
      (evalo `(letrec ([f (lambda (l) : ((list) -> list)
                            ,q)])
                (f '()))
             '())
      (evalo `(letrec ([f (lambda (l) : ((list) -> list)
                            ,q)])
                (f (cons 3 '())))
             '(3)))
    '(l)))

(parameterize ([*check-follower-every* 1])
  (test "follower refutes constant expression"
    (run 1 (q)
      (absento 'closure q)
      (follower
        q
        (fresh/d ()
          (evalo/d `(letrec ([id (lambda (l) : ((list) -> list)
                                   ,q)])
                      (id (cons 1 (cons 2 '()))))
                   '(1 2))
          (evalo/d `(letrec ([id (lambda (l) : ((list) -> list)
                                   ,q)])
                      (id (cons 3 (cons 4 '()))))
                   '(3 4))))
      (evalo `(letrec ([id (lambda (l) : ((list) -> list)
                             ,q)])
                (id (cons 1 (cons 2 '()))))
             '(1 2))
      (evalo `(letrec ([id (lambda (l) : ((list) -> list)
                             ,q)])
                (id (cons 3 (cons 4 '()))))
             '(3 4)))
    '(l)))

;;; --- leader/follower with different example placement

(parameterize ([*check-follower-every* 1])
  (test "leader empty, follower non-empty"
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
             '()))
    '(l)))

(parameterize ([*check-follower-every* 1])
  (test "leader empty, follower prepend"
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
             '(1 2)))
    '((cons 1 l))))
