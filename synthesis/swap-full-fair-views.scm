;; swap-full-fair-views.scm --- THIRD configuration: the SAME sound
;; follower (R1 base-case + R2 decreasing-recursion + TY types + NV
;; non-vacuous + evalo/d examples) as experiments/swap-full-id-views.scm,
;; but run under classic fair-interleaving search (`run 1`, no iterative
;; deepening / watch-size / bounds list) instead of size-closed ID. Decouples
;; "get the soundness benefit of the views" from "pay the ID
;; minimality-exhaustion tax". Examples/absento identical to
;; synthesis/swap-full-classic.scm. Note both the classic-search-alone arm and
;; the ID+views arm found the "return l" machine-minimal variant rather than
;; the header's human-canonical body; the expected datum below was calibrated
;; against what this fair+views arm actually returns (see run log).
;;
;; Sweep --check-follower-every at 1, 20, 100:
;;   ./run.sh --check-follower-every 1   --timeout 300 synthesis/swap-full-fair-views.scm
;;   ./run.sh --check-follower-every 20  --timeout 300 synthesis/swap-full-fair-views.scm
;;   ./run.sh --check-follower-every 100 --timeout 300 synthesis/swap-full-fair-views.scm
(load "views.scm") ; R1+R2+TY+NV view definitions

(define (swap-prog q body)
  `(letrec ([swap (lambda (l) : ((list) -> list)
                    ,q)])
     ,body))

(define swap-tyenv '((swap . ((list) -> list)) (l . list)))

(time-test "swap fair search + full views"
  (run 1 (q)
    (absento 5 q)
    (absento 6 q)
    (absento 7 q)
    (absento 8 q)
    (follower
      q
      (fresh/d ()
        (base-case-patho/d 'swap q)
        (decreasing-recursiono/d 'swap '(l) q)
        (type-ofo/d swap-tyenv q 'list)
        (non-vacuous-testso/d q)
        (evalo/d (swap-prog q '(swap '())) '())
        (evalo/d (swap-prog q '(swap (cons 5 '()))) '(5))
        (evalo/d (swap-prog q '(swap (cons 5 (cons 6 '())))) '(6 5))
        (evalo/d (swap-prog q '(swap (cons 5 (cons 6 (cons 7 (cons 8 '())))))) '(6 5 8 7))))
    (evalo (swap-prog q '(swap '())) '())
    (evalo (swap-prog q '(swap (cons 5 '()))) '(5))
    (evalo (swap-prog q '(swap (cons 5 (cons 6 '())))) '(6 5))
    (evalo (swap-prog q '(swap (cons 5 (cons 6 (cons 7 (cons 8 '())))))) '(6 5 8 7)))
  ;; matches the "return l" machine-minimal variant this same follower stack
  ;; found under size-closed ID (experiments/swap-full-id-views.scm's header) --
  ;; both base cases return `l` itself rather than rebuilding '() / (cons a '()),
  ;; valid since l IS the matched structure at that point. Fully general,
  ;; recursive, correct -- just not the human-canonical size-74 body.
  '(((match l
       ['() l]
       [(cons _.0 _.1)
        (match _.1
          ['() l]
          [(cons _.2 _.3) (cons _.2 (cons _.0 (swap _.3)))])])
     (=/= ((_.0 _.1))
          ((_.0 _.2))
          ((_.0 _.3))
          ((_.0 cons))
          ((_.0 l))
          ((_.0 match))
          ((_.0 swap))
          ((_.1 _.2))
          ((_.1 _.3))
          ((_.1 cons))
          ((_.1 l))
          ((_.1 match))
          ((_.1 swap))
          ((_.2 _.3))
          ((_.2 cons))
          ((_.2 l))
          ((_.2 swap))
          ((_.3 cons))
          ((_.3 l))
          ((_.3 swap)))
     (sym _.0 _.1 _.2 _.3))))
