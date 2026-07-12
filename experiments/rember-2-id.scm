;; rember-2-id.scm --- iterative-deepening version of the rember hole-2
;; synthesis task (see synthesis/rember-2.scm).
;;
;; The hole `,p` replaces the recursive call `(rember e d)` in the
;; else-branch.  Here the main search is *size-closed*: instead of fair
;; interleaving it is bounded by *max-term-size* on the query var, and
;; run at an ascending sequence of bounds (iterative deepening).  Two
;; arms per level: bounded search alone (arm A) vs bounded search plus
;; follower (arm B).  This file also doubles as the fast validation of
;; the harness.
;;
;; Expected answer: p = (rember e d), size 7 under term-size-lb.
;; Levels 3 and 5 find nothing; the answer appears at bound 7.
;;
;; NOTE ON *main-unsound-depth*: the spec called for 500, but under this
;; size-closed formulation the winning branch reaches main-search depth
;; between 500 and 800, so 500 unsoundly prunes the answer (both arms
;; return () even at bound 9).  Raised to 1000 (comfortable margin above
;; the ~800 threshold) so the answer is actually found; the value is a
;; harness argument, so only this constant changed, not the machinery.
;;
;; Run via:
;;   ./run.sh --timeout 300 experiments/rember-2-id.scm

(load "experiments/id-harness.scm")

(define (rember-prog p body)
  `(letrec ([rember (lambda (e l) : ((number list) -> list)
                      (match l
                        ['() l]
                        [(cons a d)
                         (if (= a e)
                             d
                             (cons a ,p))]))])
     ,body))

;; Arm A: bounded search alone (no follower).
(run-id "rember-2/no-follower" '(3 5 7 9) 1000
  (lambda (bound)
    (run 1 (p)
      (watch-size p)
      (evalo (rember-prog p '(rember 5 '())) '())
      (evalo (rember-prog p '(rember 6 (cons 6 '()))) '())
      (evalo (rember-prog p '(rember 7 (cons 3 '()))) '(3))
      (evalo (rember-prog p '(rember 4 (cons 3 (cons 6 (cons 4 '()))))) '(3 6))
      (evalo (rember-prog p '(rember 4 (cons 3 (cons 6 (cons 4 (cons 7 '())))))) '(3 6 7))
      (evalo (rember-prog p '(rember 7 (cons 3 (cons 4 (cons 5 (cons 7 '())))))) '(3 4 5)))))

;; Arm B: bounded search + follower.
(run-id "rember-2/with-follower" '(3 5 7 9) 1000
  (lambda (bound)
    (run 1 (p)
      (watch-size p)
      (follower
        p
        (fresh/d ()
          (evalo/d (rember-prog p '(rember 5 '())) '())
          (evalo/d (rember-prog p '(rember 6 (cons 6 '()))) '())
          (evalo/d (rember-prog p '(rember 7 (cons 3 '()))) '(3))
          (evalo/d (rember-prog p '(rember 4 (cons 3 (cons 6 (cons 4 '()))))) '(3 6))
          (evalo/d (rember-prog p '(rember 4 (cons 3 (cons 6 (cons 4 (cons 7 '())))))) '(3 6 7))
          (evalo/d (rember-prog p '(rember 7 (cons 3 (cons 4 (cons 5 (cons 7 '())))))) '(3 4 5))))
      (evalo (rember-prog p '(rember 5 '())) '())
      (evalo (rember-prog p '(rember 6 (cons 6 '()))) '())
      (evalo (rember-prog p '(rember 7 (cons 3 '()))) '(3))
      (evalo (rember-prog p '(rember 4 (cons 3 (cons 6 (cons 4 '()))))) '(3 6))
      (evalo (rember-prog p '(rember 4 (cons 3 (cons 6 (cons 4 (cons 7 '())))))) '(3 6 7))
      (evalo (rember-prog p '(rember 7 (cons 3 (cons 4 (cons 5 (cons 7 '())))))) '(3 4 5)))))
