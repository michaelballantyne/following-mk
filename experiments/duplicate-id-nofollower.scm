;; duplicate-id-nofollower.scm --- size-closed ID baseline for the third
;; synthesis benchmark, `duplicate` (each list element doubled).  Same
;; structure as rember-full-id-nofollower.scm / append-full-id-nofollower.scm:
;; whole body is a hole, iterative deepening on term size, no follower.
;;
;;   ./run.sh --timeout 600 experiments/duplicate-id-nofollower.scm
;;
;; Target answer:
;;   (match l ['() l] [(cons a d) (cons a (cons a (duplicate d)))])
;; term-size-lb 43 (computed via a 5-line probe loading following.scm; see
;; claude/ note for this benchmark).  Bounds ascend past 43 in steps of 4
;; starting at 11, one level past the answer (47), matching the
;; rember(47->51)/append(35->39) cadence.  main-unsound-depth 1000, matching
;; the existing benchmarks' calibration.

(load "experiments/id-harness.scm")

(define (duplicate-prog q body)
  `(letrec ([duplicate (lambda (l) : ((list) -> list)
                          ,q)])
     ,body))

(run-id "duplicate/no-follower" '(11 15 19 23 27 31 35 39 43 47) 1000
  (lambda (bound)
    (run 1 (q)
      (watch-size q)
      (absento 3 q)
      (absento 4 q)
      (absento 5 q)
      (evalo (duplicate-prog q '(duplicate '())) '())
      (evalo (duplicate-prog q '(duplicate (cons 5 '()))) '(5 5))
      (evalo (duplicate-prog q '(duplicate (cons 3 (cons 4 '())))) '(3 3 4 4)))))
