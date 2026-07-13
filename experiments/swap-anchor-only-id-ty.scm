;; swap-anchor-only-id-ty.scm --- WAVE 2b comparator for the swap-involution
;; probe: the SAME single ground anchor (swap (5 6 7 8)) = (6 5 8 7), no
;; involution property.  If this alone pins canonical swap-pairs, the strong
;; property is redundant even on the harder task; if it under-pins (degenerate)
;; while swap-involution pins canonical, that is Michael's payoff regime.
;; UNTYPED generator + TY view.
;;
;;   ./run.sh --check-follower-every 1 --main-unsound-depth 1000 \
;;     --timeout 240 experiments/swap-anchor-only-id-ty.scm

(load "restricted-interp-untyped.scm")
(load "restricted-interp-untyped-following.scm")
(load "experiments/id-harness.scm")
(load "views.scm") ; R1+R2+TY+NV

(define swap-tyenv '((swap . ((list) -> list)) (l . list)))

(define (swap-prog-u q body)
  `(letrec ([swap (lambda (l)
                    ,q)])
     ,body))

(run-id "swap-anchor-only/ty" '(15 23 31 39 47 55 63 71) 1000
  (lambda (bound)
    (run 1 (q)
      (watch-size q)
      (absento 5 q)
      (absento 6 q)
      (absento 7 q)
      (absento 8 q)
      (follower
        q
        (fresh/d ()
          (tally/d 'R1 (base-case-patho/d 'swap q))
          (tally/d 'R2 (decreasing-recursiono/d 'swap '(l) q))
          (tally/d 'TY (type-ofo/d swap-tyenv q 'list))
          (tally/d 'NV (non-vacuous-testso/d q))
          (tally/d 'EX (evalo-u/d (swap-prog-u q '(swap (cons 5 (cons 6 (cons 7 (cons 8 '())))))) '(6 5 8 7)))))
      (evalo-u (swap-prog-u q '(swap (cons 5 (cons 6 (cons 7 (cons 8 '())))))) '(6 5 8 7)))))
