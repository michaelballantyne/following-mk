;; rember-untyped-id-noty.scm --- UNTYPED generator, NO type view.
;;
;; Information-attribution experiment (see the plan in
;; claude/ and experiments/ablation.md): the interpreter is the UNTYPED
;; variant (evalo-u / evalo-u/d), so no type information lives in generation
;; at all.  The follower carries R1 (base-case-patho/d) + R2
;; (decreasing-recursiono/d) + NV (non-vacuous-testso/d) + EX (evalo-u/d over
;; the examples), but NO type-ofo/d.  Program template loses the `: type`
;; annotation.  Compare against rember-untyped-id-ty.scm (adds type-ofo/d) and
;; the typed baseline rember-full-id-tv4ex.scm.
;;
;;   ./run.sh --check-follower-every 1 --main-unsound-depth 1000 \
;;     --timeout 240 experiments/rember-untyped-id-noty.scm

(load "restricted-interp-untyped.scm")
(load "restricted-interp-untyped-following.scm")
(load "experiments/id-harness.scm")
(load "experiments/termination-view4.scm") ; loads tv3 (=> tv2 => tv1) too

(define (rember-prog-u q body)
  `(letrec ([rember (lambda (e l)
                      ,q)])
     ,body))

(run-id "rember-untyped/noty" '(15 19 23 27 31 35 39 43 47 51) 1000
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
          (non-vacuous-testso/d q)
          (evalo-u/d (rember-prog-u q '(rember 5 '())) '())
          (evalo-u/d (rember-prog-u q '(rember 6 (cons 6 '()))) '())
          (evalo-u/d (rember-prog-u q '(rember 7 (cons 3 (cons 4 (cons 7 (cons 6 '())))))) '(3 4 6))
          (evalo-u/d (rember-prog-u q '(rember 5 (cons 3 (cons 4 (cons 6 (cons 7 '())))))) '(3 4 6 7))))
      (evalo-u (rember-prog-u q '(rember 5 '())) '())
      (evalo-u (rember-prog-u q '(rember 6 (cons 6 '()))) '())
      (evalo-u (rember-prog-u q '(rember 7 (cons 3 (cons 4 (cons 7 (cons 6 '())))))) '(3 4 6))
      (evalo-u (rember-prog-u q '(rember 5 (cons 3 (cons 4 (cons 6 (cons 7 '())))))) '(3 4 6 7)))))
