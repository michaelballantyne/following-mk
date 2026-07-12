;; last-full-id-nofollower.scm --- enumerative baseline arm: same task,
;; examples, bounds, and absento exclusions as last-full-id-tv4ex.scm,
;; NO follower. Generated mechanically from that file; see it for the
;; task documentation.
(load "experiments/id-harness.scm")
(load "experiments/termination-view4.scm") ; loads tv3 (=> tv2 => tv1) too

(define (last-prog q body)
  `(letrec ([last (lambda (l) : ((list) -> number)
                    ,q)])
     ,body))

(define last-tyenv '((last . ((list) -> number)) (l . list)))

(run-id "last-full/no-follower" '(19 23 27 31 35 39 43 47 51 55) 1000
  (lambda (bound)
    (run 1 (q)
      (watch-size q)
      (absento 5 q)
      (absento 6 q)
      (absento 7 q)
      (evalo (last-prog q '(last (cons 5 '()))) 5)
      (evalo (last-prog q '(last (cons 5 (cons 6 '())))) 6)
      (evalo (last-prog q '(last (cons 5 (cons 6 (cons 7 '()))))) 7))))
