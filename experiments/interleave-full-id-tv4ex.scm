;; interleave-full-id-tv4ex.scm --- size-closed ID synthesis of `interleave`.
;; DELIBERATE STRESS TEST of the fixed-position restriction in R2
;; (decreasing-recursiono/d).  Mirrors experiments/rember-full-id-tv4ex.scm in
;; structure, but the follower stack is R1 + TY + NV + evalo/d ONLY -- R2 is
;; OMITTED.  See the finding below.
;;
;; Task: interleave : ((list list) -> list).  Alternate elements of l1 and l2,
;; starting with l1; when l1 is empty, append the rest of l2.
;;   interleave (a c) (b d) -> (a b c d).
;;
;; Canonical body (answer):
;;   (match l1 ['() l2] [(cons a d) (cons a (interleave l2 d))])
;; Size under the repo measure (pattern-binders a,d = 0): 35.
;; Expected answer at bound 35 (bounds 11..39 step 4; 35 is on the grid).
;;
;; *** R2 REFUTES THIS CANONICAL BODY (a finding, not a failure). ***
;; The recursive call `(interleave l2 d)` SWAPS its arguments: position 1 gets
;; l2 (parameter 2, not a descendant of l1) and position 2 gets d (a descendant
;; of l1, but supplied at the l2 position).  decreasing-recursiono/d requires a
;; SINGLE FIXED argument position that structurally decreases in EVERY self-call
;; (this fixed-position discipline is exactly what makes it sound against
;; argument-swapping recursions).  Here neither position 1 nor position 2
;; decreases, so R2 refutes -- correctly, by its own definition: interleave does
;; terminate, but by a well-founded measure (total length of both lists) that a
;; fixed-position structural check cannot see.  interleave therefore exposes the
;; documented restriction of rung 2, so R2 is dropped from this task's stack.
;; The gate `experiments/new-tasks-gates.scm` confirms R2 refutes the ground
;; canonical body.  R1/TY/NV all accept it.
;;
;; Examples (4), and the degenerates each kills:
;;   (interleave () ())        => ()          base
;;   (interleave () (6))       => (6)          nil branch returns l2
;;   (interleave (5) (6))      => (5 6)        basic alternation
;;   (interleave (5 7) (6 8))  => (5 6 7 8)    kills the "append-with-swap"
;;                                             variant (cons a (interleave d l2)),
;;                                             which yields (5 7 6 8) here.
;; Absento excludes example constants 5,6,7,8; the canonical body has no numeric
;; literals.
;;
;;   ./run.sh --check-follower-every 1 --timeout 500 experiments/interleave-full-id-tv4ex.scm
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
      (follower
        q
        (fresh/d ()
          (base-case-patho/d 'interleave q)
          ;; R2 (decreasing-recursiono/d) intentionally omitted: it refutes the
          ;; canonical answer (argument-swapping recursion; see header).
          (type-ofo/d interleave-tyenv q 'list)
          (non-vacuous-testso/d q)
          (evalo/d (interleave-prog q '(interleave '() '())) '())
          (evalo/d (interleave-prog q '(interleave '() (cons 6 '()))) '(6))
          (evalo/d (interleave-prog q '(interleave (cons 5 '()) (cons 6 '()))) '(5 6))
          (evalo/d (interleave-prog q '(interleave (cons 5 (cons 7 '())) (cons 6 (cons 8 '())))) '(5 6 7 8))))
      (evalo (interleave-prog q '(interleave '() '())) '())
      (evalo (interleave-prog q '(interleave '() (cons 6 '()))) '(6))
      (evalo (interleave-prog q '(interleave (cons 5 '()) (cons 6 '()))) '(5 6))
      (evalo (interleave-prog q '(interleave (cons 5 (cons 7 '())) (cons 6 (cons 8 '())))) '(5 6 7 8)))))
