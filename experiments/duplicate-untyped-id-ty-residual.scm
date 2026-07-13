;; duplicate-untyped-id-ty-residual.scm --- UNTYPED generator, WITH the type view
;; (duplicate).  See rember-untyped-id-ty.scm for the experiment framing.
;; duplicate-tyenv is not defined in residual-views.scm either (only
;; rember/append are), so we define it here -- the arrow type of the
;; letrec-bound function and its parameter, supplied to type-ofo/d-res even
;; though the interpreter template no longer carries the annotation.
;; Residual-engine port of duplicate-untyped-id-ty.scm (backlog 3b).
;;
;;   ./run.sh --check-follower-every 1 --main-unsound-depth 1000 \
;;     --timeout 240 experiments/duplicate-untyped-id-ty-residual.scm

(load "restricted-interp-untyped.scm")
(load "residual-interp-following.scm")
(load "residual-interp-untyped-following.scm")
(load "experiments/id-harness.scm")
(load "residual-views.scm") ; R1+R2+TY+NV view definitions (residual)

(define duplicate-tyenv '((duplicate . ((list) -> list)) (l . list)))

(define (duplicate-prog-u q body)
  `(letrec ([duplicate (lambda (l)
                         ,q)])
     ,body))

(run-id "duplicate-untyped/ty/residual" '(11 15 19 23 27 31 35 39 43 47) 1000
  (lambda (bound)
    (run 1 (q)
      (watch-size q)
      (absento 3 q)
      (absento 4 q)
      (absento 5 q)
      (follower
        q
        (follower-residual-goal
          (rfresh/d ()
            (base-case-patho/d-res 'duplicate q)
            (decreasing-recursiono/d-res 'duplicate '(l) q)
            (type-ofo/d-res duplicate-tyenv q 'list)
            (non-vacuous-testso/d-res q)
            (evalo-u/d-res (duplicate-prog-u q '(duplicate '())) '())
            (evalo-u/d-res (duplicate-prog-u q '(duplicate (cons 5 '()))) '(5 5))
            (evalo-u/d-res (duplicate-prog-u q '(duplicate (cons 3 (cons 4 '())))) '(3 3 4 4)))))
      (evalo-u (duplicate-prog-u q '(duplicate '())) '())
      (evalo-u (duplicate-prog-u q '(duplicate (cons 5 '()))) '(5 5))
      (evalo-u (duplicate-prog-u q '(duplicate (cons 3 (cons 4 '())))) '(3 3 4 4)))))
