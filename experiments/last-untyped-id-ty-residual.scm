;; last-untyped-id-ty-residual.scm --- UNTYPED generator, WITH the type view (last).
;; See rember-untyped-id-ty.scm for the experiment framing.  last-tyenv is not
;; defined in residual-views.scm, so we define it here.
;;
;; tally/d has no residual counterpart (it wraps the closure engine's curried
;; (unsound-fail-depth)->(suspend-depth)->(st)->inf/d goal representation,
;; which r-form goals don't have); tally/d is pure observability (bumps a
;; side counter, never alters control flow or the returned inf/d -- see
;; following.scm's tally-step), so it is dropped here rather than ported; the
;; underlying view goals are otherwise unchanged.
;; Residual-engine port of last-untyped-id-ty.scm (backlog 3b).
;;
;;   ./run.sh --check-follower-every 1 --main-unsound-depth 1000 \
;;     --timeout 240 experiments/last-untyped-id-ty-residual.scm

(load "restricted-interp-untyped.scm")
(load "residual-interp-following.scm")
(load "residual-interp-untyped-following.scm")
(load "experiments/id-harness.scm")
(load "residual-views.scm") ; R1+R2+TY+NV view definitions (residual)

(define last-tyenv '((last . ((list) -> number)) (l . list)))

(define (last-prog-u q body)
  `(letrec ([last (lambda (l)
                    ,q)])
     ,body))

(run-id "last-untyped/ty/residual" '(19 23 27 31 35 39 43 47 51 55) 1000
  (lambda (bound)
    (run 1 (q)
      (watch-size q)
      (absento 5 q)
      (absento 6 q)
      (absento 7 q)
      (follower
        q
        (follower-residual-goal
          (rfresh/d ()
            (base-case-patho/d-res 'last q)
            (decreasing-recursiono/d-res 'last '(l) q)
            (type-ofo/d-res last-tyenv q 'number)
            (non-vacuous-testso/d-res q)
            (evalo-u/d-res (last-prog-u q '(last (cons 5 '()))) 5)
            (evalo-u/d-res (last-prog-u q '(last (cons 5 (cons 6 '())))) 6)
            (evalo-u/d-res (last-prog-u q '(last (cons 5 (cons 6 (cons 7 '()))))) 7))))
      (evalo-u (last-prog-u q '(last (cons 5 '()))) 5)
      (evalo-u (last-prog-u q '(last (cons 5 (cons 6 '())))) 6)
      (evalo-u (last-prog-u q '(last (cons 5 (cons 6 (cons 7 '()))))) 7))))
