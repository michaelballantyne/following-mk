;; rember-full-id-tv-only.scm --- size-closed ID with a termination-view-only
;; follower (base-case-patho/d, no evalo/d). Generalization check of the
;; append result: the plain ID baseline died mid-bound-31 after ~1h; the
;; view refutes each level's divergent spines at commit time.
;;
;;   ./run.sh --check-follower-every 20 --timeout 850 \
;;     experiments/rember-full-id-tv-only.scm

(load "experiments/id-harness.scm")
(load "views.scm")

(define (rember-prog q body)
  `(letrec ([rember (lambda (e l) : ((number list) -> list)
                      ,q)])
     ,body))

(run-id "rember-full/tv-only" '(15 19 23 27 31 35 39 43 47 51) 1000
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
          (base-case-patho/d 'rember q)))
      (evalo (rember-prog q '(rember 5 '())) '())
      (evalo (rember-prog q '(rember 6 (cons 6 '()))) '())
      (evalo (rember-prog q '(rember 7 (cons 3 (cons 4 (cons 7 (cons 6 '())))))) '(3 4 6))
      (evalo (rember-prog q '(rember 5 (cons 3 (cons 4 (cons 6 (cons 7 '())))))) '(3 4 6 7)))))
