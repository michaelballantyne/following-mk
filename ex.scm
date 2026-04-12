(*check-follower-every* 1)

;; 1. Shape refutation: cons can't produce '()
(example "cons vs l for identity"
  (run 1 (q)
    (follower
      q
      (evalo/d `(letrec ([f (lambda (l) : ((list) -> list)
                              ,q)])
                  (f '()))
               '()))
    (conde
      ((fresh (e1 e2)
         (== q `(cons ,e1 ,e2))))
      ((== q 'l)))))

;; 2. Shape refutation: quote can't vary with input
(example "quote vs l"
  (run 1 (q)
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
      ((== q 'l)))))

;; 3. Deeper: match with wrong base case.
;; f should be identity. Base case '() -> '() is right,
;; base case '() -> '(1) is wrong. Follower should refute.
(example "match wrong base vs right base"
  (run 1 (q)
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
              [(cons a d) (cons a (f d))]))))))

;; 4. Rember: three candidate else-branches with partially known skeleton.
;; d = just the tail (drops non-matching elements after first),
;; l = the whole original list (never removes anything),
;; (rember e d) = correct recursive call.
(example "rember else-branch"
  (run 1 (q)
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
      ((== q '(rember e d))))))

;; 5. Can the follower refute a shape with a HOLE in it?
;; q = (cons 1 HOLE) vs q = l. The cons shape can't produce '().
(example "cons-with-hole vs l"
  (run 1 (q)
    (follower
      q
      (evalo/d `(letrec ([f (lambda (l) : ((list) -> list)
                              ,q)])
                  (f '()))
               '()))
    (conde
      ((fresh (e)
         (== q `(cons 1 ,e))))
      ((== q 'l)))))

;; 6. Can the follower refute a shape when the RETURN TYPE is wrong?
;; q must produce a number, but match always produces a list here.
(example "number output with match vs literal"
  (run 1 (q)
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
      ((== q 5)))))

;; 7. Two evalo/d conjuncts — can the follower cross-refute?
;; q = 'l works for example 1 (identity) but fails for example 2
;; (must prepend 1). q = '(cons 1 l) works for both.
(example "cross-example refutation"
  (run 1 (q)
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
      ((== q '(cons 1 l))))))

;; 8. Application shape: (f HOLE) — can follower tell it's wrong
;; when there's no f in scope? The application clause needs rator
;; to eval to a closure, but there's nothing in the env.
(example "application with nothing in scope"
  (run 1 (q)
    (follower
      q
      (evalo/d `(letrec ([f (lambda (l) : ((list) -> list)
                              ,q)])
                  (f '()))
               '()))
    (conde
      ((fresh (e1 e2)
         (== q `(,e1 ,e2))))
      ((== q 'l)))))

;; 9. Letrec shape for a non-recursive function — the follower should
;; be able to handle this but it might hit depth limits.
(example "letrec vs l for identity"
  (run 1 (q)
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
      ((fresh (name args typ body inner)
         (== q
             `(letrec ([,name (lambda ,args : ,typ
                                ,body)])
                ,inner))))
      ((== q 'l)))))
