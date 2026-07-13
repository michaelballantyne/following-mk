;; swap-involution-id-ty.scm --- WAVE 2b, Michael's harder-task probe.
;; swap-pairs is HARDER than rev (nested match, canonical ~bound 63) and has a
;; STRONG involution: swap∘swap = id.  Tests whether a strong (output-fixing)
;; property pays off on a hard task where a single anchor may under-pin --
;; the regime the append/rember/rev correction did NOT cover (those paired
;; strong properties with the easy rev, or hard tasks with only weak
;; properties).  Compare swap-anchor-only-id-ty.scm.
;;
;; Property: (swap (swap X)) = X over symbolic X of shapes len 2, 4, PLUS the
;; ground anchor (swap (5 6 7 8)) = (6 5 8 7) to kill the identity degenerate
;; (id∘id=id).  Caveat (Michael): the double application on a 4-element list is
;; deep entangled eval -- this arm may be infeasible; if so that is itself the
;; finding (the property makes the follower blow up exactly on the hard task
;; where it would help authoring).
;;
;;   ./run.sh --check-follower-every 1 --main-unsound-depth 1000 \
;;     --timeout 240 experiments/swap-involution-id-ty.scm

(load "restricted-interp-untyped.scm")
(load "restricted-interp-untyped-following.scm")
(load "experiments/id-harness.scm")
(load "views.scm") ; R1+R2+TY+NV

(define swap-tyenv '((swap . ((list) -> list)) (l . list)))

(define (swap-prog-u q body)
  `(letrec ([swap (lambda (l)
                    ,q)])
     ,body))

(run-id "swap-involution/ty" '(15 23 31 39 47 55 63 71) 1000
  (lambda (bound)
    (run 1 (q)
      (fresh (x1 x2 x3 x4 V1 V2)
        (watch-size q)
        (absento 5 q)
        (absento 6 q)
        (absento 7 q)
        (absento 8 q)
        (numbero x1)
        (numbero x2)
        (numbero x3)
        (numbero x4)
        (follower
          q
          (fresh/d ()
            (tally/d 'R1 (base-case-patho/d 'swap q))
            (tally/d 'R2 (decreasing-recursiono/d 'swap '(l) q))
            (tally/d 'TY (type-ofo/d swap-tyenv q 'list))
            (tally/d 'NV (non-vacuous-testso/d q))
            (tally/d 'EX (evalo-u/d (swap-prog-u q `(swap (swap (cons ,x1 (cons ,x2 '()))))) `(,x1 ,x2)))
            (tally/d 'EX (evalo-u/d (swap-prog-u q `(swap (swap (cons ,x1 (cons ,x2 (cons ,x3 (cons ,x4 '()))))))) `(,x1 ,x2 ,x3 ,x4)))
            (tally/d 'EX (evalo-u/d (swap-prog-u q '(swap (cons 5 (cons 6 (cons 7 (cons 8 '())))))) '(6 5 8 7)))))
        (evalo-u (swap-prog-u q `(swap (swap (cons ,x1 (cons ,x2 '()))))) `(,x1 ,x2))
        (evalo-u (swap-prog-u q `(swap (swap (cons ,x1 (cons ,x2 (cons ,x3 (cons ,x4 '()))))))) `(,x1 ,x2 ,x3 ,x4))
        (evalo-u (swap-prog-u q '(swap (cons 5 (cons 6 (cons 7 (cons 8 '())))))) '(6 5 8 7))))))
