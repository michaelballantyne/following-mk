;; evens-full-id-tv4ex.scm --- size-closed ID synthesis of `evens`, the full
;; follower stack (R1+R2+TY+NV) PLUS evalo/d over the examples, check-every 1.
;; Mirrors experiments/rember-full-id-tv4ex.scm.
;;
;; Task: evens : ((list) -> list).  Every other element starting with the first.
;;   (a b c d e) -> (a c e).
;;
;; Canonical body (answer):
;;   (match l ['() '()]
;;     [(cons a d) (match d ['() (cons a '())]
;;                   [(cons b dd) (cons a (evens dd))])])
;; Size under the repo measure (pattern-binders a,d,b,dd = 0): 69.
;; Expected answer at bound 71 (bounds 39..75 step 4; 69 first lands on grid 71).
;;
;; Examples (4), and the degenerates each kills:
;;   (evens ())        => ()      base
;;   (evens (5))       => (5)      single element (the identity also passes this
;;                                 -- see next)
;;   (evens (5 6))     => (5)      kills identity / "return whole list"
;;   (evens (5 6 7))   => (5 7)    kills "return first element only" (forces the
;;                                 skip-one-then-recurse structure)
;; Note: a lone short example admits identity; the 2-element case rules identity
;; out, and the 3-element case forces the actual every-other recursion. Absento
;; excludes example constants 5,6,7; the canonical body has no numeric literals.
;;
;;   ./run.sh --check-follower-every 1 --timeout 500 experiments/evens-full-id-tv4ex.scm
(load "experiments/id-harness.scm")
(load "experiments/termination-view4.scm") ; loads tv3 (=> tv2 => tv1) too

(define (evens-prog q body)
  `(letrec ([evens (lambda (l) : ((list) -> list)
                     ,q)])
     ,body))

(define evens-tyenv '((evens . ((list) -> list)) (l . list)))

(run-id "evens-full/tv4ex" '(39 43 47 51 55 59 63 67 71 75) 1000
  (lambda (bound)
    (run 1 (q)
      (watch-size q)
      (absento 5 q)
      (absento 6 q)
      (absento 7 q)
      (follower
        q
        (fresh/d ()
          (base-case-patho/d 'evens q)
          (decreasing-recursiono/d 'evens '(l) q)
          (type-ofo/d evens-tyenv q 'list)
          (non-vacuous-testso/d q)
          (evalo/d (evens-prog q '(evens '())) '())
          (evalo/d (evens-prog q '(evens (cons 5 '()))) '(5))
          (evalo/d (evens-prog q '(evens (cons 5 (cons 6 '())))) '(5))
          (evalo/d (evens-prog q '(evens (cons 5 (cons 6 (cons 7 '()))))) '(5 7))))
      (evalo (evens-prog q '(evens '())) '())
      (evalo (evens-prog q '(evens (cons 5 '()))) '(5))
      (evalo (evens-prog q '(evens (cons 5 (cons 6 '())))) '(5))
      (evalo (evens-prog q '(evens (cons 5 (cons 6 (cons 7 '()))))) '(5 7)))))
