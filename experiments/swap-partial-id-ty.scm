;; swap-partial-id-ty.scm --- WAVE 2b: PARTIAL OUTPUTS.
;; UNTYPED generator, WITH the type view (swap-pairs).  Mirrors
;; swap-untyped-id-ty.scm EXCEPT each expected OUTPUT of the multi-element
;; examples is made PARTIAL by hiding its tail behind a fresh, unconstrained
;; logic var: only the known head element is pinned.  Ground inputs, holey
;; outputs -- the cleanest place to observe the refute->force flip the wave-2
;; reflection predicts (the known output prefix propagates backward through
;; evalo/d into candidate structure).
;;
;; Task swap : ((list) -> list); swap adjacent pairs, final odd element kept.
;; Canonical body (accepted by all views):
;;   (match l ['() '()] [(cons a d) (match d ['() (cons a '())]
;;                        [(cons b dd) (cons b (cons a (swap dd)))])])
;; (The machine-minimal variant returns `l` in the two base cases; see the
;; swap-full-id-views.scm header.)
;;
;; The four examples (V2, V4 fresh, opened in the run, distinct):
;;   (swap ())          = ()          ground (no tail to hide)
;;   (swap (5))         = (5)         ground (singleton: no tail to hide)
;;   (swap (5 6))       = (6 . V2)    head 6 kept, tail hole
;;   (swap (5 6 7 8))   = (6 . V4)    head 6 kept, tail hole
;;
;; WEAKNESS WITNESS (see gates in experiments/wave2-gates.scm): the
;; NON-RECURSIVE "swap first pair, splice the rest unchanged" body
;;   (match l ['() l] [(cons a d) (match d ['() l] [(cons b dd) (cons b (cons a dd))])])
;; produces (6 5 7 8) on (5 6 7 8) -- head 6 is CORRECT, so it SATISFIES the
;; partial spec (V4 = (5 7 8)) -- yet FAILS the full ground spec (6 5 8 7).
;; This is exactly the degenerate the 4-element FULL example kills; the partial
;; spec no longer kills it.  So the partial spec is genuinely WEAKER on
;; refutation.  Whether it stays FEASIBLE (forcing must compensate) is the open
;; wave-2 question the arm measures; a concrete-example anchor may be needed.
;;
;; absento 5,6,7,8 and bounds match swap-untyped-id-ty.scm / swap-full-id-views.
;;
;;   ./run.sh --check-follower-every 1 --main-unsound-depth 1000 \
;;     --timeout 240 experiments/swap-partial-id-ty.scm

(load "restricted-interp-untyped.scm")
(load "restricted-interp-untyped-following.scm")
(load "experiments/id-harness.scm")
(load "views.scm") ; R1+R2+TY+NV view definitions

(define swap-tyenv '((swap . ((list) -> list)) (l . list)))

(define (swap-prog-u q body)
  `(letrec ([swap (lambda (l)
                    ,q)])
     ,body))

(run-id "swap-partial/ty" '(43 47 51 55 59 63 67 71 75 79) 1000
  (lambda (bound)
    (run 1 (q)
      (fresh (V2 V4)
        (watch-size q)
        (absento 5 q)
        (absento 6 q)
        (absento 7 q)
        (absento 8 q)
        (follower
          q
          (fresh/d ()
            (tally/d 'R1 (base-case-patho/d 'swap q))
            (tally/d 'R2 (decreasing-recursiono/d 'swap '(l) q))
            (tally/d 'TY (type-ofo/d swap-tyenv q 'list))
            (tally/d 'NV (non-vacuous-testso/d q))
            (tally/d 'EX (evalo-u/d (swap-prog-u q '(swap '())) '()))
            (tally/d 'EX (evalo-u/d (swap-prog-u q '(swap (cons 5 '()))) '(5)))
            (tally/d 'EX (evalo-u/d (swap-prog-u q '(swap (cons 5 (cons 6 '())))) `(6 . ,V2)))
            (tally/d 'EX (evalo-u/d (swap-prog-u q '(swap (cons 5 (cons 6 (cons 7 (cons 8 '())))))) `(6 . ,V4)))))
        (evalo-u (swap-prog-u q '(swap '())) '())
        (evalo-u (swap-prog-u q '(swap (cons 5 '()))) '(5))
        (evalo-u (swap-prog-u q '(swap (cons 5 (cons 6 '())))) `(6 . ,V2))
        (evalo-u (swap-prog-u q '(swap (cons 5 (cons 6 (cons 7 (cons 8 '())))))) `(6 . ,V4))))))
