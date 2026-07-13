;; rember-full-id-views-residual.scm --- the current best configuration: size-closed ID
;; with all four structural/type views PLUS evalo/d over the examples,
;; check-every 1. Total to canonical answer: 312,236 unify(main) — 10.3x
;; below the fair-search baseline. See
;; claude/2026-07-12-204500-examples-earn-after-cleanup.md.
;; Residual-engine port of rember-full-id-views.scm (backlog 3b).
;;   ./run.sh --check-follower-every 1 --timeout 500 experiments/rember-full-id-views-residual.scm
(load "experiments/id-harness.scm")
(load "residual-views.scm") ; R1+R2+TY+NV view definitions (residual)
(load "residual-interp-following.scm")

(define (rember-prog q body)
  `(letrec ([rember (lambda (e l) : ((number list) -> list)
                      ,q)])
     ,body))

(run-id "rember-full/views/residual" '(15 19 23 27 31 35 39 43 47 51) 1000
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
        (follower-residual-goal
          (rfresh/d ()
            (base-case-patho/d-res 'rember q)
            (decreasing-recursiono/d-res 'rember '(e l) q)
            (type-ofo/d-res rember-tyenv q 'list)
            (non-vacuous-testso/d-res q)
            (evalo/d-res (rember-prog q '(rember 5 '())) '())
            (evalo/d-res (rember-prog q '(rember 6 (cons 6 '()))) '())
            (evalo/d-res (rember-prog q '(rember 7 (cons 3 (cons 4 (cons 7 (cons 6 '())))))) '(3 4 6))
            (evalo/d-res (rember-prog q '(rember 5 (cons 3 (cons 4 (cons 6 (cons 7 '())))))) '(3 4 6 7)))))
      (evalo (rember-prog q '(rember 5 '())) '())
      (evalo (rember-prog q '(rember 6 (cons 6 '()))) '())
      (evalo (rember-prog q '(rember 7 (cons 3 (cons 4 (cons 7 (cons 6 '())))))) '(3 4 6))
      (evalo (rember-prog q '(rember 5 (cons 3 (cons 4 (cons 6 (cons 7 '())))))) '(3 4 6 7)))))
