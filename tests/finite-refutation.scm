;; Tests for refutation via an evalo/d follower. The main search offers a
;; fixed set of options via conde while the follower evaluates examples
;; against each candidate and kills branches that can't produce the right output.

(test "refute cons shape: always produces a pair, not '()"
  (run* (q)
    (follower
      q
      (evalo/d `(letrec ([f (lambda (l) : ((list) -> list)
                              ,q)])
                  (f '()))
               '()))
    (conde
      ((fresh (e1 e2)
         (== q `(cons ,e1 ,e2))))
      ((== q 'l))))
  '(l))

(test "refute unknown quoted constant: can't vary with input"
  (run* (q)
    (follower
      q
      (fresh/d ()
        (evalo/d `(letrec ([f (lambda (l) : ((list) -> list)
                                ,q)])
                    (f '()))
                 '())
        (evalo/d `(letrec ([f (lambda (l) : ((list) -> list)
                                ,q)])
                    (f (cons 1 '())))
                 '(1))))
    (conde
      ((fresh (v)
         (== q `',v)))
      ((== q 'l))))
  '(l))

(test "refute type mismatch: returns list, not number"
  (run* (q)
    (fresh (v)
      (follower
        q
        (evalo/d `(letrec ([f (lambda (l) : ((list) -> number)
                                ,q)])
                    (f '()))
                 v))
      (conde
        ((== q
             '(match l
                ['() '()]
                [(cons a d) d])))
        ((== q 5)))))
  '(5))


(test "refute type mismatch: match branch types inconsistent"
  ;; Note that we do need to run both examples here because typechecking
  ;; is combined with interpretation and only inspects evaluated expressions.
  (run* (q)
    (fresh (v1 v2 return-type)
      (follower
        q
        (fresh/d ()
          (evalo/d `(letrec ([f (lambda (l) : ((list) -> ,return-type)
                                  ,q)])
                      (f '()))
                   v1)
          (evalo/d `(letrec ([f (lambda (l) : ((list) -> ,return-type)
                                  ,q)])
                      (f (cons 1 '())))
                   v2)))
      (conde
        ((== q
             '(match l
                ['() '()]
                [(cons a d) a])))
        ((== q 'l)))))
  '(l))

(test "refute wrong match base case"
  (run* (q)
    (follower
      q
      (fresh/d ()
        (evalo/d `(letrec ([f (lambda (l) : ((list) -> list)
                                ,q)])
                    (f '()))
                 '())
        (evalo/d `(letrec ([f (lambda (l) : ((list) -> list)
                                ,q)])
                    (f (cons 1 '())))
                 '(1))))
    (conde
      ((== q
           '(match l
              ['() '(1)]
              [(cons a d) (cons a (f d))])))
      ((== q
           '(match l
              ['() l]
              [(cons a d) (cons a (f d))])))))
  '((match l
      ['() l]
      [(cons a d) (cons a (f d))])))

(test "refute wrong rember else-branches"
  (run* (q)
    (follower
      q
      (fresh/d ()
        (evalo/d `(letrec ([rember (lambda (e l) : ((number list) -> list)
                                     (match l
                                       ['() l]
                                       [(cons a d)
                                        (if (= a e)
                                            d
                                            (cons a ,q))]))])
                    (rember 5 '()))
                 '())
        (evalo/d `(letrec ([rember (lambda (e l) : ((number list) -> list)
                                     (match l
                                       ['() l]
                                       [(cons a d)
                                        (if (= a e)
                                            d
                                            (cons a ,q))]))])
                    (rember 5 (cons 3 (cons 4 (cons 5 '())))))
                 '(3 4))))
    (conde
      ((== q 'd))
      ((== q 'l))
      ((== q '(rember e d)))))
  '((rember e d)))