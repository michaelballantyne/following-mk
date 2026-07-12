;; evens-untyped-id-ty.scm --- UNTYPED generator, WITH the type view (evens).
;; See rember-untyped-id-ty.scm for the experiment framing.  evens-tyenv is not
;; defined in views.scm, so we define it here.  Each follower view goal is
;; wrapped in tally/d ('R1 'R2 'TY 'NV 'EX) for per-view refute/force
;; attribution (following.scm); the FIVE examples (incl. the length-4 case that
;; forces genuine recursion) all share 'EX.
;;
;;   ./run.sh --check-follower-every 1 --main-unsound-depth 1000 \
;;     --timeout 240 experiments/evens-untyped-id-ty.scm

(load "restricted-interp-untyped.scm")
(load "restricted-interp-untyped-following.scm")
(load "experiments/id-harness.scm")
(load "views.scm") ; R1+R2+TY+NV view definitions

(define evens-tyenv '((evens . ((list) -> list)) (l . list)))

(define (evens-prog-u q body)
  `(letrec ([evens (lambda (l)
                     ,q)])
     ,body))

(run-id "evens-untyped/ty" '(39 43 47 51 55 59 63 67 71 75) 1000
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
          (tally/d 'R1 (base-case-patho/d 'evens q))
          (tally/d 'R2 (decreasing-recursiono/d 'evens '(l) q))
          (tally/d 'TY (type-ofo/d evens-tyenv q 'list))
          (tally/d 'NV (non-vacuous-testso/d q))
          (tally/d 'EX (evalo-u/d (evens-prog-u q '(evens '())) '()))
          (tally/d 'EX (evalo-u/d (evens-prog-u q '(evens (cons 5 '()))) '(5)))
          (tally/d 'EX (evalo-u/d (evens-prog-u q '(evens (cons 5 (cons 6 '())))) '(5)))
          (tally/d 'EX (evalo-u/d (evens-prog-u q '(evens (cons 5 (cons 6 (cons 7 '()))))) '(5 7)))
          (tally/d 'EX (evalo-u/d (evens-prog-u q '(evens (cons 5 (cons 6 (cons 7 (cons 8 '())))))) '(5 7)))))
      (evalo-u (evens-prog-u q '(evens '())) '())
      (evalo-u (evens-prog-u q '(evens (cons 5 '()))) '(5))
      (evalo-u (evens-prog-u q '(evens (cons 5 (cons 6 '())))) '(5))
      (evalo-u (evens-prog-u q '(evens (cons 5 (cons 6 (cons 7 '()))))) '(5 7))
      (evalo-u (evens-prog-u q '(evens (cons 5 (cons 6 (cons 7 (cons 8 '())))))) '(5 7)))))
