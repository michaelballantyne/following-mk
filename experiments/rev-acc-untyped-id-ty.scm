;; rev-acc-untyped-id-ty.scm --- UNTYPED generator, WITH the type view
;; (accumulator-reverse).  See rember-untyped-id-ty.scm for the experiment
;; framing.  rev-tyenv is not defined in views.scm, so we define it here.  The
;; second parameter `acc` is a pure accumulator (never a decreasing recursion
;; argument), so R2 must commit position 1.  Each follower view goal is wrapped
;; in tally/d ('R1 'R2 'TY 'NV 'EX) for per-view refute/force attribution
;; (following.scm); the four examples share 'EX.
;;
;;   ./run.sh --check-follower-every 1 --main-unsound-depth 1000 \
;;     --timeout 240 experiments/rev-acc-untyped-id-ty.scm

(load "restricted-interp-untyped.scm")
(load "restricted-interp-untyped-following.scm")
(load "experiments/id-harness.scm")
(load "views.scm") ; R1+R2+TY+NV view definitions

(define rev-tyenv '((rev . ((list list) -> list)) (l . list) (acc . list)))

(define (rev-prog-u q body)
  `(letrec ([rev (lambda (l acc)
                   ,q)])
     ,body))

(run-id "rev-acc-untyped/ty" '(11 15 19 23 27 31 35 39) 1000
  (lambda (bound)
    (run 1 (q)
      (watch-size q)
      (absento 5 q)
      (absento 6 q)
      (absento 7 q)
      (follower
        q
        (fresh/d ()
          (tally/d 'R1 (base-case-patho/d 'rev q))
          (tally/d 'R2 (decreasing-recursiono/d 'rev '(l acc) q))
          (tally/d 'TY (type-ofo/d rev-tyenv q 'list))
          (tally/d 'NV (non-vacuous-testso/d q))
          (tally/d 'EX (evalo-u/d (rev-prog-u q '(rev '() '())) '()))
          (tally/d 'EX (evalo-u/d (rev-prog-u q '(rev (cons 5 '()) '())) '(5)))
          (tally/d 'EX (evalo-u/d (rev-prog-u q '(rev (cons 5 (cons 6 '())) '())) '(6 5)))
          (tally/d 'EX (evalo-u/d (rev-prog-u q '(rev (cons 5 (cons 6 (cons 7 '()))) '())) '(7 6 5)))))
      (evalo-u (rev-prog-u q '(rev '() '())) '())
      (evalo-u (rev-prog-u q '(rev (cons 5 '()) '())) '(5))
      (evalo-u (rev-prog-u q '(rev (cons 5 (cons 6 '())) '())) '(6 5))
      (evalo-u (rev-prog-u q '(rev (cons 5 (cons 6 (cons 7 '()))) '())) '(7 6 5)))))
