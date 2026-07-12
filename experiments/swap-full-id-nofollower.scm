;; swap-full-id-nofollower.scm --- enumerative baseline arm: same task,
;; examples, bounds, and absento exclusions as swap-full-id-tv4ex.scm,
;; NO follower. Generated mechanically from that file; see it for the
;; task documentation.
(load "experiments/id-harness.scm")
(load "experiments/termination-view4.scm") ; loads tv3 (=> tv2 => tv1) too

(define (swap-prog q body)
  `(letrec ([swap (lambda (l) : ((list) -> list)
                    ,q)])
     ,body))

(define swap-tyenv '((swap . ((list) -> list)) (l . list)))

(run-id "swap-full/no-follower" '(43 47 51 55 59 63 67 71 75 79) 1000
  (lambda (bound)
    (run 1 (q)
      (watch-size q)
      (absento 5 q)
      (absento 6 q)
      (absento 7 q)
      (absento 8 q)
      (evalo (swap-prog q '(swap '())) '())
      (evalo (swap-prog q '(swap (cons 5 '()))) '(5))
      (evalo (swap-prog q '(swap (cons 5 (cons 6 '())))) '(6 5))
      (evalo (swap-prog q '(swap (cons 5 (cons 6 (cons 7 (cons 8 '())))))) '(6 5 8 7)))))
