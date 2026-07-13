;; rember-idem-only-id-ty.scm --- WAVE 2b: idempotence PROPERTY ALONE, NO anchor.
;; Prediction (wave2b-property-gates.scm): returns a DEGENERATE (identity l, the
;; smallest idempotent body).  UNTYPED generator + TY view.
;;
;;   ./run.sh --check-follower-every 1 --main-unsound-depth 1000 \
;;     --timeout 240 experiments/rember-idem-only-id-ty.scm

(load "restricted-interp-untyped.scm")
(load "restricted-interp-untyped-following.scm")
(load "experiments/id-harness.scm")
(load "views.scm") ; R1+R2+TY+NV; defines rember-tyenv

(define (rember-prog-u q body)
  `(letrec ([rember (lambda (e l)
                      ,q)])
     ,body))

(run-id "rember-idem-only/ty" '(15 19 23 27 31 35 39 43 47 51) 1000
  (lambda (bound)
    (run 1 (q)
      (fresh (e x1 x2 V1 V2)
        (watch-size q)
        (numbero e)
        (numbero x1)
        (numbero x2)
        (follower
          q
          (fresh/d ()
            (tally/d 'R1 (base-case-patho/d 'rember q))
            (tally/d 'R2 (decreasing-recursiono/d 'rember '(e l) q))
            (tally/d 'TY (type-ofo/d rember-tyenv q 'list))
            (tally/d 'NV (non-vacuous-testso/d q))
            (tally/d 'EX (evalo-u/d (rember-prog-u q `(rember ,e (rember ,e (cons ,x1 '())))) V1))
            (tally/d 'EX (evalo-u/d (rember-prog-u q `(rember ,e (cons ,x1 '()))) V1))
            (tally/d 'EX (evalo-u/d (rember-prog-u q `(rember ,e (rember ,e (cons ,x1 (cons ,x2 '()))))) V2))
            (tally/d 'EX (evalo-u/d (rember-prog-u q `(rember ,e (cons ,x1 (cons ,x2 '())))) V2))))
        (evalo-u (rember-prog-u q `(rember ,e (rember ,e (cons ,x1 '())))) V1)
        (evalo-u (rember-prog-u q `(rember ,e (cons ,x1 '()))) V1)
        (evalo-u (rember-prog-u q `(rember ,e (rember ,e (cons ,x1 (cons ,x2 '()))))) V2)
        (evalo-u (rember-prog-u q `(rember ,e (cons ,x1 (cons ,x2 '())))) V2)))))
