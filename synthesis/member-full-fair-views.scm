;; member-full-fair-views.scm --- THIRD configuration: the SAME sound
;; follower (R1 base-case + R2 decreasing-recursion + TY types + NV
;; non-vacuous + evalo/d examples) as experiments/member-full-id-views.scm,
;; but run under classic fair-interleaving search (`run 1`, no iterative
;; deepening / watch-size / bounds list) instead of size-closed ID. Decouples
;; "get the soundness benefit of the views" from "pay the ID
;; minimality-exhaustion tax". Examples/absento identical to
;; synthesis/member-full-classic.scm. NOTE: classic search ALONE (no follower)
;; found a non-generalizing overfit for this task (synthesis/member-full-classic.scm);
;; this arm checks whether the SAME sound views/follower stack, now under fair
;; search rather than ID, still excludes that overfit.
;;
;; Sweep --check-follower-every at 1, 20, 100:
;;   ./run.sh --check-follower-every 1   --timeout 300 synthesis/member-full-fair-views.scm
;;   ./run.sh --check-follower-every 20  --timeout 300 synthesis/member-full-fair-views.scm
;;   ./run.sh --check-follower-every 100 --timeout 300 synthesis/member-full-fair-views.scm
;;
;; *** SURPRISING, FLAGGED FINDING (2026-07-13 fair-search-under-views sweep) ***
;; At ALL THREE check-every settings (1, 20, AND 100), this arm reproduces
;; EXACTLY the same non-generalizing overfit classic search alone found
;; (synthesis/member-full-classic.scm): the else-branch hardcodes "nonempty
;; tail => 1" via a nested match, never re-checking equality past depth 1 or
;; calling `member` recursively. Wrong e.g. on (member 5 '(6 7)), which it
;; would return 1 for despite 5 not occurring. As with last above, R1
;; (base-case-patho/d) and R2 (decreasing-recursiono/d) pass this candidate
;; VACUOUSLY -- both only constrain paths/self-calls that DO apply `member`,
;; and a body with zero self-calls trivially satisfies both (the views target
;; divergent/non-terminating recursion, not finite-unrolling overfits -- see
;; views.scm's R1/R2 headers). The expected datum below is the CANONICAL,
;; documenting intent; the actual Computed output (see run log) is the
;; overfit and the test correctly reports FAILED at all three check-every
;; settings -- deliberately left unresolved rather than calibrated around,
;; per this task's instructions.
(load "views.scm") ; R1+R2+TY+NV view definitions

(define (member-prog q body)
  `(letrec ([member (lambda (e l) : ((number list) -> number)
                      ,q)])
     ,body))

(define member-tyenv '((member . ((number list) -> number)) (e . number) (l . list)))

(time-test "member fair search + full views"
  (run 1 (q)
    (absento 5 q)
    (absento 6 q)
    (follower
      q
      (fresh/d ()
        (base-case-patho/d 'member q)
        (decreasing-recursiono/d 'member '(e l) q)
        (type-ofo/d member-tyenv q 'number)
        (non-vacuous-testso/d q)
        (evalo/d (member-prog q '(member 5 '())) 0)
        (evalo/d (member-prog q '(member 5 (cons 5 '()))) 1)
        (evalo/d (member-prog q '(member 5 (cons 6 '()))) 0)
        (evalo/d (member-prog q '(member 5 (cons 6 (cons 5 '())))) 1)))
    (evalo (member-prog q '(member 5 '())) 0)
    (evalo (member-prog q '(member 5 (cons 5 '()))) 1)
    (evalo (member-prog q '(member 5 (cons 6 '()))) 0)
    (evalo (member-prog q '(member 5 (cons 6 (cons 5 '())))) 1))
  '(((match l
       ['() 0]
       [(cons _.0 _.1) (if (= _.0 e) 1 (member e _.1))])
     (=/= ((_.0 _.1)) ((_.0 e)) ((_.0 if)) ((_.0 member)) ((_.1 e)) ((_.1 if)) ((_.1 member)))
     (sym _.0 _.1))))
