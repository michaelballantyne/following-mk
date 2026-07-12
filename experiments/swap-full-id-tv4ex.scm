;; swap-full-id-tv4ex.scm --- size-closed ID synthesis of `swap-pairs`, the full
;; follower stack (R1+R2+TY+NV) PLUS evalo/d over the examples, check-every 1.
;; Mirrors experiments/rember-full-id-tv4ex.scm.  This is the BIGGEST answer in
;; the suite.
;;
;; Task: swap : ((list) -> list).  Swap adjacent pairs; a final odd element is
;; kept in place.  (a b c d) -> (b a d c); (a b c) -> (b a c).
;;
;; Canonical body (answer):
;;   (match l ['() '()]
;;     [(cons a d) (match d ['() (cons a '())]
;;                   [(cons b dd) (cons b (cons a (swap dd)))])])
;; Size under the repo measure (pattern-binders a,d,b,dd = 0): 74.
;; Expected answer at bound 75 (bounds 43..79 step 4; 74 first lands on grid 75).
;;
;; Examples (4), and the degenerates each kills:
;;   (swap ())          => ()        base
;;   (swap (5))         => (5)       odd leftover at top level
;;   (swap (5 6))       => (6 5)     one swap (kills identity)
;;   (swap (5 6 7 8))   => (6 5 8 7) TWO swaps -> forces recursion; kills the
;;                                   non-recursive "swap first pair, splice tail"
;;                                   body, which yields (6 5 7 8) here.
;; A 3-element case (5 6 7)->(6 5 7) would additionally exercise an odd leftover
;; INSIDE the recursion; it is not separately pinned here (the 4-element case
;; already forces the recursive call), so a smaller body that happens to agree
;; on these four inputs is conceivable but not expected -- noted rather than
;; chased.  Absento excludes example constants 5,6,7,8; the canonical body has
;; no numeric literals.
;;
;;   ./run.sh --check-follower-every 1 --timeout 500 experiments/swap-full-id-tv4ex.scm
(load "experiments/id-harness.scm")
(load "experiments/termination-view4.scm") ; loads tv3 (=> tv2 => tv1) too

(define (swap-prog q body)
  `(letrec ([swap (lambda (l) : ((list) -> list)
                    ,q)])
     ,body))

(define swap-tyenv '((swap . ((list) -> list)) (l . list)))

(run-id "swap-full/tv4ex" '(43 47 51 55 59 63 67 71 75 79) 1000
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
          (base-case-patho/d 'swap q)
          (decreasing-recursiono/d 'swap '(l) q)
          (type-ofo/d swap-tyenv q 'list)
          (non-vacuous-testso/d q)
          (evalo/d (swap-prog q '(swap '())) '())
          (evalo/d (swap-prog q '(swap (cons 5 '()))) '(5))
          (evalo/d (swap-prog q '(swap (cons 5 (cons 6 '())))) '(6 5))
          (evalo/d (swap-prog q '(swap (cons 5 (cons 6 (cons 7 (cons 8 '())))))) '(6 5 8 7))))
      (evalo (swap-prog q '(swap '())) '())
      (evalo (swap-prog q '(swap (cons 5 '()))) '(5))
      (evalo (swap-prog q '(swap (cons 5 (cons 6 '())))) '(6 5))
      (evalo (swap-prog q '(swap (cons 5 (cons 6 (cons 7 (cons 8 '())))))) '(6 5 8 7)))))
