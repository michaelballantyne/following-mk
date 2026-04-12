;; Full rember synthesis with ex1 <-> ex2 swapped: a length-1 one-element
;; remove (rember 6 (cons 6 '())) first, then the empty-list base case.
;; Like append-full-swap.scm, this variant currently times out in every
;; configuration we've tested and is an open problem.  A working
;; follower should rescue the bad ordering by using all four examples
;; in parallel instead of following the main search's traversal.
;;
;; Run via `./run.sh synthesis/rember-full-swap.scm`.

(define (rember-prog q body)
  `(letrec ([rember (lambda (e l) : ((number list) -> list)
                      ,q)])
     ,body))

(time
  (test "rember-swap no follower"
    (run 1 (q)
      (absento 3 q)
      (absento 4 q)
      (absento 5 q)
      (absento 6 q)
      (absento 7 q)
      ;; ex2 first (swapped)
      (evalo (rember-prog q '(rember 6 (cons 6 '()))) '())
      ;; ex1 second
      (evalo (rember-prog q '(rember 5 '())) '())
      ;; ex3
      (evalo (rember-prog q '(rember 7 (cons 3 (cons 4 (cons 7 (cons 6 '())))))) '(3 4 6))
      ;; ex4
      (evalo (rember-prog q '(rember 5 (cons 3 (cons 4 (cons 6 (cons 7 '())))))) '(3 4 6 7)))
    '(((match l
         ['() l]
         [(cons _.0 _.1)
          (if (= _.0 e)
              _.1
              (cons _.0 (rember e _.1)))])
       (=/= ((_.0 _.1))
            ((_.0 cons))
            ((_.0 e))
            ((_.0 if))
            ((_.0 rember))
            ((_.1 cons))
            ((_.1 e))
            ((_.1 if))
            ((_.1 rember)))
       (sym _.0 _.1)))))

(time
  (test "rember-swap with follower"
    (run 1 (q)
      (absento 3 q)
      (absento 4 q)
      (absento 5 q)
      (absento 6 q)
      (absento 7 q)
      (follower
        q
        (fresh/d ()
          (evalo/d (rember-prog q '(rember 6 (cons 6 '()))) '())
          (evalo/d (rember-prog q '(rember 5 '())) '())
          (evalo/d (rember-prog q '(rember 7 (cons 3 (cons 4 (cons 7 (cons 6 '())))))) '(3 4 6))
          (evalo/d (rember-prog q '(rember 5 (cons 3 (cons 4 (cons 6 (cons 7 '())))))) '(3 4 6 7))))
      (evalo (rember-prog q '(rember 6 (cons 6 '()))) '())
      (evalo (rember-prog q '(rember 5 '())) '())
      (evalo (rember-prog q '(rember 7 (cons 3 (cons 4 (cons 7 (cons 6 '())))))) '(3 4 6))
      (evalo (rember-prog q '(rember 5 (cons 3 (cons 4 (cons 6 (cons 7 '())))))) '(3 4 6 7)))
    '(((match l
         ['() l]
         [(cons _.0 _.1)
          (if (= _.0 e)
              _.1
              (cons _.0 (rember e _.1)))])
       (=/= ((_.0 _.1))
            ((_.0 cons))
            ((_.0 e))
            ((_.0 if))
            ((_.0 rember))
            ((_.1 cons))
            ((_.1 e))
            ((_.1 if))
            ((_.1 rember)))
       (sym _.0 _.1)))))
