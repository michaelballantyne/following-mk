;; interleave-full-id-nofollower.scm --- enumerative baseline arm: same task,
;; examples, bounds, and absento exclusions as interleave-full-id-tv4ex.scm,
;; NO follower. Generated mechanically from that file; see it for the
;; task documentation.
(load "experiments/id-harness.scm")
(load "experiments/termination-view4.scm") ; loads tv3 (=> tv2 => tv1) too

(define (interleave-prog q body)
  `(letrec ([interleave (lambda (l1 l2) : ((list list) -> list)
                          ,q)])
     ,body))

(define interleave-tyenv
  '((interleave . ((list list) -> list)) (l1 . list) (l2 . list)))

(run-id "interleave-full/tv4ex(noR2)" '(11 15 19 23 27 31 35 39) 1000
  (lambda (bound)
    (run 1 (q)
      (watch-size q)
      (absento 5 q)
      (absento 6 q)
      (absento 7 q)
      (absento 8 q)
      (evalo (interleave-prog q '(interleave '() '())) '())
      (evalo (interleave-prog q '(interleave '() (cons 6 '()))) '(6))
      (evalo (interleave-prog q '(interleave (cons 5 '()) (cons 6 '()))) '(5 6))
      (evalo (interleave-prog q '(interleave (cons 5 (cons 7 '())) (cons 6 (cons 8 '())))) '(5 6 7 8)))))
