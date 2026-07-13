;; evens-full-fair-views.scm --- THIRD configuration: the SAME sound
;; follower (R1 base-case + R2 decreasing-recursion + TY types + NV
;; non-vacuous + evalo/d examples) as experiments/evens-full-id-views.scm,
;; but run under classic fair-interleaving search (`run 1`, no iterative
;; deepening / watch-size / bounds list) instead of size-closed ID. Decouples
;; "get the soundness benefit of the views" from "pay the ID
;; minimality-exhaustion tax". Examples/absento identical to
;; synthesis/evens-full-classic.scm.
;;
;; Sweep --check-follower-every at 1, 20, 100:
;;   ./run.sh --check-follower-every 1   --timeout 300 synthesis/evens-full-fair-views.scm
;;   ./run.sh --check-follower-every 20  --timeout 300 synthesis/evens-full-fair-views.scm
;;   ./run.sh --check-follower-every 100 --timeout 300 synthesis/evens-full-fair-views.scm
(load "views.scm") ; R1+R2+TY+NV view definitions

(define (evens-prog q body)
  `(letrec ([evens (lambda (l) : ((list) -> list)
                     ,q)])
     ,body))

(define evens-tyenv '((evens . ((list) -> list)) (l . list)))

(time-test "evens fair search + full views"
  (run 1 (q)
    (absento 5 q)
    (absento 6 q)
    (absento 7 q)
    (absento 8 q)
    (follower
      q
      (fresh/d ()
        (base-case-patho/d 'evens q)
        (decreasing-recursiono/d 'evens '(l) q)
        (type-ofo/d evens-tyenv q 'list)
        (non-vacuous-testso/d q)
        (evalo/d (evens-prog q '(evens '())) '())
        (evalo/d (evens-prog q '(evens (cons 5 '()))) '(5))
        (evalo/d (evens-prog q '(evens (cons 5 (cons 6 '())))) '(5))
        (evalo/d (evens-prog q '(evens (cons 5 (cons 6 (cons 7 '()))))) '(5 7))
        (evalo/d (evens-prog q '(evens (cons 5 (cons 6 (cons 7 (cons 8 '())))))) '(5 7))))
    (evalo (evens-prog q '(evens '())) '())
    (evalo (evens-prog q '(evens (cons 5 '()))) '(5))
    (evalo (evens-prog q '(evens (cons 5 (cons 6 '())))) '(5))
    (evalo (evens-prog q '(evens (cons 5 (cons 6 (cons 7 '()))))) '(5 7))
    (evalo (evens-prog q '(evens (cons 5 (cons 6 (cons 7 (cons 8 '())))))) '(5 7)))
  ;; matches the "return l" variant (both base cases return `l` itself rather
  ;; than rebuilding '() / (cons a '())), same trick documented for swap; fully
  ;; general, recursive, correct.
  '(((match l
       ['() l]
       [(cons _.0 _.1)
        (match _.1
          ['() l]
          [(cons _.2 _.3) (cons _.0 (evens _.3))])])
     (=/= ((_.0 _.1))
          ((_.0 _.2))
          ((_.0 _.3))
          ((_.0 cons))
          ((_.0 evens))
          ((_.0 l))
          ((_.0 match))
          ((_.1 _.2))
          ((_.1 _.3))
          ((_.1 cons))
          ((_.1 evens))
          ((_.1 l))
          ((_.1 match))
          ((_.2 _.3))
          ((_.2 cons))
          ((_.2 evens))
          ((_.2 l))
          ((_.3 cons))
          ((_.3 evens))
          ((_.3 l)))
     (sym _.0 _.1 _.2 _.3))))
