;; Tests for refutation via an evalo/d follower. The main search offers a 
;; fixed set of options via conde while the follower evaluates examples 
;; against each candidate and kills branches that can't produce the right output.

;; Shape refutation: cons can't produce '()
(test "cons vs l for identity"
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

;; Shape refutation: quote can't vary with input
(test "quote vs l"
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

;; Match with wrong base case. f should be identity.
;; Base case '() -> '() is right, base case '() -> '(1) is wrong.
(test "match wrong base vs right base"
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

;; Rember: three candidate else-branches.
;; d = just the tail, l = the whole list, (rember e d) = correct.
(test "rember else-branch"
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

;; Follower refutes a shape with a HOLE: (cons 1 HOLE) vs l.
(test "cons-with-hole vs l"
  (run* (q)
    (follower
      q
      (evalo/d `(letrec ([f (lambda (l) : ((list) -> list)
                              ,q)])
                  (f '()))
               '()))
    (conde
      ((fresh (e)
         (== q `(cons 1 ,e))))
      ((== q 'l))))
  '(l))

;; Return type mismatch: match produces a list, but output is a number.
(test "number output with match vs literal"
  (run* (q)
    (follower
      q
      (evalo/d `(letrec ([f (lambda (l) : ((list) -> number)
                              ,q)])
                  (f '()))
               5))
    (conde
      ((== q
           '(match l
              ['() '()]
              [(cons a d) a])))
      ((== q 5))))
  '(5))

;; Cross-example refutation: l works for ex1 but fails for ex2.
(test "cross-example refutation"
  (run* (q)
    (follower
      q
      (fresh/d ()
        (evalo/d `(letrec ([f (lambda (l) : ((list) -> list)
                                ,q)])
                    (f '()))
                 '(1))
        (evalo/d `(letrec ([f (lambda (l) : ((list) -> list)
                                ,q)])
                    (f (cons 2 '())))
                 '(1 2))))
    (conde
      ((== q 'l))
      ((== q '(cons 1 l)))))
  '((cons 1 l)))

;; Follower refutes wrong branch via interpreter.
(test "follower refutes wrong branch via interpreter"
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
                    (f (cons 3 '())))
                 '(3))))
    (conde
      ((== q '(cons 1 '())))
      ((== q 'l))))
  '(l))

;; Follower refutes constant via non-empty example.
(test "follower refutes constant via non-empty example"
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
                    (f (cons 5 '())))
                 '(5))))
    (conde
      ((== q ''()))
      ((== q 'l))))
  '(l))

;; Follower picks cons 1 l over identity and constant.
(test "follower picks cons 1 l over identity and constant"
  (run* (q)
    (follower
      q
      (fresh/d ()
        (evalo/d `(letrec ([f (lambda (l) : ((list) -> list)
                                ,q)])
                    (f '()))
                 '(1))
        (evalo/d `(letrec ([f (lambda (l) : ((list) -> list)
                                ,q)])
                    (f (cons 2 '())))
                 '(1 2))))
    (conde
      ((== q 'l))
      ((== q ''(1)))
      ((== q '(cons 1 l)))))
  '((cons 1 l)))

;; Follower refutes wrong rember else-branch.
(test "follower refutes wrong rember else-branch"
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
      ((== q ''()))
      ((== q '(rember e d)))))
  '((rember e d)))

;; Follower refutes two candidates, picks identity.
(test "follower refutes two candidates, picks identity"
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
                    (f (cons 3 '())))
                 '(3))
        (evalo/d `(letrec ([f (lambda (l) : ((list) -> list)
                                ,q)])
                    (f (cons 7 (cons 8 '()))))
                 '(7 8))))
    (conde
      ((== q ''()))
      ((== q '(cons 1 l)))
      ((== q 'l))))
  '(l))
