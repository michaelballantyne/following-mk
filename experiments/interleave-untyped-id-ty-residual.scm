;; interleave-untyped-id-ty-residual.scm --- UNTYPED generator, WITH the type view
;; (interleave).  See rember-untyped-id-ty.scm for the experiment framing.
;; interleave-tyenv is not defined in residual-views.scm, so we define it here.
;;
;; R2 (decreasing-recursiono/d-res) is OMITTED, exactly as in
;; experiments/interleave-untyped-id-ty.scm: interleave's canonical recursion
;; SWAPS its arguments ((interleave l2 d)), so no single fixed argument position
;; structurally decreases in every self-call and R2 would refute the canonical
;; answer.  The label keeps the (noR2) suffix to mark this.
;;
;; tally/d has no residual counterpart (it wraps the closure engine's curried
;; (unsound-fail-depth)->(suspend-depth)->(st)->inf/d goal representation,
;; which r-form goals don't have); tally/d is pure observability (bumps a
;; side counter, never alters control flow or the returned inf/d -- see
;; following.scm's tally-step), so it is dropped here rather than ported; the
;; underlying view goals are otherwise unchanged.
;; Residual-engine port of interleave-untyped-id-ty.scm (backlog 3b).
;;
;;   ./run.sh --check-follower-every 1 --main-unsound-depth 1000 \
;;     --timeout 240 experiments/interleave-untyped-id-ty-residual.scm

(load "restricted-interp-untyped.scm")
(load "residual-interp-following.scm")
(load "residual-interp-untyped-following.scm")
(load "experiments/id-harness.scm")
(load "residual-views.scm") ; R1+R2+TY+NV view definitions (residual)

(define interleave-tyenv
  '((interleave . ((list list) -> list)) (l1 . list) (l2 . list)))

(define (interleave-prog-u q body)
  `(letrec ([interleave (lambda (l1 l2)
                          ,q)])
     ,body))

(run-id "interleave-untyped/ty(noR2)/residual" '(11 15 19 23 27 31 35 39) 1000
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
            (base-case-patho/d-res 'interleave q)
            ;; R2 (decreasing-recursiono/d-res) intentionally omitted: it refutes
            ;; the canonical answer (argument-swapping recursion; see header).
            (type-ofo/d-res interleave-tyenv q 'list)
            (non-vacuous-testso/d-res q)
            (evalo-u/d-res (interleave-prog-u q '(interleave '() '())) '())
            (evalo-u/d-res (interleave-prog-u q '(interleave '() (cons 6 '()))) '(6))
            (evalo-u/d-res (interleave-prog-u q '(interleave (cons 5 '()) (cons 6 '()))) '(5 6))
            (evalo-u/d-res (interleave-prog-u q '(interleave (cons 5 (cons 7 '())) (cons 6 (cons 8 '())))) '(5 6 7 8)))))
      (evalo-u (interleave-prog-u q '(interleave '() '())) '())
      (evalo-u (interleave-prog-u q '(interleave '() (cons 6 '()))) '(6))
      (evalo-u (interleave-prog-u q '(interleave (cons 5 '()) (cons 6 '()))) '(5 6))
      (evalo-u (interleave-prog-u q '(interleave (cons 5 (cons 7 '())) (cons 6 (cons 8 '())))) '(5 6 7 8)))))
