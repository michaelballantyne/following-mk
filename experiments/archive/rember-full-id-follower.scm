;; rember-full-id-follower.scm --- one arm of the iterative-deepening rember-full
;; synthesis experiment. The arms live in separate files so a slow arm
;; can't starve the other of wall-clock; run each under its own timeout:
;;   ./run.sh --timeout 3600 experiments/rember-full-id-follower.scm
;;
;; Whole rember body is a hole; 4 examples; with follower (check-every 1).
;; Expected answer size 47 under term-size-lb. main-unsound-depth 1000
;; (calibrated: both ground answers evaluate within depth 1000).
;; Per-level [LEVEL ...] lines are the measurement: on levels below the
;; answer size, unify-main is the work to *exhaust* the same finite
;; subspace in both arms -- the apples-to-apples pruning factor.

(load "experiments/id-harness.scm")

(define (rember-prog q body)
  `(letrec ([rember (lambda (e l) : ((number list) -> list)
                      ,q)])
     ,body))

(run-id "rember-full/with-follower" '(15 19 23 27 31 35 39 43 47 51) 1000
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
          (evalo/d (rember-prog q '(rember 5 '())) '())
          (evalo/d (rember-prog q '(rember 6 (cons 6 '()))) '())
          (evalo/d (rember-prog q '(rember 7 (cons 3 (cons 4 (cons 7 (cons 6 '())))))) '(3 4 6))
          (evalo/d (rember-prog q '(rember 5 (cons 3 (cons 4 (cons 6 (cons 7 '())))))) '(3 4 6 7))))
      (evalo (rember-prog q '(rember 5 '())) '())
      (evalo (rember-prog q '(rember 6 (cons 6 '()))) '())
      (evalo (rember-prog q '(rember 7 (cons 3 (cons 4 (cons 7 (cons 6 '())))))) '(3 4 6))
      (evalo (rember-prog q '(rember 5 (cons 3 (cons 4 (cons 6 (cons 7 '())))))) '(3 4 6 7)))))
