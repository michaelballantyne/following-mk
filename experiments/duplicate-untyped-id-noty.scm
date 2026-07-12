;; duplicate-untyped-id-noty.scm --- UNTYPED generator, NO type view (duplicate).
;; See rember-untyped-id-noty.scm for the experiment framing.
;;
;;   ./run.sh --check-follower-every 1 --main-unsound-depth 1000 \
;;     --timeout 240 experiments/duplicate-untyped-id-noty.scm

(load "restricted-interp-untyped.scm")
(load "restricted-interp-untyped-following.scm")
(load "experiments/id-harness.scm")
(load "experiments/termination-view4.scm") ; loads tv3 (=> tv2 => tv1) too

(define (duplicate-prog-u q body)
  `(letrec ([duplicate (lambda (l)
                         ,q)])
     ,body))

(run-id "duplicate-untyped/noty" '(11 15 19 23 27 31 35 39 43 47) 1000
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
          (non-vacuous-testso/d q)
          (evalo-u/d (duplicate-prog-u q '(duplicate '())) '())
          (evalo-u/d (duplicate-prog-u q '(duplicate (cons 5 '()))) '(5 5))
          (evalo-u/d (duplicate-prog-u q '(duplicate (cons 3 (cons 4 '())))) '(3 3 4 4))))
      (evalo-u (duplicate-prog-u q '(duplicate '())) '())
      (evalo-u (duplicate-prog-u q '(duplicate (cons 5 '()))) '(5 5))
      (evalo-u (duplicate-prog-u q '(duplicate (cons 3 (cons 4 '())))) '(3 3 4 4)))))
