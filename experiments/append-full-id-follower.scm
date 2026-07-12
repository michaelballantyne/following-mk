;; append-full-id-follower.scm --- one arm of the iterative-deepening append-full
;; synthesis experiment. The arms live in separate files so a slow arm
;; can't starve the other of wall-clock; run each under its own timeout:
;;   ./run.sh --timeout 3600 experiments/append-full-id-follower.scm
;;
;; Whole append body is a hole; 2 examples; with follower (check-every 1).
;; Expected answer size 35 under term-size-lb. main-unsound-depth 1000
;; (calibrated: both ground answers evaluate within depth 1000).
;; Per-level [LEVEL ...] lines are the measurement: on levels below the
;; answer size, unify-main is the work to *exhaust* the same finite
;; subspace in both arms -- the apples-to-apples pruning factor.

(load "experiments/id-harness.scm")

(define (append-prog q body)
  `(letrec ([append (lambda (l s) : ((list list) -> list)
                      ,q)])
     ,body))

(run-id "append-full/with-follower" '(11 15 19 23 27 31 35 39) 1000
  (lambda (bound)
    (run 1 (q)
      (watch-size q)
      (absento '3 q)
      (absento '4 q)
      (absento '5 q)
      (absento '6 q)
      (absento '7 q)
      (follower
        q
        (fresh/d ()
          (evalo/d (append-prog q '(append '() (cons 5 (cons 6 '())))) '(5 6))
          (evalo/d (append-prog q '(append (cons 3 (cons 4 (cons 5 '()))) (cons 6 (cons 7 '()))))
                   '(3 4 5 6 7))))
      (evalo (append-prog q '(append '() (cons 5 (cons 6 '())))) '(5 6))
      (evalo (append-prog q '(append (cons 3 (cons 4 (cons 5 '()))) (cons 6 (cons 7 '()))))
             '(3 4 5 6 7)))))
