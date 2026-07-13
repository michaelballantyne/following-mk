;; rember-idem-property-id-ty.scm --- WAVE 2b: PROPERTY / relational spec.
;; rember IDEMPOTENCE  rember e (rember e l) = rember e l  over symbolic bounded
;; inputs, PLUS one ground anchor  (rember 5 (6 5)) = (6).  UNTYPED gen + TY view.
;;
;; Idempotence is WEAKER than involution: its RHS is candidate-dependent, so it
;; is satisfied by identity and the head-only degenerate (proven in
;; wave2b-property-gates.scm).  The single anchor forces recursion PAST a
;; non-match and drop-deeper, killing both.  Compare:
;;   rember-anchor-only-id-ty.scm  (same anchor, no property)
;;   rember-idem-only-id-ty.scm    (property, no anchor)  -> degenerate
;;
;;   ./run.sh --check-follower-every 1 --main-unsound-depth 1000 \
;;     --timeout 240 experiments/rember-idem-property-id-ty.scm

(load "restricted-interp-untyped.scm")
(load "restricted-interp-untyped-following.scm")
(load "experiments/id-harness.scm")
(load "views.scm") ; R1+R2+TY+NV; defines rember-tyenv

(define (rember-prog-u q body)
  `(letrec ([rember (lambda (e l)
                      ,q)])
     ,body))

(run-id "rember-idem-property/ty" '(15 19 23 27 31 35 39 43 47 51) 1000
  (lambda (bound)
    (run 1 (q)
      (fresh (e x1 x2 V1 V2)
        (watch-size q)
        (absento 5 q)
        (absento 6 q)
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
            (tally/d 'EX (evalo-u/d (rember-prog-u q `(rember ,e (cons ,x1 (cons ,x2 '())))) V2))
            (tally/d 'EX (evalo-u/d (rember-prog-u q '(rember 5 (cons 6 (cons 5 '())))) '(6)))))
        (evalo-u (rember-prog-u q `(rember ,e (rember ,e (cons ,x1 '())))) V1)
        (evalo-u (rember-prog-u q `(rember ,e (cons ,x1 '()))) V1)
        (evalo-u (rember-prog-u q `(rember ,e (rember ,e (cons ,x1 (cons ,x2 '()))))) V2)
        (evalo-u (rember-prog-u q `(rember ,e (cons ,x1 (cons ,x2 '())))) V2)
        (evalo-u (rember-prog-u q '(rember 5 (cons 6 (cons 5 '())))) '(6))))))
