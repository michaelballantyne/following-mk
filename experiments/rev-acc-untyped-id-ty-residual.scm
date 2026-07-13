;; rev-acc-untyped-id-ty-residual.scm --- UNTYPED generator, WITH the type view
;; (accumulator-reverse).  See rember-untyped-id-ty.scm for the experiment
;; framing.  rev-tyenv is not defined in residual-views.scm, so we define it
;; here.  The second parameter `acc` is a pure accumulator (never a decreasing
;; recursion argument), so R2 must commit position 1.
;;
;; tally/d has no residual counterpart (it wraps the closure engine's curried
;; (unsound-fail-depth)->(suspend-depth)->(st)->inf/d goal representation,
;; which r-form goals don't have); tally/d is pure observability (bumps a
;; side counter, never alters control flow or the returned inf/d -- see
;; following.scm's tally-step), so it is dropped here rather than ported; the
;; underlying view goals are otherwise unchanged.
;; Residual-engine port of rev-acc-untyped-id-ty.scm (backlog 3b).
;;
;;   ./run.sh --check-follower-every 1 --main-unsound-depth 1000 \
;;     --timeout 240 experiments/rev-acc-untyped-id-ty-residual.scm

(load "restricted-interp-untyped.scm")
(load "residual-interp-following.scm")
(load "residual-interp-untyped-following.scm")
(load "experiments/id-harness.scm")
(load "residual-views.scm") ; R1+R2+TY+NV view definitions (residual)

(define rev-tyenv '((rev . ((list list) -> list)) (l . list) (acc . list)))

(define (rev-prog-u q body)
  `(letrec ([rev (lambda (l acc)
                   ,q)])
     ,body))

(run-id "rev-acc-untyped/ty/residual" '(11 15 19 23 27 31 35 39) 1000
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
            (base-case-patho/d-res 'rev q)
            (decreasing-recursiono/d-res 'rev '(l acc) q)
            (type-ofo/d-res rev-tyenv q 'list)
            (non-vacuous-testso/d-res q)
            (evalo-u/d-res (rev-prog-u q '(rev '() '())) '())
            (evalo-u/d-res (rev-prog-u q '(rev (cons 5 '()) '())) '(5))
            (evalo-u/d-res (rev-prog-u q '(rev (cons 5 (cons 6 '())) '())) '(6 5))
            (evalo-u/d-res (rev-prog-u q '(rev (cons 5 (cons 6 (cons 7 '()))) '())) '(7 6 5)))))
      (evalo-u (rev-prog-u q '(rev '() '())) '())
      (evalo-u (rev-prog-u q '(rev (cons 5 '()) '())) '(5))
      (evalo-u (rev-prog-u q '(rev (cons 5 (cons 6 '())) '())) '(6 5))
      (evalo-u (rev-prog-u q '(rev (cons 5 (cons 6 (cons 7 '()))) '())) '(7 6 5)))))
