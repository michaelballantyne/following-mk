;; rev-acc-full-id-nofollower.scm --- enumerative baseline arm: same task,
;; examples, bounds, and absento exclusions as rev-acc-full-id-tv4ex.scm,
;; NO follower. Generated mechanically from that file; see it for the
;; task documentation.
(load "experiments/id-harness.scm")
(load "experiments/termination-view4.scm") ; loads tv3 (=> tv2 => tv1) too

(define (rev-prog q body)
  `(letrec ([rev (lambda (l acc) : ((list list) -> list)
                   ,q)])
     ,body))

(define rev-tyenv '((rev . ((list list) -> list)) (l . list) (acc . list)))

(run-id "rev-acc-full/no-follower" '(11 15 19 23 27 31 35 39) 1000
  (lambda (bound)
    (run 1 (q)
      (watch-size q)
      (absento 5 q)
      (absento 6 q)
      (absento 7 q)
      (evalo (rev-prog q '(rev '() '())) '())
      (evalo (rev-prog q '(rev (cons 5 '()) '())) '(5))
      (evalo (rev-prog q '(rev (cons 5 (cons 6 '())) '())) '(6 5))
      (evalo (rev-prog q '(rev (cons 5 (cons 6 (cons 7 '()))) '())) '(7 6 5)))))
