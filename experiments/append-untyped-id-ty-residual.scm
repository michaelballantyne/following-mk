;; append-untyped-id-ty-residual.scm --- UNTYPED generator, WITH the type view (append).
;; See rember-untyped-id-ty.scm for the experiment framing.  append-tyenv is
;; defined in residual-views.scm.
;; Residual-engine port of append-untyped-id-ty.scm (backlog 3b).
;;
;;   ./run.sh --check-follower-every 1 --main-unsound-depth 1000 \
;;     --timeout 240 experiments/append-untyped-id-ty-residual.scm

(load "restricted-interp-untyped.scm")
(load "residual-interp-following.scm")
(load "residual-interp-untyped-following.scm")
(load "experiments/id-harness.scm")
(load "residual-views.scm") ; R1+R2+TY+NV (residual); defines append-tyenv

(define (append-prog-u q body)
  `(letrec ([append (lambda (l s)
                      ,q)])
     ,body))

(run-id "append-untyped/ty/residual" '(11 15 19 23 27 31 35 39) 1000
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
            (base-case-patho/d-res 'append q)
            (decreasing-recursiono/d-res 'append '(l s) q)
            (type-ofo/d-res append-tyenv q 'list)
            (non-vacuous-testso/d-res q)
            (evalo-u/d-res (append-prog-u q '(append '() (cons 5 (cons 6 '())))) '(5 6))
            (evalo-u/d-res (append-prog-u q '(append (cons 3 (cons 4 (cons 5 '()))) (cons 6 (cons 7 '())))) '(3 4 5 6 7)))))
      (evalo-u (append-prog-u q '(append '() (cons 5 (cons 6 '())))) '(5 6))
      (evalo-u (append-prog-u q '(append (cons 3 (cons 4 (cons 5 '()))) (cons 6 (cons 7 '())))) '(3 4 5 6 7)))))
