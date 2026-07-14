;; last-full-id-views-dfs.scm --- size-closed ID synthesis of `last`, the full
;; follower stack (R1+R2+TY+NV) PLUS evalo/d over the examples, check-every 1.
;; IDDFS variant of experiments/last-full-id-views.scm: same everything, but
;; the per-level search is depth-first (dfs-search.scm's mplus) instead of fair
;; interleaving. Mirrors experiments/rember-full-id-views.scm.
;;
;; Task: last : ((list) -> number).  The last element of a (nonempty) list.
;;
;; Canonical body (answer):
;;   (match l ['() 0]
;;     [(cons a d) (match d ['() a] [(cons b dd) (last d)])])
;; Size under the repo measure (pattern-binders a,d,b,dd = 0): 50.
;; Expected answer at bound 51 (bounds 19..55 step 4; 50 first lands on the
;; grid at 51).
;;
;; DEAD NIL BRANCH: the outer `['() 0]` arm is dynamically dead on every example
;; (all example inputs are nonempty), so the `0` filler is unconstrained by the
;; I/O spec -- any type-correct number literal there would also satisfy.  This is
;; a candidate for a future coverage view: the examples never exercise it, so it
;; is pinned only by size-minimality of the literal, not by evaluation.
;;
;; Examples (3), and the degenerates each kills:
;;   (last (5))       => 5   base: single element (kills "return 0"/const)
;;   (last (5 6))     => 6   kills "return head" (a)
;;   (last (5 6 7))   => 7   kills "return second element" (forces recursion)
;; Absento excludes example constants 5,6,7; the canonical body contains no
;; numeric literal >=3 (only the dead-branch 0 and pattern vars/params).
;;
;;   ./run.sh --check-follower-every 1 --timeout 500 experiments/last-full-id-views-dfs.scm
(load "experiments/id-harness.scm")
(load "views.scm") ; R1+R2+TY+NV view definitions
(load "dfs-search.scm") ; per-level search: depth-first instead of fair interleaving

(define (last-prog q body)
  `(letrec ([last (lambda (l) : ((list) -> number)
                    ,q)])
     ,body))

(define last-tyenv '((last . ((list) -> number)) (l . list)))

(run-id "last-full/views/dfs" '(19 23 27 31 35 39 43 47 51 55) 1000
  (lambda (bound)
    (run 1 (q)
      (watch-size q)
      (absento 5 q)
      (absento 6 q)
      (absento 7 q)
      (follower
        q
        (fresh/d ()
          (base-case-patho/d 'last q)
          (decreasing-recursiono/d 'last '(l) q)
          (type-ofo/d last-tyenv q 'number)
          (non-vacuous-testso/d q)
          (evalo/d (last-prog q '(last (cons 5 '()))) 5)
          (evalo/d (last-prog q '(last (cons 5 (cons 6 '())))) 6)
          (evalo/d (last-prog q '(last (cons 5 (cons 6 (cons 7 '()))))) 7)))
      (evalo (last-prog q '(last (cons 5 '()))) 5)
      (evalo (last-prog q '(last (cons 5 (cons 6 '())))) 6)
      (evalo (last-prog q '(last (cons 5 (cons 6 (cons 7 '()))))) 7))))
