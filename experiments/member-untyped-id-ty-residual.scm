;; member-untyped-id-ty-residual.scm --- UNTYPED generator, WITH the type view (member).
;; See rember-untyped-id-ty.scm for the experiment framing.  member-tyenv is not
;; defined in residual-views.scm, so we define it here -- the arrow type of the
;; letrec-bound function and its parameters, supplied to type-ofo/d-res even
;; though the interpreter template no longer carries the annotation.
;;
;; tally/d has no residual counterpart (it wraps the closure engine's curried
;; (unsound-fail-depth)->(suspend-depth)->(st)->inf/d goal representation,
;; which r-form goals don't have); tally/d is pure observability (bumps a
;; side counter, never alters control flow or the returned inf/d -- see
;; following.scm's tally-step), so it is dropped here rather than ported; the
;; underlying view goals are otherwise unchanged.
;; Residual-engine port of member-untyped-id-ty.scm (backlog 3b).
;;
;;   ./run.sh --check-follower-every 1 --main-unsound-depth 1000 \
;;     --timeout 240 experiments/member-untyped-id-ty-residual.scm

(load "restricted-interp-untyped.scm")
(load "residual-interp-following.scm")
(load "residual-interp-untyped-following.scm")
(load "experiments/id-harness.scm")
(load "residual-views.scm") ; R1+R2+TY+NV view definitions (residual)

(define member-tyenv '((member . ((number list) -> number)) (e . number) (l . list)))

(define (member-prog-u q body)
  `(letrec ([member (lambda (e l)
                      ,q)])
     ,body))

(run-id "member-untyped/ty/residual" '(11 15 19 23 27 31 35 39 43 47) 1000
  (lambda (bound)
    (run 1 (q)
      (watch-size q)
      (absento 5 q)
      (absento 6 q)
      (follower
        q
        (follower-residual-goal
          (rfresh/d ()
            (base-case-patho/d-res 'member q)
            (decreasing-recursiono/d-res 'member '(e l) q)
            (type-ofo/d-res member-tyenv q 'number)
            (non-vacuous-testso/d-res q)
            (evalo-u/d-res (member-prog-u q '(member 5 '())) 0)
            (evalo-u/d-res (member-prog-u q '(member 5 (cons 5 '()))) 1)
            (evalo-u/d-res (member-prog-u q '(member 5 (cons 6 '()))) 0)
            (evalo-u/d-res (member-prog-u q '(member 5 (cons 6 (cons 5 '())))) 1))))
      (evalo-u (member-prog-u q '(member 5 '())) 0)
      (evalo-u (member-prog-u q '(member 5 (cons 5 '()))) 1)
      (evalo-u (member-prog-u q '(member 5 (cons 6 '()))) 0)
      (evalo-u (member-prog-u q '(member 5 (cons 6 (cons 5 '())))) 1))))
