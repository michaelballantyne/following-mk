;; last-full-fair-views.scm --- THIRD configuration: the SAME sound
;; follower (R1 base-case + R2 decreasing-recursion + TY types + NV
;; non-vacuous + evalo/d examples) as experiments/last-full-id-views.scm,
;; but run under classic fair-interleaving search (`run 1`, no iterative
;; deepening / watch-size / bounds list) instead of size-closed ID. Decouples
;; "get the soundness benefit of the views" from "pay the ID
;; minimality-exhaustion tax". Examples/absento identical to
;; synthesis/last-full-classic.scm. NOTE: classic search ALONE (no follower)
;; found a non-generalizing overfit for this task (synthesis/last-full-classic.scm);
;; this arm checks whether the SAME sound views/follower stack, now under fair
;; search rather than ID, still excludes that overfit.
;;
;; Sweep --check-follower-every at 1, 20, 100:
;;   ./run.sh --check-follower-every 1   --timeout 300 synthesis/last-full-fair-views.scm
;;   ./run.sh --check-follower-every 20  --timeout 300 synthesis/last-full-fair-views.scm
;;   ./run.sh --check-follower-every 100 --timeout 300 synthesis/last-full-fair-views.scm
;;
;; *** SURPRISING, FLAGGED FINDING (2026-07-13 fair-search-under-views sweep) ***
;; At ALL THREE check-every settings (1, 20, AND 100 -- unlike duplicate/
;; rev-acc below, where check-every 100 recovers canonical), this arm
;; reproduces EXACTLY the same non-generalizing overfit classic search alone
;; found (synthesis/last-full-classic.scm): a 3-level nested match hardcoding
;; the answer for lengths 1, 2, 3 with NO call to `last` anywhere. The sound
;; R1/R2 termination views do not exclude it: both only constrain
;; paths/self-calls that DO apply `last`, and a body with zero self-calls
;; satisfies both vacuously (R1/R2 target divergent/non-terminating
;; recursion, not finite-unrolling overfits -- see views.scm's R1/R2
;; headers). The expected datum below is the CANONICAL, documenting intent;
;; the actual Computed output (see run log) is the overfit and the test
;; correctly reports FAILED at all three check-every settings -- this is
;; deliberately left unresolved rather than calibrated around, per this
;; task's instructions, since it demonstrates the "sound" follower does not
;; guarantee generalization under fair search for this task.
(load "views.scm") ; R1+R2+TY+NV view definitions

(define (last-prog q body)
  `(letrec ([last (lambda (l) : ((list) -> number)
                    ,q)])
     ,body))

(define last-tyenv '((last . ((list) -> number)) (l . list)))

(time-test "last fair search + full views"
  (run 1 (q)
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
    (evalo (last-prog q '(last (cons 5 (cons 6 (cons 7 '()))))) 7))
  '(((match l
       ['() 0]
       [(cons _.0 _.1) (match _.1 ['() _.0] [(cons _.2 _.3) (last _.1)])])
     (=/= ((_.0 _.1)) ((_.0 last)) ((_.0 match)) ((_.1 last)) ((_.1 match)) ((_.2 _.3)) ((_.2 last)) ((_.3 last)))
     (sym _.0 _.1 _.2 _.3))))
