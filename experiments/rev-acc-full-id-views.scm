;; rev-acc-full-id-views.scm --- size-closed ID synthesis of accumulator-reverse,
;; the full follower stack (R1+R2+TY+NV) PLUS evalo/d over the examples,
;; check-every 1.  Mirrors experiments/rember-full-id-views.scm.
;;
;; Task: rev : ((list list) -> list).  Reverse `l` onto accumulator `acc`.
;;   The examples always call it with acc = '(), so (rev l '()) = reverse(l).
;; Interesting because the SECOND parameter is a pure accumulator: it is never a
;; structurally-decreasing recursion argument, so R2 must commit position 1.
;;
;; Canonical body (answer):
;;   (match l ['() acc] [(cons a d) (rev d (cons a acc))])
;; Size under the repo measure (pattern-binders a,d = 0): 35.
;; Expected answer at bound 35 (bounds 11..39 step 4; 35 is on the grid).
;;
;; Examples (4), and the degenerates each kills:
;;   (rev () ())        => ()       base: returns acc
;;   (rev (5) ())       => (5)      kills "return acc always" (=> ())
;;   (rev (5 6) ())     => (6 5)    kills identity and "(cons a acc)" one-step
;;   (rev (5 6 7) ())   => (7 6 5)  forces full accumulator recursion
;; The accumulator's role (build result in reverse) is pinned by the 2- and
;; 3-element cases. Absento excludes example constants 5,6,7; the canonical body
;; has no numeric literals.  A strictly smaller satisfying program is not
;; expected -- the answer is already near-minimal for a two-argument recursion.
;;
;;   ./run.sh --check-follower-every 1 --timeout 500 experiments/rev-acc-full-id-views.scm
(load "experiments/id-harness.scm")
(load "views.scm") ; R1+R2+TY+NV view definitions

(define (rev-prog q body)
  `(letrec ([rev (lambda (l acc) : ((list list) -> list)
                   ,q)])
     ,body))

(define rev-tyenv '((rev . ((list list) -> list)) (l . list) (acc . list)))

(run-id "rev-acc-full/views" '(11 15 19 23 27 31 35 39) 1000
  (lambda (bound)
    (run 1 (q)
      (watch-size q)
      (absento 5 q)
      (absento 6 q)
      (absento 7 q)
      (follower
        q
        (fresh/d ()
          (base-case-patho/d 'rev q)
          (decreasing-recursiono/d 'rev '(l acc) q)
          (type-ofo/d rev-tyenv q 'list)
          (non-vacuous-testso/d q)
          (evalo/d (rev-prog q '(rev '() '())) '())
          (evalo/d (rev-prog q '(rev (cons 5 '()) '())) '(5))
          (evalo/d (rev-prog q '(rev (cons 5 (cons 6 '())) '())) '(6 5))
          (evalo/d (rev-prog q '(rev (cons 5 (cons 6 (cons 7 '()))) '())) '(7 6 5))))
      (evalo (rev-prog q '(rev '() '())) '())
      (evalo (rev-prog q '(rev (cons 5 '()) '())) '(5))
      (evalo (rev-prog q '(rev (cons 5 (cons 6 '())) '())) '(6 5))
      (evalo (rev-prog q '(rev (cons 5 (cons 6 (cons 7 '()))) '())) '(7 6 5)))))
