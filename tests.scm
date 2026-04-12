(load "load.scm")
(load "restricted-interp.scm")
(load "restricted-interp-following.scm")

(test "conde/d commit"
  (run* (q)
    (follower
      '()
      (fresh/d (x)
        (==/d x 1)
        (conde/d
          ([]
           [(==/d x 1)]
           [(==/d q 1)])
          ([]
           [(==/d x 2)]
           [(==/d q 2)])))))
  '(1))

(test "conde/d nondet"
  (run* (q)
    (follower
      '()
      (fresh/d (x)
        (conde/d
          ([]
           [(==/d x 1)]
           [(==/d q 1)])
          ([]
           [(==/d x 2)]
           [(==/d q 2)])))))
  '(_.0))

(test "conde/d commit outer, nondet inner, nested"
  (run* (q)
    (follower
      '()
      (fresh/d (x y a b)
        (==/d q (cons a b))
        (==/d x 1)
        (conde/d
          ([]
           [(==/d x 1)]
           [(==/d a 1)
            (conde/d
              ([]
               [(==/d y 1)]
               [(==/d b 1)])
              ([]
               [(==/d y 2)]
               [(==/d b 2)]))])
          ([]
           [(==/d x 2)]
           [(==/d a 2)])))))
  '((1 . _.0)))

(test "conde/d commit first, nondet second, conjunction"
  (run* (q)
    (follower
      '()
      (fresh/d (x y a b)
        (==/d q (cons a b))
        (==/d x 1)
        (conde/d
          ([]
           [(==/d x 1)]
           [(==/d a 1)])
          ([]
           [(==/d x 2)]
           [(==/d a 2)]))
        (conde/d
          ([]
           [(==/d y 1)]
           [(==/d b 1)])
          ([]
           [(==/d y 2)]
           [(==/d b 2)])))))
  '((1 . _.0)))

(test "conde/d nondet first, det second; commits second"
  (run* (q)
    (follower
      '()
      (fresh/d (x y a b)
        (==/d q (cons a b))
        (==/d y 1)
        (conde/d
          ([]
           [(==/d x 1)]
           [(==/d a 1)])
          ([]
           [(==/d x 2)]
           [(==/d a 2)]))
        (conde/d
          ([]
           [(==/d y 1)]
           [(==/d b 1)])
          ([]
           [(==/d y 2)]
           [(==/d b 2)])))))
  '((_.0 . 1)))

(test "conde/d nondet first, det second; commits second; return to first"
  (run* (q)
    (fresh (x y a b)
      (follower
        (list x y a b)
        (fresh/d ()
          (==/d q (cons a b))
          (==/d y 1)
          (conde/d
            ([]
             [(==/d x 1)]
             [(==/d a 1)])
            ([]
             [(==/d x 2)]
             [(==/d a 2)]))
          (conde/d
            ([]
             [(==/d y 1)]
             [(==/d b 1)])
            ([]
             [(==/d y 2)]
             [(==/d b 2)]))))
      (== x 1)))
  '((1 . 1)))

(test "conde/d interp should eval ground program 1"
  (run 1 (q)
    (follower
      '()
      (evalo/d '1 q)))
  '(1))

(test "conde/d interp should eval ground program 2"
  (run 1 (q)
    (follower
      '()
      (evalo/d '(cons 1 '()) q)))
  '((1)))

(test "conde/d interp partial 1 resume"
  (run 1 (q)
    (fresh (p)
      (follower
        (list p)
        (evalo/d `(cons 1 ,p) q))
      (== p ''())))
  '((1)))

(test "conde/d interp partial 2"
  (run 1 (q)
    (fresh (p)
      (follower
        (list p)
        (evalo/d `(cons 1 (cons ,p '())) q))))
  '((1 _.0)))

(test "conde/d interp partial 2 resume"
  (run 1 (q)
    (fresh (p)
      (follower
        (list p)
        (evalo/d `(cons 1 (cons ,p '())) q))
      (== p 2)))
  '((1 2)))

(test "conde/d interp partial refute"
  (run* (e v)
    (fresh (e1 v1)
      (== e `(cons ,e1 (cons 5 '())))
      (== v `(,v1 6))
      (follower
        '()
        (evalo/d e v))
      (evalo e v)))
  '())

(test "conde/d interp partial 3 resume"
  (run 1 (q)
    (fresh (p)
      (follower
        (list p)
        (evalo/d `(letrec ([double (lambda (l) : ((list) -> list)
                                     ,p)])
                    (double (cons 1 (cons 2 (cons 3 '())))))
                 q))
      (== p 'l)))
  '((1 2 3)))

(test "conde/d interp should eval ground program identity"
  (run 1 (q)
    (follower
      '()
      (evalo/d '(letrec ([double (lambda (l) : ((list) -> list)
                                   l)])
                  (double (cons 1 (cons 2 (cons 3 '())))))
               q)))
  '((1 2 3)))

(test "conde/d interp should eval ground program cons-if-eq"
  (run 1 (q)
    (follower
      '()
      (evalo/d '(letrec ([cons-if-= (lambda (v1 v2 l) : ((number number list) -> list)
                                      (if (= v1 v2)
                                          (cons v1 l)
                                          l))])
                  (cons-if-= 1 1 (cons 1 (cons 2 (cons 3 '())))))
               q)))
  '((1 1 2 3)))

(test "conde/d interp resume cons-if-eq 1"
  (run 1 (q)
    (fresh (p1 p2 p3)
      (follower
        (list p1)
        (evalo/d `(letrec ([cons-if-= (lambda (v1 v2 l) : ((number number list) -> list)
                                        ,p1)])
                    (cons-if-= 1 1 (cons 1 (cons 2 (cons 3 '())))))
                 q))
      (== p1 `(if ,p2 ,p3 l))
      (conde
        (succeed))
      (== p3 '(cons v1 l))
      (conde
        (succeed))
      (== p2 '(= v1 v2))

      (evalo `(letrec ([cons-if-= (lambda (v1 v2 l) : ((number number list) -> list)
                                    ,p1)])
                (cons-if-= 1 1 (cons 1 (cons 2 (cons 3 '())))))
             q)))
  '((1 1 2 3)))

(parameterize ([*suspend-depth* 1000])
  (test "conde/d interp resume rember 1"
    (run 1 (q)
      (fresh (p)
        (follower
          (list p)
          (evalo/d `(letrec ([rember (lambda (e l) : ((number list) -> list)
                                       ,p)])
                      (rember 5 (cons 3 (cons 4 (cons 6 (cons 7 '()))))))
                   q))
        (== p
            '(match l
               ['() l]
               [(cons _.0 _.1)
                (if (= _.0 e)
                    _.1
                    (cons _.0 (rember e _.1)))]))))
    '((3 4 6 7))))

(parameterize ([*suspend-depth* 1000])
  (test "conde/d interp should eval ground program rember 1"
    (run 1 (q)
      (follower
        '()
        (evalo/d '(letrec ([rember (lambda (e l) : ((number list) -> list)
                                     (match l
                                       ['() l]
                                       [(cons _.0 _.1)
                                        (if (= _.0 e)
                                            _.1
                                            (cons _.0 (rember e _.1)))]))])
                    (rember 5 (cons 3 (cons 4 (cons 6 (cons 7 '()))))))
                 q)))
    '((3 4 6 7))))

(parameterize ([*suspend-depth* 1000])
  (test "conde/d interp should eval ground program rember 2"
    (run 1 (q)
      (follower
        '()
        (evalo/d '(letrec ([rember (lambda (e l) : ((number list) -> list)
                                     (match l
                                       ['() l]
                                       [(cons _.0 _.1)
                                        (if (= _.0 e)
                                            _.1
                                            (cons _.0 (rember e _.1)))]))])
                    (rember 7 (cons 3 (cons 4 (cons 7 (cons 6 '()))))))
                 q)))
    '((3 4 6))))

(time
  (test "interp eval ground program rember all"
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
    '((() () (3 4 6) (3 4 6 7)))))

(parameterize ([*suspend-depth* 1000])
  (time
    (test "conde/d interp eval ground program rember all"
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
      '((() () (3 4 6) (3 4 6 7))))))
