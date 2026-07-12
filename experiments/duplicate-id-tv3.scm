;; duplicate-id-tv3.scm --- size-closed ID with THREE termination/type views
;; conjoined in the follower, for `duplicate`.  Matches
;; experiments/rember-full-id-tv3.scm's pattern exactly: the follower is
;; VIEW-ONLY (base-case-patho/d + decreasing-recursiono/d + type-ofo/d,
;; conjoined with fresh/d) -- no evalo/d inside the follower.  The `run`'s
;; own top-level evalo examples do the actual example-checking, as usual.
;;
;;   ./run.sh --check-follower-every 1 --timeout 600 experiments/duplicate-id-tv3.scm
;;   ./run.sh --check-follower-every 20 --timeout 600 experiments/duplicate-id-tv3.scm

(load "experiments/id-harness.scm")
(load "experiments/termination-view3.scm") ; loads tv2 (=> tv1) too

(define (duplicate-prog q body)
  `(letrec ([duplicate (lambda (l) : ((list) -> list)
                          ,q)])
     ,body))

(define duplicate-tyenv '((duplicate . ((list) -> list)) (l . list)))

(run-id "duplicate/tv3" '(11 15 19 23 27 31 35 39 43 47) 1000
  (lambda (bound)
    (run 1 (q)
      (watch-size q)
      (absento 3 q)
      (absento 4 q)
      (absento 5 q)
      (follower
        q
        (fresh/d ()
          (base-case-patho/d 'duplicate q)
          (decreasing-recursiono/d 'duplicate '(l) q)
          (type-ofo/d duplicate-tyenv q 'list)))
      (evalo (duplicate-prog q '(duplicate '())) '())
      (evalo (duplicate-prog q '(duplicate (cons 5 '()))) '(5 5))
      (evalo (duplicate-prog q '(duplicate (cons 3 (cons 4 '())))) '(3 3 4 4)))))
