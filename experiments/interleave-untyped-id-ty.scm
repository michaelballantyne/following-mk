;; interleave-untyped-id-ty.scm --- UNTYPED generator, WITH the type view
;; (interleave).  See rember-untyped-id-ty.scm for the experiment framing.
;; interleave-tyenv is not defined in views.scm, so we define it here.
;;
;; R2 (decreasing-recursiono/d) is OMITTED, exactly as in
;; experiments/interleave-full-id-views.scm: interleave's canonical recursion
;; SWAPS its arguments ((interleave l2 d)), so no single fixed argument position
;; structurally decreases in every self-call and R2 would refute the canonical
;; answer.  The label keeps the (noR2) suffix to mark this.  Each remaining
;; follower view goal is wrapped in tally/d ('R1 'TY 'NV 'EX) for per-view
;; refute/force attribution (following.scm); the four examples share 'EX.
;;
;;   ./run.sh --check-follower-every 1 --main-unsound-depth 1000 \
;;     --timeout 240 experiments/interleave-untyped-id-ty.scm

(load "restricted-interp-untyped.scm")
(load "restricted-interp-untyped-following.scm")
(load "experiments/id-harness.scm")
(load "views.scm") ; R1+R2+TY+NV view definitions

(define interleave-tyenv
  '((interleave . ((list list) -> list)) (l1 . list) (l2 . list)))

(define (interleave-prog-u q body)
  `(letrec ([interleave (lambda (l1 l2)
                          ,q)])
     ,body))

(run-id "interleave-untyped/ty(noR2)" '(11 15 19 23 27 31 35 39) 1000
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
          (tally/d 'R1 (base-case-patho/d 'interleave q))
          ;; R2 (decreasing-recursiono/d) intentionally omitted: it refutes the
          ;; canonical answer (argument-swapping recursion; see header).
          (tally/d 'TY (type-ofo/d interleave-tyenv q 'list))
          (tally/d 'NV (non-vacuous-testso/d q))
          (tally/d 'EX (evalo-u/d (interleave-prog-u q '(interleave '() '())) '()))
          (tally/d 'EX (evalo-u/d (interleave-prog-u q '(interleave '() (cons 6 '()))) '(6)))
          (tally/d 'EX (evalo-u/d (interleave-prog-u q '(interleave (cons 5 '()) (cons 6 '()))) '(5 6)))
          (tally/d 'EX (evalo-u/d (interleave-prog-u q '(interleave (cons 5 (cons 7 '())) (cons 6 (cons 8 '())))) '(5 6 7 8)))))
      (evalo-u (interleave-prog-u q '(interleave '() '())) '())
      (evalo-u (interleave-prog-u q '(interleave '() (cons 6 '()))) '(6))
      (evalo-u (interleave-prog-u q '(interleave (cons 5 '()) (cons 6 '()))) '(5 6))
      (evalo-u (interleave-prog-u q '(interleave (cons 5 (cons 7 '())) (cons 6 (cons 8 '())))) '(5 6 7 8)))))
