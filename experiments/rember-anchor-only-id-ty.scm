;; rember-anchor-only-id-ty.scm --- WAVE 2b COMPARATOR: the SAME single ground
;; anchor  (rember 5 (6 5)) = (6)  used by rember-idem-property-id-ty.scm, but
;; WITHOUT the idempotence property.  Isolates what the property adds for
;; pinning.  rember is the interesting case: one anchor likely UNDER-pins (many
;; programs map (6 5) -> (6)), so this arm may itself return a degenerate --
;; in which case the property either rescues it or does not.  UNTYPED gen + TY.
;;
;;   ./run.sh --check-follower-every 1 --main-unsound-depth 1000 \
;;     --timeout 240 experiments/rember-anchor-only-id-ty.scm

(load "restricted-interp-untyped.scm")
(load "restricted-interp-untyped-following.scm")
(load "experiments/id-harness.scm")
(load "views.scm") ; R1+R2+TY+NV; defines rember-tyenv

(define (rember-prog-u q body)
  `(letrec ([rember (lambda (e l)
                      ,q)])
     ,body))

(run-id "rember-anchor-only/ty" '(15 19 23 27 31 35 39 43 47 51) 1000
  (lambda (bound)
    (run 1 (q)
      (watch-size q)
      (absento 5 q)
      (absento 6 q)
      (follower
        q
        (fresh/d ()
          (tally/d 'R1 (base-case-patho/d 'rember q))
          (tally/d 'R2 (decreasing-recursiono/d 'rember '(e l) q))
          (tally/d 'TY (type-ofo/d rember-tyenv q 'list))
          (tally/d 'NV (non-vacuous-testso/d q))
          (tally/d 'EX (evalo-u/d (rember-prog-u q '(rember 5 (cons 6 (cons 5 '())))) '(6)))))
      (evalo-u (rember-prog-u q '(rember 5 (cons 6 (cons 5 '())))) '(6)))))
