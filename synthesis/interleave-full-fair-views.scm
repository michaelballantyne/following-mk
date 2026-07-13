;; interleave-full-fair-views.scm --- THIRD configuration: the SAME sound
;; follower (R1 base-case + R2P permuted-decreasing-recursion + TY types + NV
;; non-vacuous + evalo/d examples) as
;; experiments/interleave-full-id-views-r2p.scm, but run under classic
;; fair-interleaving search (`run 1`, no iterative deepening / watch-size /
;; bounds list) instead of size-closed ID. Decouples "get the soundness
;; benefit of the views" from "pay the ID minimality-exhaustion tax". Uses
;; R2P (permuted-decreasing-recursiono/d), NOT plain R2, since interleave's
;; canonical body swaps its self-call arguments and plain R2 (fixed-position
;; decreasing-recursiono/d) soundly refutes that recursion -- see
;; experiments/interleave-full-id-views-r2p.scm's header. Examples/absento
;; identical to synthesis/interleave-full-classic.scm.
;;
;; Sweep --check-follower-every at 1, 20, 100:
;;   ./run.sh --check-follower-every 1   --timeout 300 synthesis/interleave-full-fair-views.scm
;;   ./run.sh --check-follower-every 20  --timeout 300 synthesis/interleave-full-fair-views.scm
;;   ./run.sh --check-follower-every 100 --timeout 300 synthesis/interleave-full-fair-views.scm
(load "views.scm") ; R1 + R2 + R2P + TY + NV view definitions

(define (interleave-prog q body)
  `(letrec ([interleave (lambda (l1 l2) : ((list list) -> list)
                          ,q)])
     ,body))

(define interleave-tyenv
  '((interleave . ((list list) -> list)) (l1 . list) (l2 . list)))

(time-test "interleave fair search + full views (R2P)"
  (run 1 (q)
    (absento 5 q)
    (absento 6 q)
    (absento 7 q)
    (absento 8 q)
    (follower
      q
      (fresh/d ()
        (base-case-patho/d 'interleave q)
        (permuted-decreasing-recursiono/d 'interleave '(l1 l2) q)
        (type-ofo/d interleave-tyenv q 'list)
        (non-vacuous-testso/d q)
        (evalo/d (interleave-prog q '(interleave '() '())) '())
        (evalo/d (interleave-prog q '(interleave '() (cons 6 '()))) '(6))
        (evalo/d (interleave-prog q '(interleave (cons 5 '()) (cons 6 '()))) '(5 6))
        (evalo/d (interleave-prog q '(interleave (cons 5 (cons 7 '())) (cons 6 (cons 8 '())))) '(5 6 7 8))))
    (evalo (interleave-prog q '(interleave '() '())) '())
    (evalo (interleave-prog q '(interleave '() (cons 6 '()))) '(6))
    (evalo (interleave-prog q '(interleave (cons 5 '()) (cons 6 '()))) '(5 6))
    (evalo (interleave-prog q '(interleave (cons 5 (cons 7 '())) (cons 6 (cons 8 '())))) '(5 6 7 8)))
  ;; matches the DIFFERENT-but-still-correct variant classic search (no views)
  ;; found for interleave (synthesis/interleave-full-classic.scm): an extra
  ;; match on _.1 in the else-branch hardcodes the "second recursive-call arg
  ;; is empty" case to l2 directly instead of computing it through recursion
  ;; -- interleave l2 '() = l2 by induction, so this is a provably-equivalent
  ;; unfolding, not an overfit.
  '(((match l1
       ['() l2]
       [(cons _.0 _.1)
        (cons _.0
              (match _.1
                ['() l2]
                [(cons _.2 _.3) (interleave l2 _.1)]))])
     (=/= ((_.0 _.1))
          ((_.0 _.2))
          ((_.0 _.3))
          ((_.0 cons))
          ((_.0 interleave))
          ((_.0 l1))
          ((_.0 l2))
          ((_.0 match))
          ((_.1 _.2))
          ((_.1 _.3))
          ((_.1 cons))
          ((_.1 interleave))
          ((_.1 l1))
          ((_.1 l2))
          ((_.1 match))
          ((_.2 interleave))
          ((_.2 l1))
          ((_.2 l2))
          ((_.3 interleave))
          ((_.3 l1))
          ((_.3 l2)))
     (sym _.0 _.1 _.2 _.3))))
