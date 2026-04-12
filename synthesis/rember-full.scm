;; Full rember synthesis: the entire lambda body is a hole (`,q`).
;; The synthesizer has to find the whole match/if/cons/recurse body.
;; Four examples in the "good" order.
;;
;; Run via `./run.sh synthesis/rember-full.scm`.

(define (rember-prog q body)
  `(letrec ([rember (lambda (e l) : ((number list) -> list)
                      ,q)])
     ,body))

(time-test "rember-full no follower"
  (run 1 (q)
    (absento 3 q)
    (absento 4 q)
    (absento 5 q)
    (absento 6 q)
    (absento 7 q)
    ;; ex1
    (evalo (rember-prog q '(rember 5 '())) '())
    ;; ex2
    (evalo (rember-prog q '(rember 6 (cons 6 '()))) '())
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
     (sym _.0 _.1))))

(time-test "rember-full with follower"
  (run 1 (q)
    (absento 3 q)
    (absento 4 q)
    (absento 5 q)
    (absento 6 q)
    (absento 7 q)
    (follower
      q
      (fresh/d ()
        (evalo/d (rember-prog q '(rember 5 '())) '())
        (evalo/d (rember-prog q '(rember 6 (cons 6 '()))) '())
        (evalo/d (rember-prog q '(rember 7 (cons 3 (cons 4 (cons 7 (cons 6 '())))))) '(3 4 6))
        (evalo/d (rember-prog q '(rember 5 (cons 3 (cons 4 (cons 6 (cons 7 '())))))) '(3 4 6 7))))
    (evalo (rember-prog q '(rember 5 '())) '())
    (evalo (rember-prog q '(rember 6 (cons 6 '()))) '())
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
     (sym _.0 _.1))))
