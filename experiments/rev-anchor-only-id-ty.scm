;; rev-anchor-only-id-ty.scm --- WAVE 2b DECISIVE COMPARATOR for rev-involution.
;; The single ground anchor  (rev (5 6) ()) = (6 5)  that rev-involution-id-ty.scm
;; carried ALONGSIDE the involution property, but here WITHOUT the involution
;; examples.  If this alone synthesizes canonical accumulator-reverse, then the
;; wave-2 "property specs are the flagship" conclusion was CONFOUNDED by the
;; anchor -- the involution property would have added cost, not pinning, exactly
;; as the append/rember property arms showed.  UNTYPED generator + TY view.
;;
;;   ./run.sh --check-follower-every 1 --main-unsound-depth 1000 \
;;     --timeout 200 experiments/rev-anchor-only-id-ty.scm

(load "restricted-interp-untyped.scm")
(load "restricted-interp-untyped-following.scm")
(load "experiments/id-harness.scm")
(load "views.scm") ; R1+R2+TY+NV view definitions

(define rev-tyenv '((rev . ((list list) -> list)) (l . list) (acc . list)))

(define (rev-prog-u q body)
  `(letrec ([rev (lambda (l acc)
                   ,q)])
     ,body))

(run-id "rev-anchor-only/ty" '(11 15 19 23 27 31 35 39) 1000
  (lambda (bound)
    (run 1 (q)
      (watch-size q)
      (absento 5 q)
      (absento 6 q)
      (follower
        q
        (fresh/d ()
          (tally/d 'R1 (base-case-patho/d 'rev q))
          (tally/d 'R2 (decreasing-recursiono/d 'rev '(l acc) q))
          (tally/d 'TY (type-ofo/d rev-tyenv q 'list))
          (tally/d 'NV (non-vacuous-testso/d q))
          (tally/d 'EX (evalo-u/d (rev-prog-u q '(rev (cons 5 (cons 6 '())) '())) '(6 5)))))
      (evalo-u (rev-prog-u q '(rev (cons 5 (cons 6 '())) '())) '(6 5)))))
