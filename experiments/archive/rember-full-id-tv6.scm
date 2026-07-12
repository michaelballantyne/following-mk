;; rember-full-id-tv6.scm --- tv4ex (best-known config) + rung 4c
;; (non-vacuous-brancheso/d, termination-view6.scm): the "canonicity family,
;; cousin of 4a" -- (if (= c1 c2) t e) where {t,e} collapse to identical
;; values under the condition. See
;; claude/2026-07-12-204500-examples-earn-after-cleanup.md (post-4a residue,
;; the ~11% "F8" branch-vacuity family) and the design note for this rung.
;;   ./run.sh --check-follower-every 1 --timeout 300 experiments/rember-full-id-tv6.scm
;; Baseline to beat (tv4ex, same benchmark, ce1): 312,236 unify(main),
;; 7,899 conde(main).
(load "experiments/id-harness.scm")
(load "experiments/negative-view-branch-vacuity.scm") ; loads tv4 (=> tv3 => tv2 => tv1) too

(define (rember-prog q body)
  `(letrec ([rember (lambda (e l) : ((number list) -> list)
                      ,q)])
     ,body))

(run-id "rember-full/tv6" '(15 19 23 27 31 35 39 43 47 51) 1000
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
          (decreasing-recursiono/d 'rember '(e l) q)
          (type-ofo/d rember-tyenv q 'list)
          (non-vacuous-testso/d q)
          (non-vacuous-brancheso/d q)
          (evalo/d (rember-prog q '(rember 5 '())) '())
          (evalo/d (rember-prog q '(rember 6 (cons 6 '()))) '())
          (evalo/d (rember-prog q '(rember 7 (cons 3 (cons 4 (cons 7 (cons 6 '())))))) '(3 4 6))
          (evalo/d (rember-prog q '(rember 5 (cons 3 (cons 4 (cons 6 (cons 7 '())))))) '(3 4 6 7))))
      (evalo (rember-prog q '(rember 5 '())) '())
      (evalo (rember-prog q '(rember 6 (cons 6 '()))) '())
      (evalo (rember-prog q '(rember 7 (cons 3 (cons 4 (cons 7 (cons 6 '())))))) '(3 4 6))
      (evalo (rember-prog q '(rember 5 (cons 3 (cons 4 (cons 6 (cons 7 '())))))) '(3 4 6 7)))))
