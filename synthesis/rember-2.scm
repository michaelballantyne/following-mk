;; rember, hole 2: a slightly bigger hole than rember-1.  Instead of
;; one symbol, the hole replaces the entire recursive call
;; `(rember e d)` in the else-branch, so the synthesizer has to find
;; a 3-element application, not a single symbol.  Expected answer:
;; p = (rember e d).
;;
;; Examples in the "good" order.  Ex1 and ex2 hit the base cases.  Ex3
;; hits the else-branch once.  Ex4 removes at position 2 of a 3-elem
;; list.  Ex5 removes at position 2 of a 4-elem list.  Ex6 removes
;; from the END of a 4-elem list -- this is the one that defeats the
;; "nested-match drop-one-from-d" trick the baseline otherwise finds
;; on ex1-ex5, forcing the synthesizer to the actual recursive answer.
;;
;; Run via `./run.sh synthesis/rember-2.scm`.

;; Build the whole letrec-wrapped program with the hole `,p` and a
;; caller expression `body`.  `p` is the outer logic variable; `body`
;; is a quoted application like `(rember 5 '())`.
(define (rember-prog p body)
  `(letrec ([rember (lambda (e l) : ((number list) -> list)
                      (match l
                        ['() l]
                        [(cons a d)
                         (if (= a e)
                             d
                             (cons a ,p))]))])
     ,body))

(time-test "rember hole-2 no follower"
  (run 1 (p)
    (evalo (rember-prog p '(rember 5 '())) '())
    (evalo (rember-prog p '(rember 6 (cons 6 '()))) '())
    (evalo (rember-prog p '(rember 7 (cons 3 '()))) '(3))
    (evalo (rember-prog p '(rember 4 (cons 3 (cons 6 (cons 4 '()))))) '(3 6))
    (evalo (rember-prog p '(rember 4 (cons 3 (cons 6 (cons 4 (cons 7 '())))))) '(3 6 7))
    (evalo (rember-prog p '(rember 7 (cons 3 (cons 4 (cons 5 (cons 7 '())))))) '(3 4 5)))
  '((rember e d)))

(time-test "rember hole-2 with follower"
  (run 1 (p)
    (follower
      p
      (fresh/d ()
        (evalo/d (rember-prog p '(rember 5 '())) '())
        (evalo/d (rember-prog p '(rember 6 (cons 6 '()))) '())
        (evalo/d (rember-prog p '(rember 7 (cons 3 '()))) '(3))
        (evalo/d (rember-prog p '(rember 4 (cons 3 (cons 6 (cons 4 '()))))) '(3 6))
        (evalo/d (rember-prog p '(rember 4 (cons 3 (cons 6 (cons 4 (cons 7 '())))))) '(3 6 7))
        (evalo/d (rember-prog p '(rember 7 (cons 3 (cons 4 (cons 5 (cons 7 '())))))) '(3 4 5))))
    (evalo (rember-prog p '(rember 5 '())) '())
    (evalo (rember-prog p '(rember 6 (cons 6 '()))) '())
    (evalo (rember-prog p '(rember 7 (cons 3 '()))) '(3))
    (evalo (rember-prog p '(rember 4 (cons 3 (cons 6 (cons 4 '()))))) '(3 6))
    (evalo (rember-prog p '(rember 4 (cons 3 (cons 6 (cons 4 (cons 7 '())))))) '(3 6 7))
    (evalo (rember-prog p '(rember 7 (cons 3 (cons 4 (cons 5 (cons 7 '())))))) '(3 4 5)))
  '((rember e d)))
