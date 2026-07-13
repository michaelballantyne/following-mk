;; append-full-fair-views.scm --- THIRD configuration: the SAME sound
;; follower (R1 base-case + R2 decreasing-recursion + TY types + NV
;; non-vacuous + evalo/d examples) as experiments/append-full-id-views.scm,
;; but run under classic fair-interleaving search (`run 1`, no iterative
;; deepening / watch-size / bounds list) instead of size-closed ID. Decouples
;; "get the soundness benefit of the views" from "pay the ID
;; minimality-exhaustion tax". Examples/absento identical to
;; synthesis/append-full.scm (pre-existing, no "-classic" suffix).
;; append-tyenv is defined in views.scm; reused here rather than redefined.
;;
;; Sweep --check-follower-every at 1, 20, 100:
;;   ./run.sh --check-follower-every 1   --timeout 300 synthesis/append-full-fair-views.scm
;;   ./run.sh --check-follower-every 20  --timeout 300 synthesis/append-full-fair-views.scm
;;   ./run.sh --check-follower-every 100 --timeout 300 synthesis/append-full-fair-views.scm
(load "views.scm") ; R1+R2+TY+NV view definitions; defines append-tyenv

(define (append-prog q body)
  `(letrec ([append (lambda (l s) : ((list list) -> list)
                      ,q)])
     ,body))

(time-test "append fair search + full views"
  (run 1 (q)
    (absento '3 q)
    (absento '4 q)
    (absento '5 q)
    (absento '6 q)
    (absento '7 q)
    (follower
      q
      (fresh/d ()
        (base-case-patho/d 'append q)
        (decreasing-recursiono/d 'append '(l s) q)
        (type-ofo/d append-tyenv q 'list)
        (non-vacuous-testso/d q)
        (evalo/d (append-prog q '(append '() (cons 5 (cons 6 '())))) '(5 6))
        (evalo/d (append-prog q '(append (cons 3 (cons 4 (cons 5 '()))) (cons 6 (cons 7 '()))))
                 '(3 4 5 6 7))))
    (evalo (append-prog q '(append '() (cons 5 (cons 6 '())))) '(5 6))
    (evalo (append-prog q '(append (cons 3 (cons 4 (cons 5 '()))) (cons 6 (cons 7 '()))))
           '(3 4 5 6 7)))
  '(((match l
       ['() s]
       [(cons _.0 _.1) (cons _.0 (append _.1 s))])
     (=/= ((_.0 _.1))
          ((_.0 append))
          ((_.0 cons))
          ((_.0 l))
          ((_.0 s))
          ((_.1 append))
          ((_.1 cons))
          ((_.1 l))
          ((_.1 s)))
     (sym _.0 _.1))))
