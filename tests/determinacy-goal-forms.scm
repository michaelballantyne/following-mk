;; Tests for the /d language primitives: conde/d, fresh/d, conjunction,
;; depth limits, and the basic follower commit/suspend/fail mechanics.
;; No interpreter involved.

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

;; Regression test. Two adjacent r/d calls each recur infinitely.
;; With earlier an earlier implementation of fresh/d, the refinement
;; fixed point bounced back and forth forever. With the new approach of separating
;; suspension due to nondeterminism vs due to the depth limit, the depth limit causes
;; each r/d to hard-suspend, so the conjunction terminates and the
;; follower commits q = 1 from the other clause.

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
