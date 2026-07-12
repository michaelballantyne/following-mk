;; swap-untyped-id-ty.scm --- UNTYPED generator, WITH the type view (swap-pairs).
;; See rember-untyped-id-ty.scm for the experiment framing.  swap-tyenv is not
;; defined in views.scm, so we define it here.  Each follower view goal is
;; wrapped in tally/d ('R1 'R2 'TY 'NV 'EX) for per-view refute/force
;; attribution (following.scm); the four examples share 'EX.
;;
;;   ./run.sh --check-follower-every 1 --main-unsound-depth 1000 \
;;     --timeout 240 experiments/swap-untyped-id-ty.scm

(load "restricted-interp-untyped.scm")
(load "restricted-interp-untyped-following.scm")
(load "experiments/id-harness.scm")
(load "views.scm") ; R1+R2+TY+NV view definitions

(define swap-tyenv '((swap . ((list) -> list)) (l . list)))

(define (swap-prog-u q body)
  `(letrec ([swap (lambda (l)
                    ,q)])
     ,body))

(run-id "swap-untyped/ty" '(43 47 51 55 59 63 67 71 75 79) 1000
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
          (tally/d 'EX (evalo-u/d (swap-prog-u q '(swap '())) '()))
          (tally/d 'EX (evalo-u/d (swap-prog-u q '(swap (cons 5 '()))) '(5)))
          (tally/d 'EX (evalo-u/d (swap-prog-u q '(swap (cons 5 (cons 6 '())))) '(6 5)))
          (tally/d 'EX (evalo-u/d (swap-prog-u q '(swap (cons 5 (cons 6 (cons 7 (cons 8 '())))))) '(6 5 8 7)))))
      (evalo-u (swap-prog-u q '(swap '())) '())
      (evalo-u (swap-prog-u q '(swap (cons 5 '()))) '(5))
      (evalo-u (swap-prog-u q '(swap (cons 5 (cons 6 '())))) '(6 5))
      (evalo-u (swap-prog-u q '(swap (cons 5 (cons 6 (cons 7 (cons 8 '())))))) '(6 5 8 7)))))
