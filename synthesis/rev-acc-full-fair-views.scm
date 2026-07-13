;; rev-acc-full-fair-views.scm --- THIRD configuration: the SAME sound
;; follower (R1 base-case + R2 decreasing-recursion + TY types + NV
;; non-vacuous + evalo/d examples) as experiments/rev-acc-full-id-views.scm,
;; but run under classic fair-interleaving search (`run 1`, no iterative
;; deepening / watch-size / bounds list) instead of size-closed ID. Decouples
;; "get the soundness benefit of the views" from "pay the ID
;; minimality-exhaustion tax". Examples/absento identical to
;; synthesis/rev-acc-full-classic.scm. NOTE: classic search ALONE (no follower)
;; found a non-generalizing overfit for this task (synthesis/rev-acc-full-classic.scm);
;; this arm checks whether the SAME sound views/follower stack, now under fair
;; search rather than ID, still excludes that overfit. Uses `rev` as the fname
;; (matching the letrec binding, not `rev-acc`) -- see rev-acc-full-id-views.scm.
;;
;; Sweep --check-follower-every at 1, 20, 100:
;;   ./run.sh --check-follower-every 1   --timeout 300 synthesis/rev-acc-full-fair-views.scm
;;   ./run.sh --check-follower-every 20  --timeout 300 synthesis/rev-acc-full-fair-views.scm
;;   ./run.sh --check-follower-every 100 --timeout 300 synthesis/rev-acc-full-fair-views.scm
;;
;; *** SURPRISING, FLAGGED FINDING (2026-07-13 fair-search-under-views sweep) ***
;; At check-every 1 AND 20, this arm finds a NON-GENERALIZING OVERFIT (a
;; DIFFERENT one than classic-search-alone's, but the same failure category):
;; a body with THREE nested matches all scrutinizing _.3, computing three
;; independently-hardcoded projections, with NO recursive call to `rev`
;; anywhere. Correct on all 4 given examples (lengths 0..3) but WRONG at
;; length 4+ (verified by hand: (rev '(5 6 7 8) '()) evaluates under it to
;; '(7 6 5 8), not the correct '(8 7 6 5)). As with duplicate below, R1
;; (base-case-patho/d) and R2 (decreasing-recursiono/d) pass this candidate
;; VACUOUSLY -- both only constrain paths/calls that DO apply `rev`, so a
;; body with zero self-calls trivially satisfies both; the termination views
;; provide no defense against this finite-unrolling overfit class (they target
;; divergent/non-terminating recursion, a different population -- see views.scm
;; R1/R2 headers). At check-every 100, this arm instead finds the true
;; canonical recursive body (see expected datum below), matching duplicate's
;; pattern (overfit at 1/20, canonical at 100) rather than last/member's
;; (identical overfit at all three settings).
(load "views.scm") ; R1+R2+TY+NV view definitions

(define (rev-prog q body)
  `(letrec ([rev (lambda (l acc) : ((list list) -> list)
                   ,q)])
     ,body))

(define rev-tyenv '((rev . ((list list) -> list)) (l . list) (acc . list)))

(time-test "rev-acc fair search + full views"
  (run 1 (q)
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
    (evalo (rev-prog q '(rev (cons 5 (cons 6 (cons 7 '()))) '())) '(7 6 5)))
  ;; the canonical, as found at check-every 100 (see header note: check-every
  ;; 1/20 instead find a non-generalizing overfit for this task).
  '(((match l
       ['() acc]
       [(cons _.0 _.1) (rev _.1 (cons _.0 acc))])
     (=/= ((_.0 _.1)) ((_.0 acc)) ((_.0 cons)) ((_.0 l)) ((_.0 rev)) ((_.1 acc)) ((_.1 cons)) ((_.1 l)) ((_.1 rev)))
     (sym _.0 _.1))))
