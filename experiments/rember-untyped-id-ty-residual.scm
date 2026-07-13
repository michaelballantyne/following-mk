;; rember-untyped-id-ty-residual.scm --- UNTYPED generator, WITH the type view.
;;
;; Same as rember-untyped-id-noty.scm but the follower additionally carries
;; TY (type-ofo/d) under rember-tyenv.  Types now live ONLY in this view: the
;; interpreter template carries no `: type` annotation, yet the arrow type of
;; the letrec-bound `rember` and its parameters is supplied to type-ofo/d via
;; rember-tyenv (defined in residual-views.scm).  This measures whether the
;; type view flips from useless (fully overlapped, see ablation.md) to
;; load-bearing once type information is absent from generation.
;; Residual-engine port of rember-untyped-id-ty.scm (backlog 3b).
;;
;;   ./run.sh --check-follower-every 1 --main-unsound-depth 1000 \
;;     --timeout 240 experiments/rember-untyped-id-ty-residual.scm

(load "restricted-interp-untyped.scm")
(load "residual-interp-following.scm")
(load "residual-interp-untyped-following.scm")
(load "experiments/id-harness.scm")
(load "residual-views.scm") ; R1+R2+TY+NV (residual); defines rember-tyenv

(define (rember-prog-u q body)
  `(letrec ([rember (lambda (e l)
                      ,q)])
     ,body))

(run-id "rember-untyped/ty/residual" '(15 19 23 27 31 35 39 43 47 51) 1000
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
            (evalo-u/d-res (rember-prog-u q '(rember 5 '())) '())
            (evalo-u/d-res (rember-prog-u q '(rember 6 (cons 6 '()))) '())
            (evalo-u/d-res (rember-prog-u q '(rember 7 (cons 3 (cons 4 (cons 7 (cons 6 '())))))) '(3 4 6))
            (evalo-u/d-res (rember-prog-u q '(rember 5 (cons 3 (cons 4 (cons 6 (cons 7 '())))))) '(3 4 6 7)))))
      (evalo-u (rember-prog-u q '(rember 5 '())) '())
      (evalo-u (rember-prog-u q '(rember 6 (cons 6 '()))) '())
      (evalo-u (rember-prog-u q '(rember 7 (cons 3 (cons 4 (cons 7 (cons 6 '())))))) '(3 4 6))
      (evalo-u (rember-prog-u q '(rember 5 (cons 3 (cons 4 (cons 6 (cons 7 '())))))) '(3 4 6 7)))))
