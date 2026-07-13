;; Residual-engine port of tests/guard-robustness.scm.  Those 8 tests pin the
;; subtlest part of the committing conde: the sole-survivor commit that carries
;; a retained guard obligation (diverging guards, multi-answer guards, guard
;; extensions leaking or not).  The closure engine's version was the regression
;; suite for exactly the path where the residual engine's exponential
;; commit-splice bug lived (finding 1 of the residual-engine review); this file
;; runs the same scenarios through follower-residual-goal + the r-forms, with
;; the SAME expected answers and counter predicates.
;;
;; Loaded after tests/residual-decisions.scm so its `decision-equiv` /
;; `decisions-of` helpers are in scope for the case-1/case-2 decision-equiv
;; variants at the bottom.

;; Guard bodies used throughout, closure and residual sides.
;;   diverge/d: sole-clause guard that recurses forever with no base case ->
;;     each recursion re-enters the conde/d and consumes a suspend-depth tick,
;;     so it is guaranteed to hard-suspend (budget-block) at the depth limit.
;;   fail/d: a guard that always fails cleanly (y = 1 and y = 2 at once).
(define (diverge/d)
  (conde/d
    ([]
     [(diverge/d)]
     [])))

(define (fail/d)
  (fresh/d (y)
    (==/d y 1)
    (==/d y 2)))

;; Residual counterparts.  rdiverge/d is recursive, so it MUST go through
;; define-relation/d (a plain define with a self-reference loops at
;; construction time).  rfail-goal is non-recursive, so a plain thunk returning
;; an rfresh/d is fine.
(define-relation/d (rdiverge/d)
  (rconde/d
    ([]
     [(rdiverge/d)]
     [])))

(define (rfail-goal)
  (rfresh/d (y)
    (r==/d y 1)
    (r==/d y 2)))

;; --- Case 1: diverging guard, sibling ruled out cleanly -> sole survivor
;; commits, carrying the budget-blocked guard leftover forward (a suspend-depth
;; cutoff fires, q = 'A is visible immediately).
(test "R-guard: diverging guard commits when sole survivor (hard-suspend carried forward)"
  (let ([result (run 1 (q)
                  (follower q
                    (follower-residual-goal
                      (rconde/d
                        ([] [(rdiverge/d)] [(r==/d q 'A)])
                        ([] [(rfail-goal)] [(r==/d q 'B)])))))])
    (list result (> *suspend-depth-cutoff-counter* 0)))
  '((A) #t))

;; --- Case 2: diverging guard + a genuinely succeeding sibling -> two live
;; candidates, so the whole conde/d stalls; q stays unbound, nothing leaks.
(test "R-guard: diverging guard + genuinely succeeding sibling stalls (no leakage)"
  (let ([result (run 1 (q)
                  (follower q
                    (follower-residual-goal
                      (rconde/d
                        ([] [(rdiverge/d)] [(r==/d q 'A)])
                        ([] [(r==/d 1 1)] [(r==/d q 'B)])))))])
    (list result (> *non-singleton-succeed-counter* 0) (> *suspend-depth-cutoff-counter* 0)))
  '((_.0) #t #t))

;; --- Case 3a: sole-clause guard that is itself internally multi-answer.  With
;; only one outer clause there is no sibling to collide with, so the outer
;; clause commits (q = 'A visible now) and the unresolved inner ambiguity is
;; carried forward as a soft residual -- soft (nondet) and hard (budget) guard
;; suspensions get the same "commit now, chew on the residual later" treatment.
(test "R-guard: sole-clause guard with internal multi-answer ambiguity still commits"
  (let ([result (run 1 (q x)
                  (follower (list q x)
                    (follower-residual-goal
                      (rfresh/d ()
                        (rconde/d
                          ([] [(rfresh/d (z)
                                 (rconde/d
                                   ([] [(r==/d z 1)] [])
                                   ([] [(r==/d z 2)] [])))]
                           [(r==/d q 'A)]))))))])
    (list result (> *non-singleton-succeed-counter* 0)))
  '(((A _.0)) #t))

;; --- Case 3b: the same ambiguous guard, now with a cleanly-succeeding sibling.
;; A real two-candidate collision -> the whole conde/d stalls; neither q nor
;; the witness x leaks.
(test "R-guard: ambiguous guard + genuinely succeeding sibling stalls (no leakage)"
  (let ([result (run 1 (q x)
                  (follower (list q x)
                    (follower-residual-goal
                      (rfresh/d ()
                        (rconde/d
                          ([] [(rfresh/d (z)
                                 (rconde/d
                                   ([] [(r==/d z 1)] [])
                                   ([] [(r==/d z 2)] [])))]
                           [(r==/d q 'A)])
                          ([] [(r==/d 1 1)] [(r==/d q 'B)]))))))])
    (list result (> *non-singleton-succeed-counter* 0)))
  '(((_.0 _.1)) #t))

;; --- Case 4: guard extends the store then contradicts itself (x = 1, x =/= 1).
;; The clause is ruled out cleanly; being the only clause, the whole conde/d
;; fails and the mid-guard extension never leaks.
(test "R-guard: guard extension undone by later guard conjunct's failure -> whole conde/d fails"
  (let ([result (run 1 (q)
                  (follower q
                    (follower-residual-goal
                      (rconde/d
                        ([] [(rfresh/d (x) (r==/d x 1) (r=/=/d x 1))] [(r==/d q 'A)])))))])
    (list result *fail-counter*))
  '(() 1))

;; --- Case 5: two guards singleton-succeed with incompatible extensions
;; (q = 'A vs q = 'B) -> stall; neither extension leaks to q or x.
(test "R-guard: two singleton-succeeding guards with different extensions stalls (no leakage)"
  (let ([result (run 1 (q x)
                  (fresh (dummy)
                    (follower (list q x)
                      (follower-residual-goal
                        (rfresh/d ()
                          (rconde/d
                            ([] [(r==/d q 'A)] [(r==/d x 1)])
                            ([] [(r==/d q 'B)] [(r==/d x 2)])))))))])
    (list result (> *non-singleton-succeed-counter* 0)))
  '(((_.0 _.1)) #t))

;; --- Case 6: unique surviving guard singleton-succeeds with its own extension
;; (y = 'guard-extended, a var the body never touches); it commits and the
;; guard's extension travels out alongside the body's (q = 'A).
(test "R-guard: unique singleton-succeeding guard's extension flows out with the commit"
  (let ([result (run 1 (q y)
                  (follower (list q y)
                    (follower-residual-goal
                      (rfresh/d ()
                        (rconde/d
                          ([] [(r==/d y 'guard-extended)] [(r==/d q 'A)])
                          ([] [(rfail-goal)] [(r==/d q 'B)]))))))])
    (list result (> *singleton-succeed-counter* 0)))
  '(((A guard-extended)) #t))

;; --- Case 7: suspend now, commit later.  Both guards depend on unbound x, so
;; the first evaluation is a cross-clause ambiguity and the follower stalls.
;; The main search grounds x = 1; on the end-of-run retrigger clause B's guard
;; (x = 2) is ruled out, leaving A the sole survivor -> commit, q = 'A appears
;; only after the retrigger.
(test "R-guard: stall now, commit later: main search grounds discriminator, retrigger commits"
  (let ([result (run 1 (q)
                  (fresh (x)
                    (follower (list q x)
                      (follower-residual-goal
                        (rfresh/d ()
                          (rconde/d
                            ([] [(r==/d x 1)] [(r==/d q 'A)])
                            ([] [(r==/d x 2)] [(r==/d q 'B)])))))
                    (== x 1)))])
    (list result (> *singleton-succeed-counter* 0) (> *non-singleton-succeed-counter* 0)))
  '((A) #t #t))

;;; ----------------------------------------------------------------
;;; Decision-equivalence variants (finding-1 witnesses): compare the
;;; per-trigger decision vector against the closure engine directly.
;;; ----------------------------------------------------------------

;; Case 1 is the exact scenario finding 1's probe caught deviating: before the
;; commit-splice fix the residual side's suspend-cutoff count blew up to 2^22.
(decision-equiv "D-guard: diverging guard commits, sole survivor (case 1)"
  (run 1 (q)
    (follower q
      (conde/d
        ([] [(diverge/d)] [(==/d q 'A)])
        ([] [(fail/d)] [(==/d q 'B)]))))
  (run 1 (q)
    (follower q
      (follower-residual-goal
        (rconde/d
          ([] [(rdiverge/d)] [(r==/d q 'A)])
          ([] [(rfail-goal)] [(r==/d q 'B)]))))))

;; Case 2: diverging guard + succeeding sibling stalls -- checks the budget
;; cutoff is counted the same when the disj stalls rather than commits.
(decision-equiv "D-guard: diverging guard + succeeding sibling stalls (case 2)"
  (run 1 (q)
    (follower q
      (conde/d
        ([] [(diverge/d)] [(==/d q 'A)])
        ([] [(==/d 1 1)] [(==/d q 'B)]))))
  (run 1 (q)
    (follower q
      (follower-residual-goal
        (rconde/d
          ([] [(rdiverge/d)] [(r==/d q 'A)])
          ([] [(r==/d 1 1)] [(r==/d q 'B)]))))))

;;; ----------------------------------------------------------------
;;; The one understood, one-sided exception to decision-vector equality:
;;; dead-alternative pruning skips re-verification of dead guards.
;;;
;;; Scenario: a 3-alt disj where alt A's guard fails only AFTER budget-blocking
;;; work (diverge, then y = 1 and y = 2), and alts B/C stall on an outer var x
;;; the main search grounds later.  On the retrigger the closure engine
;;; re-verifies A's dead guard from scratch, paying its suspend-depth cutoff a
;;; second time; the residual engine pruned A out of the stalled disj on the
;;; first pass (sound: guard failure is monotone in the growing store), so its
;;; cutoff tally is one lower.  The follower decisions (fail / singleton /
;;; suspend -- the first three components) must ALWAYS match; only the cutoff
;;; work count may differ, and only in this direction: pruning can make the
;;; residual tally LOWER, never higher.  Both vectors are hard-coded so any
;;; future shift in either engine flags loudly.  Deliberately NOT written with
;;; decision-equiv, which asserts full equality.
;;; ----------------------------------------------------------------

(test "D-guard: pruning skips dead-guard re-verification (cutoff lower by 1, decisions equal)"
  (list
   (decisions-of
    (lambda ()
      (run 1 (q)
        (fresh (x)
          (follower (list q x)
            (conde/d
              ([y] [(diverge/d) (==/d y 1) (==/d y 2)] [(==/d q 'A)])
              ([] [(==/d x 1)] [(==/d q 'B)])
              ([] [(==/d x 2)] [(==/d q 'C)])))
          (== x 1)))))
   (decisions-of
    (lambda ()
      (run 1 (q)
        (fresh (x)
          (follower (list q x)
            (follower-residual-goal
              (rconde/d
                ([y] [(rdiverge/d) (r==/d y 1) (r==/d y 2)] [(r==/d q 'A)])
                ([] [(r==/d x 1)] [(r==/d q 'B)])
                ([] [(r==/d x 2)] [(r==/d q 'C)]))))
          (== x 1))))))
  '((0 1 1 2)    ; closure : re-pays alt A's cutoff on the retrigger
    (0 1 1 1)))  ; residual: alt A pruned after its first (failing) scan
