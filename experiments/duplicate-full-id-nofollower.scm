;; duplicate-full-id-nofollower.scm --- size-closed ID baseline (no follower)
;; for the `duplicate` benchmark (each list element doubled), the paired
;; baseline for experiments/duplicate-full-id-views.scm (same template,
;; examples, absento exclusions, and bounds; the follower is the only
;; difference).  Same structure as rember-full-id-nofollower.scm /
;; append-full-id-nofollower.scm: whole body is a hole, iterative deepening on
;; term size, no follower.
;;
;;   ./run.sh --timeout 600 experiments/duplicate-full-id-nofollower.scm
;;
;; Answer (found at bound 39; see experiments/ablation.md, duplicate rows):
;;   (match l ['() l] [(cons a d) (cons a (cons a (duplicate d)))])
;; Bounds 11..47 step 4 bracket the answer at 39.  main-unsound-depth 1000,
;; matching the existing benchmarks' calibration.

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
