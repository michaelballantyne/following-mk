;; duplicate-full-fair-views.scm --- THIRD configuration: the SAME sound
;; follower (R1 base-case + R2 decreasing-recursion + TY types + NV
;; non-vacuous + evalo/d examples) as experiments/duplicate-full-id-views.scm,
;; but run under classic fair-interleaving search (`run 1`, no iterative
;; deepening / watch-size / bounds list) instead of size-closed ID. Decouples
;; "get the soundness benefit of the views" from "pay the ID
;; minimality-exhaustion tax". Examples/absento identical to
;; synthesis/duplicate-full-classic.scm.
;;
;; Sweep --check-follower-every at 1, 20, 100:
;;   ./run.sh --check-follower-every 1   --timeout 300 synthesis/duplicate-full-fair-views.scm
;;   ./run.sh --check-follower-every 20  --timeout 300 synthesis/duplicate-full-fair-views.scm
;;   ./run.sh --check-follower-every 100 --timeout 300 synthesis/duplicate-full-fair-views.scm
;;
;; *** SURPRISING, FLAGGED FINDING (2026-07-13 fair-search-under-views sweep) ***
;; At check-every 1 AND 20, this arm finds a NON-GENERALIZING OVERFIT: a
;; 2-level nested match with NO recursive call to `duplicate` anywhere,
;; hardcoding the length-0/1/2+ pattern exactly as far as the 3 examples probe
;; (lengths 0,1,2) and silently WRONG on length 3+ (verified by hand:
;; duplicate('(3 4 5)) evaluates under it to '(3 3 4 5), missing the second
;; 5 -- should be '(3 3 4 4 5 5)). Full body found at check-every 1/20:
;;   (match l ['() l]
;;     [(cons a d) (match d ['() (cons a l)]
;;                   [(cons b dd) (cons a (cons a (cons b d)))])])
;; This passes R1 (base-case-patho/d) and R2 (decreasing-recursiono/d)
;; VACUOUSLY: both views only constrain paths/calls that DO apply `duplicate`;
;; a body with zero self-calls satisfies "some clean path" and "every
;; self-call decreases" trivially, so the sound termination views provide NO
;; defense against this failure mode (finite-unrolling overfit) -- they were
;; designed against divergent/non-terminating recursion (see views.scm's R1/R2
;; headers), a DIFFERENT population. At check-every 100, this arm instead finds
;; the true canonical recursive body (see expected datum below) -- so the
;; overfit is check-follower-every-dependent, not deterministic across the
;; sweep. See also: last and member below reproduce their classic-search-alone
;; overfits at ALL THREE check-every settings (persistent, not just check-every
;; dependent); rev-acc reproduces a NEW (different) overfit at check-every
;; 1/20 and also recovers canonical at check-every 100, mirroring duplicate.
(load "views.scm") ; R1+R2+TY+NV view definitions

(define (duplicate-prog q body)
  `(letrec ([duplicate (lambda (l) : ((list) -> list)
                         ,q)])
     ,body))

(define duplicate-tyenv '((duplicate . ((list) -> list)) (l . list)))

(time-test "duplicate fair search + full views"
  (run 1 (q)
    (absento 3 q)
    (absento 4 q)
    (absento 5 q)
    (follower
      q
      (fresh/d ()
        (base-case-patho/d 'duplicate q)
        (decreasing-recursiono/d 'duplicate '(l) q)
        (type-ofo/d duplicate-tyenv q 'list)
        (non-vacuous-testso/d q)
        (evalo/d (duplicate-prog q '(duplicate '())) '())
        (evalo/d (duplicate-prog q '(duplicate (cons 5 '()))) '(5 5))
        (evalo/d (duplicate-prog q '(duplicate (cons 3 (cons 4 '())))) '(3 3 4 4))))
    (evalo (duplicate-prog q '(duplicate '())) '())
    (evalo (duplicate-prog q '(duplicate (cons 5 '()))) '(5 5))
    (evalo (duplicate-prog q '(duplicate (cons 3 (cons 4 '())))) '(3 3 4 4)))
  ;; the canonical, as found at check-every 100 (see header note: check-every
  ;; 1/20 instead find a non-generalizing overfit for this task).
  '(((match l
       ['() l]
       [(cons _.0 _.1) (cons _.0 (cons _.0 (duplicate _.1)))])
     (=/= ((_.0 _.1))
          ((_.0 cons))
          ((_.0 duplicate))
          ((_.0 l))
          ((_.1 cons))
          ((_.1 duplicate))
          ((_.1 l)))
     (sym _.0 _.1))))
