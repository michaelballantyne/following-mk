;; append-anchor-only-id-ty.scm --- WAVE 2b COMPARATOR: the SAME single ground
;; anchor used by append-assoc-property-id-ty.scm, but WITHOUT the associativity
;; property.  Isolates what the relational property adds on top of the anchor it
;; needs anyway: if property+anchor and anchor-only reach the same answer at the
;; same bound/cost, the property adds nothing for PINNING (it may still matter as
;; the E&T-inaccessible half of the story).  UNTYPED generator + TY view.
;;
;;   ./run.sh --check-follower-every 1 --main-unsound-depth 1000 \
;;     --timeout 240 experiments/append-anchor-only-id-ty.scm

(load "restricted-interp-untyped.scm")
(load "restricted-interp-untyped-following.scm")
(load "experiments/id-harness.scm")
(load "views.scm") ; R1+R2+TY+NV; defines append-tyenv

(define (append-prog-u q body)
  `(letrec ([append (lambda (l s)
                      ,q)])
     ,body))

(run-id "append-anchor-only/ty" '(11 15 19 23 27 31 35 39) 1000
  (lambda (bound)
    (run 1 (q)
      (watch-size q)
      (absento 3 q)
      (absento 4 q)
      (absento 5 q)
      (follower
        q
        (fresh/d ()
          (tally/d 'R1 (base-case-patho/d 'append q))
          (tally/d 'R2 (decreasing-recursiono/d 'append '(l s) q))
          (tally/d 'TY (type-ofo/d append-tyenv q 'list))
          (tally/d 'NV (non-vacuous-testso/d q))
          (tally/d 'EX (evalo-u/d (append-prog-u q '(append (cons 3 (cons 4 '())) (cons 5 '()))) '(3 4 5)))))
      (evalo-u (append-prog-u q '(append (cons 3 (cons 4 '())) (cons 5 '()))) '(3 4 5)))))
