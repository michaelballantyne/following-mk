;; member-full-id-nofollower.scm --- enumerative baseline arm: same task,
;; examples, bounds, and absento exclusions as member-full-id-views.scm,
;; NO follower. Generated mechanically from that file; see it for the
;; task documentation.
(load "experiments/id-harness.scm")
(load "views.scm") ; R1+R2+TY+NV view definitions

(define (member-prog q body)
  `(letrec ([member (lambda (e l) : ((number list) -> number)
                      ,q)])
     ,body))

(define member-tyenv '((member . ((number list) -> number)) (e . number) (l . list)))

(run-id "member-full/no-follower" '(11 15 19 23 27 31 35 39 43 47) 1000
  (lambda (bound)
    (run 1 (q)
      (watch-size q)
      (absento 5 q)
      (absento 6 q)
      (evalo (member-prog q '(member 5 '())) 0)
      (evalo (member-prog q '(member 5 (cons 5 '()))) 1)
      (evalo (member-prog q '(member 5 (cons 6 '()))) 0)
      (evalo (member-prog q '(member 5 (cons 6 (cons 5 '())))) 1))))
