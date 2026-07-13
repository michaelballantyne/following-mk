;; member-full-id-views-residual.scm --- size-closed ID synthesis of `member?`, the full
;; follower stack (R1 base-case + R2 decreasing-recursion + TY types + NV
;; non-vacuous) PLUS evalo/d over the examples, check-every 1.  Mirrors
;; experiments/rember-full-id-views.scm.
;;
;; Task: member? : ((number list) -> number).  Boolean-as-number: 1 if e occurs
;; in l, else 0.
;;
;; Canonical body (answer):
;;   (match l ['() 0] [(cons a d) (if (= a e) 1 (member e d))])
;; Size under the repo measure (vars/pattern-binders 0, atoms 1, pairs 1+car+cdr):
;;   43.  (Pattern vars a,d stay fresh in the synthesized term, hence 0.)
;; Expected answer at bound 43 (bounds bracket it: 11..47 step 4).
;;
;; Expressibility note (the backlog's "check expressibility" for member): the
;; 0/1 boolean encoding type-checks fine.  A number literal has type `number`
;; (type-ofo/d numbero clause), and the `if` requires both branches at the
;; result type; here the result type IS number, so `0`, `1`, and the recursive
;; `(member e d)` : number all agree.  No blocker.
;;
;; Examples (4), and the degenerates each set-member kills:
;;   (member 5 '())              => 0   kills the constant `1` and `['() 1]`
;;   (member 5 (5))              => 1   kills the constant `0`
;;   (member 5 (6))              => 0   kills "nonempty -> 1" (ignores equality)
;;   (member 5 (6 5))            => 1   kills "check head only" (no recursion)
;; Together they force a recursive equality scan.  A strictly smaller satisfying
;; program is not expected (any non-recursive body fails the depth-2 example, and
;; an explicit 2-level-nested match is larger than the canonical recursion).
;; Absento excludes only the example element constants >=3 (5,6); 0 and 1 are
;; permitted because they are answer literals.
;;
;; Residual-engine port of member-full-id-views.scm (backlog 3b).
;;   ./run.sh --check-follower-every 1 --timeout 500 experiments/member-full-id-views-residual.scm
(load "experiments/id-harness.scm")
(load "residual-views.scm") ; R1+R2+TY+NV view definitions (residual)
(load "residual-interp-following.scm")

(define (member-prog q body)
  `(letrec ([member (lambda (e l) : ((number list) -> number)
                      ,q)])
     ,body))

(define member-tyenv '((member . ((number list) -> number)) (e . number) (l . list)))

(run-id "member-full/views/residual" '(11 15 19 23 27 31 35 39 43 47) 1000
  (lambda (bound)
    (run 1 (q)
      (watch-size q)
      (absento 5 q)
      (absento 6 q)
      (follower
        q
        (follower-residual-goal
          (rfresh/d ()
            (base-case-patho/d-res 'member q)
            (decreasing-recursiono/d-res 'member '(e l) q)
            (type-ofo/d-res member-tyenv q 'number)
            (non-vacuous-testso/d-res q)
            (evalo/d-res (member-prog q '(member 5 '())) 0)
            (evalo/d-res (member-prog q '(member 5 (cons 5 '()))) 1)
            (evalo/d-res (member-prog q '(member 5 (cons 6 '()))) 0)
            (evalo/d-res (member-prog q '(member 5 (cons 6 (cons 5 '())))) 1))))
      (evalo (member-prog q '(member 5 '())) 0)
      (evalo (member-prog q '(member 5 (cons 5 '()))) 1)
      (evalo (member-prog q '(member 5 (cons 6 '()))) 0)
      (evalo (member-prog q '(member 5 (cons 6 (cons 5 '())))) 1))))
