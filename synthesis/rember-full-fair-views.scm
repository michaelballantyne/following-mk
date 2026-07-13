;; rember-full-fair-views.scm --- THIRD configuration: the SAME sound
;; follower (R1 base-case + R2 decreasing-recursion + TY types + NV
;; non-vacuous + evalo/d examples) as experiments/rember-full-id-views.scm,
;; but run under classic fair-interleaving search (`run 1`, no iterative
;; deepening / watch-size / bounds list) instead of size-closed ID. Decouples
;; "get the soundness benefit of the views" from "pay the ID
;; minimality-exhaustion tax". Examples/absento identical to
;; synthesis/rember-full.scm (pre-existing, no "-classic" suffix).
;;
;; Sweep --check-follower-every at 1, 20, 100:
;;   ./run.sh --check-follower-every 1   --timeout 300 synthesis/rember-full-fair-views.scm
;;   ./run.sh --check-follower-every 20  --timeout 300 synthesis/rember-full-fair-views.scm
;;   ./run.sh --check-follower-every 100 --timeout 300 synthesis/rember-full-fair-views.scm
(load "views.scm") ; R1+R2+TY+NV view definitions

(define (rember-prog q body)
  `(letrec ([rember (lambda (e l) : ((number list) -> list)
                      ,q)])
     ,body))

(time-test "rember fair search + full views"
  (run 1 (q)
    (absento 3 q)
    (absento 4 q)
    (absento 5 q)
    (absento 6 q)
    (absento 7 q)
    (follower
      q
      (fresh/d ()
        (base-case-patho/d 'rember q)
        (decreasing-recursiono/d 'rember '(e l) q)
        (type-ofo/d rember-tyenv q 'list)
        (non-vacuous-testso/d q)
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
          ((_.0 l))
          ((_.0 rember))
          ((_.1 cons))
          ((_.1 e))
          ((_.1 if))
          ((_.1 l))
          ((_.1 rember)))
     (sym _.0 _.1))))
