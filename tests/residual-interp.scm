;; The /d relational interpreter, ported to the residual engine's constructors
;; -- see residual-interp-following.scm for the relation definitions
;; (evalo/d-res, eval-expo/d-res, lookupo/d-res, etc.) -- plus the
;; following-interpreter.scm and refutation.scm tests re-run through it. Same
;; expected answers as the closure-engine originals => decision-equivalence on
;; ground eval, partial eval, suspend/resume, and refutation -- the full
;; engine surface.

(load "residual-interp-following.scm")

;;; ================================================================
;;; following-interpreter.scm, ported
;;; ================================================================

(test "R-interp: duplicate lambda params rejected /d"
  (run* (q)
    (follower
      '()
      (evalo/d-r '(letrec ([f (lambda (x x) : ((number number) -> number)
                                x)])
                    (f 1 2))
                 q)))
  '())

(test "R-interp: ground program 1"
  (run 1 (q) (follower '() (evalo/d-r '1 q)))
  '(1))

(test "R-interp: ground program 2"
  (run 1 (q) (follower '() (evalo/d-r '(cons 1 '()) q)))
  '((1)))

(test "R-interp: ground program identity"
  (run 1 (q)
    (follower '()
      (evalo/d-r '(letrec ([double (lambda (l) : ((list) -> list)
                                     l)])
                    (double (cons 1 (cons 2 (cons 3 '())))))
                 q)))
  '((1 2 3)))

(test "R-interp: ground program cons-if-eq"
  (run 1 (q)
    (follower '()
      (evalo/d-r '(letrec ([cons-if-= (lambda (v1 v2 l) : ((number number list) -> list)
                                        (if (= v1 v2)
                                            (cons v1 l)
                                            l))])
                    (cons-if-= 1 1 (cons 1 (cons 2 (cons 3 '())))))
                 q)))
  '((1 1 2 3)))

(parameterize ([*suspend-depth* 1000])
  (test "R-interp: ground program rember 1"
    (run 1 (q)
      (follower '()
        (evalo/d-r '(letrec ([rember (lambda (e l) : ((number list) -> list)
                                       (match l
                                         ['() l]
                                         [(cons _.0 _.1)
                                          (if (= _.0 e)
                                              _.1
                                              (cons _.0 (rember e _.1)))]))])
                      (rember 5 (cons 3 (cons 4 (cons 6 (cons 7 '()))))))
                   q)))
    '((3 4 6 7))))

(test "R-interp: partial 2 (force only determinate)"
  (run 1 (q)
    (fresh (p)
      (follower (list p) (evalo/d-r `(cons 1 (cons ,p '())) q))))
  '((1 _.0)))

(test "R-interp: partial 1 resume"
  (run 1 (q)
    (fresh (p)
      (follower (list p) (evalo/d-r `(cons 1 ,p) q))
      (== p ''())))
  '((1)))

(test "R-interp: partial 2 resume"
  (run 1 (q)
    (fresh (p)
      (follower (list p) (evalo/d-r `(cons 1 (cons ,p '())) q))
      (== p 2)))
  '((1 2)))

(test "R-interp: partial refute"
  (run* (e v)
    (fresh (e1 v1)
      (== e `(cons ,e1 (cons 5 '())))
      (== v `(,v1 6))
      (follower '() (evalo/d-r e v))
      (evalo e v)))
  '())

(test "R-interp: partial 3 resume"
  (run 1 (q)
    (fresh (p)
      (follower (list p)
        (evalo/d-r `(letrec ([double (lambda (l) : ((list) -> list)
                                       ,p)])
                      (double (cons 1 (cons 2 (cons 3 '())))))
                   q))
      (== p 'l)))
  '((1 2 3)))

(parameterize ([*suspend-depth* 1000])
  (test "R-interp: resume rember 1"
    (run 1 (q)
      (fresh (p)
        (follower (list p)
          (evalo/d-r `(letrec ([rember (lambda (e l) : ((number list) -> list)
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

;;; ================================================================
;;; refutation.scm, ported (follower over a fixed conde candidate set)
;;; ================================================================

(test "R-refute: cons shape can't produce '()"
  (run* (q)
    (follower q
      (evalo/d-r `(letrec ([f (lambda (l) : ((list) -> list)
                                ,q)])
                    (f '()))
                 '()))
    (conde
      ((fresh (e1 e2) (== q `(cons ,e1 ,e2))))
      ((== q 'l))))
  '(l))

(test "R-refute: unknown quoted constant can't vary with input"
  (run* (q)
    (follower q
      (follower-residual-goal
        (rfresh/d ()
          (evalo/d-res `(letrec ([f (lambda (l) : ((list) -> list)
                                      ,q)])
                          (f '()))
                       '())
          (evalo/d-res `(letrec ([f (lambda (l) : ((list) -> list)
                                      ,q)])
                          (f (cons 1 '())))
                       '(1)))))
    (conde
      ((fresh (v) (== q `',v)))
      ((== q 'l))))
  '(l))

(test "R-refute: type mismatch returns list not number"
  (run* (q)
    (fresh (v)
      (follower q
        (evalo/d-r `(letrec ([f (lambda (l) : ((list) -> number)
                                  ,q)])
                      (f '()))
                   v))
      (conde
        ((== q '(match l ['() '()] [(cons a d) d])))
        ((== q 5)))))
  '(5))

(test "R-refute: match branch types inconsistent"
  (run* (q)
    (fresh (v1 v2 return-type)
      (follower q
        (follower-residual-goal
          (rfresh/d ()
            (evalo/d-res `(letrec ([f (lambda (l) : ((list) -> ,return-type)
                                        ,q)])
                            (f '()))
                         v1)
            (evalo/d-res `(letrec ([f (lambda (l) : ((list) -> ,return-type)
                                        ,q)])
                            (f (cons 1 '())))
                         v2))))
      (conde
        ((== q '(match l ['() '()] [(cons a d) a])))
        ((== q 'l)))))
  '(l))

(test "R-refute: wrong base case"
  (run* (q)
    (follower q
      (follower-residual-goal
        (rfresh/d ()
          (evalo/d-res `(letrec ([f (lambda (l) : ((list) -> list)
                                      ,q)])
                          (f '()))
                       '())
          (evalo/d-res `(letrec ([f (lambda (l) : ((list) -> list)
                                      ,q)])
                          (f (cons 1 '())))
                       '(1)))))
    (conde
      ((== q '(match l ['() '(1)] [(cons a d) (cons a (f d))])))
      ((== q '(match l ['() l] [(cons a d) (cons a (f d))])))))
  '((match l ['() l] [(cons a d) (cons a (f d))])))

(test "R-refute: wrong rember else-branches"
  (run* (q)
    (follower q
      (follower-residual-goal
        (rfresh/d ()
          (evalo/d-res `(letrec ([rember (lambda (e l) : ((number list) -> list)
                                           (match l
                                             ['() l]
                                             [(cons a d)
                                              (if (= a e)
                                                  d
                                                  (cons a ,q))]))])
                          (rember 5 '()))
                       '())
          (evalo/d-res `(letrec ([rember (lambda (e l) : ((number list) -> list)
                                           (match l
                                             ['() l]
                                             [(cons a d)
                                              (if (= a e)
                                                  d
                                                  (cons a ,q))]))])
                          (rember 5 (cons 3 (cons 4 (cons 5 '())))))
                       '(3 4)))))
    (conde
      ((== q 'd))
      ((== q 'l))
      ((== q '(rember e d)))))
  '((rember e d)))
