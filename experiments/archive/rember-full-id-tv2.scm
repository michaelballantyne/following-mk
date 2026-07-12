;; rember-full-id-tv2.scm --- size-closed ID with rung-1 + rung-2 termination
;; views conjoined in the follower (base-case-patho/d + decreasing-recursiono/d,
;; no evalo/d).  Extends experiments/rember-full-id-tv-only.scm: rung 2 refutes
;; base-case bodies that still diverge via non-structurally-decreasing recursion
;; -- the population the capstone identified as dominating levels 39/43
;; (depth-cut 918/3160).
;;
;;   ./run.sh --check-follower-every 20 --timeout 850 \
;;     experiments/rember-full-id-tv2.scm

(load "experiments/id-harness.scm")
(load "views.scm") ; loads termination-view.scm too

(define (rember-prog q body)
  `(letrec ([rember (lambda (e l) : ((number list) -> list)
                      ,q)])
     ,body))

(run-id "rember-full/tv2" '(15 19 23 27 31 35 39 43 47 51) 1000
  (lambda (bound)
    (run 1 (q)
      (watch-size q)
      (absento 3 q)
      (absento 4 q)
      (absento 5 q)
      (absento 6 q)
      (absento 7 q)
      (follower
        q
        (fresh/d ()
          (base-case-patho/d 'rember q)
          (decreasing-recursiono/d 'rember '(e l) q)))
      (evalo (rember-prog q '(rember 5 '())) '())
      (evalo (rember-prog q '(rember 6 (cons 6 '()))) '())
      (evalo (rember-prog q '(rember 7 (cons 3 (cons 4 (cons 7 (cons 6 '())))))) '(3 4 6))
      (evalo (rember-prog q '(rember 5 (cons 3 (cons 4 (cons 6 (cons 7 '())))))) '(3 4 6 7)))))
