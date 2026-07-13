;; swap-untyped-id-ty-residual.scm --- UNTYPED generator, WITH the type view (swap-pairs).
;; See rember-untyped-id-ty.scm for the experiment framing.  swap-tyenv is not
;; defined in residual-views.scm, so we define it here.
;;
;; tally/d has no residual counterpart (it wraps the closure engine's curried
;; (unsound-fail-depth)->(suspend-depth)->(st)->inf/d goal representation,
;; which r-form goals don't have); tally/d is pure observability (bumps a
;; side counter, never alters control flow or the returned inf/d -- see
;; following.scm's tally-step), so it is dropped here rather than ported; the
;; underlying view goals are otherwise unchanged.
;; Residual-engine port of swap-untyped-id-ty.scm (backlog 3b).
;;
;;   ./run.sh --check-follower-every 1 --main-unsound-depth 1000 \
;;     --timeout 240 experiments/swap-untyped-id-ty-residual.scm

(load "restricted-interp-untyped.scm")
(load "residual-interp-following.scm")
(load "residual-interp-untyped-following.scm")
(load "experiments/id-harness.scm")
(load "residual-views.scm") ; R1+R2+TY+NV view definitions (residual)

(define swap-tyenv '((swap . ((list) -> list)) (l . list)))

(define (swap-prog-u q body)
  `(letrec ([swap (lambda (l)
                    ,q)])
     ,body))

(run-id "swap-untyped/ty/residual" '(43 47 51 55 59 63 67 71 75 79) 1000
  (lambda (bound)
    (run 1 (q)
      (watch-size q)
      (absento 5 q)
      (absento 6 q)
      (absento 7 q)
      (absento 8 q)
      (follower
        q
        (follower-residual-goal
          (rfresh/d ()
            (base-case-patho/d-res 'swap q)
            (decreasing-recursiono/d-res 'swap '(l) q)
            (type-ofo/d-res swap-tyenv q 'list)
            (non-vacuous-testso/d-res q)
            (evalo-u/d-res (swap-prog-u q '(swap '())) '())
            (evalo-u/d-res (swap-prog-u q '(swap (cons 5 '()))) '(5))
            (evalo-u/d-res (swap-prog-u q '(swap (cons 5 (cons 6 '())))) '(6 5))
            (evalo-u/d-res (swap-prog-u q '(swap (cons 5 (cons 6 (cons 7 (cons 8 '())))))) '(6 5 8 7)))))
      (evalo-u (swap-prog-u q '(swap '())) '())
      (evalo-u (swap-prog-u q '(swap (cons 5 '()))) '(5))
      (evalo-u (swap-prog-u q '(swap (cons 5 (cons 6 '())))) '(6 5))
      (evalo-u (swap-prog-u q '(swap (cons 5 (cons 6 (cons 7 (cons 8 '())))))) '(6 5 8 7)))))
