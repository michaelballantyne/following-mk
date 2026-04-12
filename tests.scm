(load "load.scm")
(load "restricted-interp.scm")
(load "restricted-interp-following.scm")

(test "duplicate lambda params rejected"
  (run* (q)
    (evalo '(letrec ([f (lambda (x x) : ((number number) -> number)
                          x)])
              (f 1 2))
           q))
  '())

(test "duplicate lambda params rejected /d"
  (run* (q)
    (follower
      '()
      (evalo/d '(letrec ([f (lambda (x x) : ((number number) -> number)
                              x)])
                  (f 1 2))
               q)))
  '())

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

;;; --- follower refutation tests
;;;
;;; These test the follower's ability to prune wrong branches in the main
;;; search. The main search explores different program structures for q;
;;; the follower evaluates examples against each candidate and kills
;;; branches that can't produce the right output. With check-follower-every
;;; = 1, the follower fires right after the main search commits to a
;;; structure, giving immediate refutation.

;; The main search might try q = (cons ...) or q = (quote ...) before
;; finding q = (match ...). The follower should refute the wrong forms
;; immediately: (cons ...) evaluated in empty env can't produce '() for
;; the base case, and a quoted value can't depend on the input.
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

;; q is the body of a function that should return its input unchanged
;; for 2-element lists but the main search might try a constant like
;; '() or a cons of literals. The follower checks two examples and
;; refutes anything that doesn't vary with the input.
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

;; The main search tries two bodies for f: (cons 1 '()) which is
;; wrong (produces (1) not (3)), and l which is right. The follower
;; refutes the cons branch via the second example.
(parameterize ([*check-follower-every* 1])
  (test "follower refutes wrong branch via interpreter"
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
                      (f (cons 3 '())))
                   '(3))))
      (conde
        ((== q '(cons 1 '())))
        ((== q 'l))))
    '(l)))

(parameterize ([*check-follower-every* 1])
  (test "follower refutes constant via non-empty example"
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
                      (f (cons 5 '())))
                   '(5))))
      (conde
        ((== q ''()))
        ((== q 'l))))
    '(l)))

;; Main search picks between three specific bodies for a function that
;; prepends 1: l (identity — wrong), '(1) (constant — wrong for
;; non-empty input), (cons 1 l) (correct). Follower refutes the first
;; two via two examples.
(parameterize ([*check-follower-every* 1])
  (test "follower picks cons 1 l over identity and constant"
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
        ((== q ''(1)))
        ((== q '(cons 1 l)))))
    '((cons 1 l))))

;; Main search has a partially-known rember with three candidate else
;; branches: d (drop the element AND everything after — wrong),
;; '() (wrong for non-empty tails), (rember e d) (correct recursive
;; call). Follower refutes the first two.
(parameterize ([*check-follower-every* 1])
  (test "follower refutes wrong rember else-branch"
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
        ((== q ''()))
        ((== q '(rember e d)))))
    '((rember e d))))

;; Three candidates for the whole body of an identity function:
;; '() (constant — fails on non-empty), (cons 1 l) (prepends 1 —
;; fails when input doesn't start with 1), l (correct). Tests that
;; the follower can refute multiple wrong candidates in sequence.
(parameterize ([*check-follower-every* 1])
  (test "follower refutes two candidates, picks identity"
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
    '(l)))

;; Two adjacent conjuncts that each diverge (r/d recurses infinitely).
;; Without the depth limit and hard-suspend mechanism, the conjunction
;; bounces back and forth between the two r/d calls forever: each
;; iteration creates fresh variables and extends the substitution map,
;; so the change-detection sees "progress" on every pass. The depth
;; limit causes each r/d to hard-suspend, which bind/d cannot bounce
;; through, so the conjunction terminates and the follower commits
;; q = 1 from the other clause.
(define (r)
  (conde
    ((fresh (x)
       (== x 1)
       (r)))))

(define (r/d)
  (conde/d
    ([x]
     [(==/d x 1)]
     [(r/d)])))

(test "diverging conjuncts terminate via hard-suspend"
  (run 1 (q)
    (follower
      q
      (conde/d
        ([]
         [(==/d q 1)]
         [])
        ([]
         [(==/d q 2)
          (fresh/d ()
            (r/d)
            (r/d))]
         [])))
    (conde
      ((== q 1))
      ((fresh ()
         (== q 2)
         (r)
         (r)))))
  '(1))
