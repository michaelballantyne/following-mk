;; append-untyped-id-noty.scm --- UNTYPED generator, NO type view (append).
;; See rember-untyped-id-noty.scm for the experiment framing.
;;
;;   ./run.sh --check-follower-every 1 --main-unsound-depth 1000 \
;;     --timeout 240 experiments/append-untyped-id-noty.scm

(load "restricted-interp-untyped.scm")
(load "restricted-interp-untyped-following.scm")
(load "experiments/id-harness.scm")
(load "views.scm") ; R1+R2+TY+NV view definitions

(define (append-prog-u q body)
  `(letrec ([append (lambda (l s)
                      ,q)])
     ,body))

(run-id "append-untyped/noty" '(11 15 19 23 27 31 35 39) 1000
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
          (base-case-patho/d 'append q)
          (decreasing-recursiono/d 'append '(l s) q)
          (non-vacuous-testso/d q)
          (evalo-u/d (append-prog-u q '(append '() (cons 5 (cons 6 '())))) '(5 6))
          (evalo-u/d (append-prog-u q '(append (cons 3 (cons 4 (cons 5 '()))) (cons 6 (cons 7 '())))) '(3 4 5 6 7))))
      (evalo-u (append-prog-u q '(append '() (cons 5 (cons 6 '())))) '(5 6))
      (evalo-u (append-prog-u q '(append (cons 3 (cons 4 (cons 5 '()))) (cons 6 (cons 7 '())))) '(3 4 5 6 7)))))
