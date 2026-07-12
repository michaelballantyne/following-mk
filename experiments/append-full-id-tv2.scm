;; append-full-id-tv2.scm --- size-closed ID with rung-1 + rung-2 termination
;; views conjoined in the follower (base-case-patho/d + decreasing-recursiono/d,
;; no evalo/d).  Append variant of rember-full-id-tv2.scm; params (l s).
;;
;;   ./run.sh --check-follower-every 20 --timeout 850 \
;;     experiments/append-full-id-tv2.scm

(load "experiments/id-harness.scm")
(load "experiments/termination-view2.scm") ; loads termination-view.scm too

(define (append-prog q body)
  `(letrec ([append (lambda (l s) : ((list list) -> list)
                      ,q)])
     ,body))

(run-id "append-full/tv2" '(11 15 19 23 27 31 35 39) 1000
  (lambda (bound)
    (run 1 (q)
      (watch-size q)
      (absento '3 q)
      (absento '4 q)
      (absento '5 q)
      (absento '6 q)
      (absento '7 q)
      (follower
        q
        (fresh/d ()
          (base-case-patho/d 'append q)
          (decreasing-recursiono/d 'append '(l s) q)))
      (evalo (append-prog q '(append '() (cons 5 (cons 6 '())))) '(5 6))
      (evalo (append-prog q '(append (cons 3 (cons 4 (cons 5 '()))) (cons 6 (cons 7 '()))))
             '(3 4 5 6 7)))))
