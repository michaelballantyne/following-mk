;; rember-full-id-tv5.scm --- rung 4b added: size-closed ID with all five
;; structural/type views (base-case, decreasing-recursion, types,
;; non-vacuous-tests, occurs) PLUS evalo/d over the examples, check-every 1.
;; Compare totals against experiments/rember-full-id-tv4ex.scm's cell
;; (312,236 unify(main) / 7,899 conde(main)) to see whether the sixth
;; conjunct (occurso/d 'e q) earns its keep.
;;   ./run.sh --check-follower-every 1 --timeout 300 experiments/rember-full-id-tv5.scm
(load "experiments/id-harness.scm")
(load "experiments/negative-view-occurso.scm") ; loads tv4 (=> tv3 => tv2 => tv1) too

(define (rember-prog q body)
  `(letrec ([rember (lambda (e l) : ((number list) -> list)
                      ,q)])
     ,body))

(run-id "rember-full/tv5" '(15 19 23 27 31 35 39 43 47 51) 1000
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
          (occurso/d 'e q)
          (evalo/d (rember-prog q '(rember 5 '())) '())
          (evalo/d (rember-prog q '(rember 6 (cons 6 '()))) '())
          (evalo/d (rember-prog q '(rember 7 (cons 3 (cons 4 (cons 7 (cons 6 '())))))) '(3 4 6))
          (evalo/d (rember-prog q '(rember 5 (cons 3 (cons 4 (cons 6 (cons 7 '())))))) '(3 4 6 7))))
      (evalo (rember-prog q '(rember 5 '())) '())
      (evalo (rember-prog q '(rember 6 (cons 6 '()))) '())
      (evalo (rember-prog q '(rember 7 (cons 3 (cons 4 (cons 7 (cons 6 '())))))) '(3 4 6))
      (evalo (rember-prog q '(rember 5 (cons 3 (cons 4 (cons 6 (cons 7 '())))))) '(3 4 6 7)))))
