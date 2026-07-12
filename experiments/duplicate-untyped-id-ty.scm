;; duplicate-untyped-id-ty.scm --- UNTYPED generator, WITH the type view
;; (duplicate).  See rember-untyped-id-ty.scm for the experiment framing.
;; duplicate-tyenv is not defined in views.scm (only rember/append
;; are), so we define it here -- the arrow type of the letrec-bound function
;; and its parameter, supplied to type-ofo/d even though the interpreter
;; template no longer carries the annotation.
;;
;;   ./run.sh --check-follower-every 1 --main-unsound-depth 1000 \
;;     --timeout 240 experiments/duplicate-untyped-id-ty.scm

(load "restricted-interp-untyped.scm")
(load "restricted-interp-untyped-following.scm")
(load "experiments/id-harness.scm")
(load "views.scm") ; R1+R2+TY+NV view definitions

(define duplicate-tyenv '((duplicate . ((list) -> list)) (l . list)))

(define (duplicate-prog-u q body)
  `(letrec ([duplicate (lambda (l)
                         ,q)])
     ,body))

(run-id "duplicate-untyped/ty" '(11 15 19 23 27 31 35 39 43 47) 1000
  (lambda (bound)
    (run 1 (q)
      (watch-size q)
      (absento 3 q)
      (absento 4 q)
      (absento 5 q)
      (follower
        q
        (fresh/d ()
          (base-case-patho/d 'duplicate q)
          (decreasing-recursiono/d 'duplicate '(l) q)
          (type-ofo/d duplicate-tyenv q 'list)
          (non-vacuous-testso/d q)
          (evalo-u/d (duplicate-prog-u q '(duplicate '())) '())
          (evalo-u/d (duplicate-prog-u q '(duplicate (cons 5 '()))) '(5 5))
          (evalo-u/d (duplicate-prog-u q '(duplicate (cons 3 (cons 4 '())))) '(3 3 4 4))))
      (evalo-u (duplicate-prog-u q '(duplicate '())) '())
      (evalo-u (duplicate-prog-u q '(duplicate (cons 5 '()))) '(5 5))
      (evalo-u (duplicate-prog-u q '(duplicate (cons 3 (cons 4 '())))) '(3 3 4 4)))))
