;; member-untyped-id-ty.scm --- UNTYPED generator, WITH the type view (member).
;; See rember-untyped-id-ty.scm for the experiment framing.  member-tyenv is not
;; defined in views.scm, so we define it here -- the arrow type of the
;; letrec-bound function and its parameters, supplied to type-ofo/d even though
;; the interpreter template no longer carries the annotation.  Each follower
;; view goal is wrapped in tally/d ('R1 'R2 'TY 'NV 'EX) for per-view
;; refute/force attribution (following.scm); the four examples share 'EX.
;;
;;   ./run.sh --check-follower-every 1 --main-unsound-depth 1000 \
;;     --timeout 240 experiments/member-untyped-id-ty.scm

(load "restricted-interp-untyped.scm")
(load "restricted-interp-untyped-following.scm")
(load "experiments/id-harness.scm")
(load "views.scm") ; R1+R2+TY+NV view definitions

(define member-tyenv '((member . ((number list) -> number)) (e . number) (l . list)))

(define (member-prog-u q body)
  `(letrec ([member (lambda (e l)
                      ,q)])
     ,body))

(run-id "member-untyped/ty" '(11 15 19 23 27 31 35 39 43 47) 1000
  (lambda (bound)
    (run 1 (q)
      (watch-size q)
      (absento 5 q)
      (absento 6 q)
      (follower
        q
        (fresh/d ()
          (tally/d 'R1 (base-case-patho/d 'member q))
          (tally/d 'R2 (decreasing-recursiono/d 'member '(e l) q))
          (tally/d 'TY (type-ofo/d member-tyenv q 'number))
          (tally/d 'NV (non-vacuous-testso/d q))
          (tally/d 'EX (evalo-u/d (member-prog-u q '(member 5 '())) 0))
          (tally/d 'EX (evalo-u/d (member-prog-u q '(member 5 (cons 5 '()))) 1))
          (tally/d 'EX (evalo-u/d (member-prog-u q '(member 5 (cons 6 '()))) 0))
          (tally/d 'EX (evalo-u/d (member-prog-u q '(member 5 (cons 6 (cons 5 '())))) 1))))
      (evalo-u (member-prog-u q '(member 5 '())) 0)
      (evalo-u (member-prog-u q '(member 5 (cons 5 '()))) 1)
      (evalo-u (member-prog-u q '(member 5 (cons 6 '()))) 0)
      (evalo-u (member-prog-u q '(member 5 (cons 6 (cons 5 '())))) 1))))
