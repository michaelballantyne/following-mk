;; last-untyped-id-ty.scm --- UNTYPED generator, WITH the type view (last).
;; See rember-untyped-id-ty.scm for the experiment framing.  last-tyenv is not
;; defined in views.scm, so we define it here.  Each follower view goal is
;; wrapped in tally/d ('R1 'R2 'TY 'NV 'EX) for per-view refute/force
;; attribution (following.scm); the three examples share 'EX.
;;
;;   ./run.sh --check-follower-every 1 --main-unsound-depth 1000 \
;;     --timeout 240 experiments/last-untyped-id-ty.scm

(load "restricted-interp-untyped.scm")
(load "restricted-interp-untyped-following.scm")
(load "experiments/id-harness.scm")
(load "views.scm") ; R1+R2+TY+NV view definitions

(define last-tyenv '((last . ((list) -> number)) (l . list)))

(define (last-prog-u q body)
  `(letrec ([last (lambda (l)
                    ,q)])
     ,body))

(run-id "last-untyped/ty" '(19 23 27 31 35 39 43 47 51 55) 1000
  (lambda (bound)
    (run 1 (q)
      (watch-size q)
      (absento 5 q)
      (absento 6 q)
      (absento 7 q)
      (follower
        q
        (fresh/d ()
          (tally/d 'R1 (base-case-patho/d 'last q))
          (tally/d 'R2 (decreasing-recursiono/d 'last '(l) q))
          (tally/d 'TY (type-ofo/d last-tyenv q 'number))
          (tally/d 'NV (non-vacuous-testso/d q))
          (tally/d 'EX (evalo-u/d (last-prog-u q '(last (cons 5 '()))) 5))
          (tally/d 'EX (evalo-u/d (last-prog-u q '(last (cons 5 (cons 6 '())))) 6))
          (tally/d 'EX (evalo-u/d (last-prog-u q '(last (cons 5 (cons 6 (cons 7 '()))))) 7))))
      (evalo-u (last-prog-u q '(last (cons 5 '()))) 5)
      (evalo-u (last-prog-u q '(last (cons 5 (cons 6 '())))) 6)
      (evalo-u (last-prog-u q '(last (cons 5 (cons 6 (cons 7 '()))))) 7))))
