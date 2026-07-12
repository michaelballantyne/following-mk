;; rember-full-id.scm --- iterative-deepening version of the full rember
;; synthesis task (see synthesis/rember-full.scm).
;;
;; The entire lambda body is a hole (`,q`); the synthesizer has to find
;; the whole match/if/cons/recurse body.  As in rember-2-id, the main
;; search is size-closed via *max-term-size* on the query var, run at an
;; ascending sequence of bounds.  The absento constraints are identical
;; in both arms.  Two arms per level: bounded search alone (arm A) vs
;; bounded search plus follower (arm B).
;;
;; Expected answer size: 47 under term-size-lb (the match/if/cons body).
;; This is a hard task and may well time out before reaching bound 47;
;; that is fine and informative.
;;
;; NOTE ON *main-unsound-depth*: the spec called for 500, but rember-2-id
;; showed 500 unsoundly prunes the winning branch under the size-closed
;; search (its depth exceeds 500).  Raised to 1000 here for consistency.
;;
;; Run via:
;;   ./run.sh --timeout 600 experiments/rember-full-id.scm

(load "experiments/id-harness.scm")

(define (rember-prog q body)
  `(letrec ([rember (lambda (e l) : ((number list) -> list)
                      ,q)])
     ,body))

;; Arm A: bounded search alone (no follower).
(run-id "rember-full/no-follower" '(15 19 23 27 31 35 39 43 47 51) 1000
  (lambda (bound)
    (run 1 (q)
      (watch-size q)
      (absento 3 q)
      (absento 4 q)
      (absento 5 q)
      (absento 6 q)
      (absento 7 q)
      (evalo (rember-prog q '(rember 5 '())) '())
      (evalo (rember-prog q '(rember 6 (cons 6 '()))) '())
      (evalo (rember-prog q '(rember 7 (cons 3 (cons 4 (cons 7 (cons 6 '())))))) '(3 4 6))
      (evalo (rember-prog q '(rember 5 (cons 3 (cons 4 (cons 6 (cons 7 '())))))) '(3 4 6 7)))))

;; Arm B: bounded search + follower.
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
