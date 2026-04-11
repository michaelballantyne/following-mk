;; rember, hole 1 (smallest): the program body is almost fully
;; known, with just one symbol hole (`,p`) in place of `e` in the
;; `(= a e)` comparison.  Expected answer: p = e.
;;
;; Three examples in the "good" order.  Two examples alone don't
;; constrain the hole uniquely (both p=a and p=e satisfy them), so
;; ex3 is a "remove misses first element" case that rules out p=a.
;;
;; This file has two tests: the same task with a follower wrapped
;; around evalo/d, and without.  Intended for side-by-side counter
;; comparison when debugging whether the follower is helping.
;;
;; Run via `./run.sh synthesis/rember-1.scm`.

(define (rember-prog p body)
  `(letrec ([rember (lambda (e l) : ((number list) -> list)
                      (match l
                        ['() l]
                        [(cons a d) (if (= a ,p) d (cons a (rember e d)))]))])
     ,body))

(time
  (test "rember hole-1 no follower"
    (run 1 (p)
      (evalo (rember-prog p '(rember 5 '())) '())
      (evalo (rember-prog p '(rember 6 (cons 6 '()))) '())
      ;; ex3 -- discriminates p = e from p = a
      (evalo (rember-prog p '(rember 7 (cons 3 '()))) '(3)))
    '(e)))

(time
  (test "rember hole-1 with follower"
    (run 1 (p)
      (follower p
        (fresh/d ()
          (evalo/d (rember-prog p '(rember 5 '())) '())
          (evalo/d (rember-prog p '(rember 6 (cons 6 '()))) '())
          (evalo/d (rember-prog p '(rember 7 (cons 3 '()))) '(3))))
      (evalo (rember-prog p '(rember 5 '())) '())
      (evalo (rember-prog p '(rember 6 (cons 6 '()))) '())
      (evalo (rember-prog p '(rember 7 (cons 3 '()))) '(3)))
    '(e)))
