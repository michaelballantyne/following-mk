;; rember-full-id-tv4.scm --- size-closed ID with FOUR termination/type/
;; canonicity views conjoined in the follower: rung 1 (base-case-patho/d),
;; rung 2 (decreasing-recursiono/d), rung 3 (type-ofo/d), and rung 4a
;; (non-vacuous-testso/d).  No evalo/d in the follower.  Extends
;; experiments/rember-full-id-tv3.scm: rung 4a additionally refutes
;; `(if (= X X) then else)` candidates with syntactically identical `=`
;; arguments -- a canonicity restriction, not a semantic one (see
;; claude/2026-07-12-201800-duplicate-task-and-postviews-spotcheck.md).
;;
;;   ./run.sh --check-follower-every 1 --timeout 600 \
;;     experiments/rember-full-id-tv4.scm

(load "experiments/id-harness.scm")
(load "views.scm") ; loads tv3 (=> tv2 => tv1) too

(define (rember-prog q body)
  `(letrec ([rember (lambda (e l) : ((number list) -> list)
                      ,q)])
     ,body))

(run-id "rember-full/tv4" '(15 19 23 27 31 35 39 43 47 51) 1000
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
          (non-vacuous-testso/d q)))
      (evalo (rember-prog q '(rember 5 '())) '())
      (evalo (rember-prog q '(rember 6 (cons 6 '()))) '())
      (evalo (rember-prog q '(rember 7 (cons 3 (cons 4 (cons 7 (cons 6 '())))))) '(3 4 6))
      (evalo (rember-prog q '(rember 5 (cons 3 (cons 4 (cons 6 (cons 7 '())))))) '(3 4 6 7)))))
