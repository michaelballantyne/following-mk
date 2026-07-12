;; Tests pinning the guard-evaluation invariant behind the soundness
;; argument in claude/2026-04-11-200000-design.md ("evaluate-guard
;; correctly reports 'nondet whenever there is real ambiguity") and the
;; hard-suspend commitment rule in claude/2026-04-12-fixpoint-conjunction.md
;; ("A depth-limited guard whose clause is the sole survivor still gets
;; committed"). TODO.md asks what properties a programmer must ensure of
;; conde/d guards; the documented answer is "none -- depth limits and
;; nondet handling cover diverging and multi-answer guards." These tests
;; check that documented answer against actual behavior.
;;
;; Two /d relations used throughout as guard bodies:
;;   - diverge/d: a conde/d whose sole clause's guard recursively calls
;;     itself with no base case. Each recursive call re-enters
;;     conde/d-runtime, consuming one tick of suspend-depth budget, so it
;;     is guaranteed to hard-suspend once suspend-depth exceeds
;;     *suspend-depth* (default 20). Models an unboundedly-recursive guard.
;;   - fail/d: a guard that always fails cleanly via a contradictory
;;     fresh unification (y = 1 and y = 2 in the same clause).

(define (diverge/d)
  (conde/d
    ([]
     [(diverge/d)]
     [])))

(define (fail/d)
  (fresh/d (y)
    (==/d y 1)
    (==/d y 2)))

;; --- Case 1: diverging guard, other clause is ruled out cleanly -------
;;
;; Clause A's guard diverges (hard-suspends at the depth limit); clause
;; B's guard fails outright on the entry state. A is the sole surviving
;; candidate, so per the documented rule it commits with the
;; hard-suspension carried into the worklist: the body's extension (q =
;; 'A) is visible immediately, and a suspend-depth cutoff fires.
(test "diverging guard commits when sole survivor (hard-suspend carried forward)"
  (let ([result (run 1 (q)
                  (follower q
                    (conde/d
                      ([]
                       [(diverge/d)]
                       [(==/d q 'A)])
                      ([]
                       [(fail/d)]
                       [(==/d q 'B)]))))])
    (list result (> *suspend-depth-cutoff-counter* 0)))
  '((A) #t))

;; --- Case 2: diverging guard with a genuinely ambiguous sibling -------
;;
;; Clause A's guard diverges (hard-suspends); clause B's guard genuinely,
;; cleanly succeeds. Now there are two live candidates (A via hard-
;; suspend, B via singleton success), so the whole conde/d must stall
;; rather than commit either clause. The outer-visible q must stay
;; unbound; no extension from either clause leaks.
(test "diverging guard + genuinely succeeding sibling stalls (no leakage)"
  (let ([result (run 1 (q)
                  (follower q
                    (conde/d
                      ([]
                       [(diverge/d)]
                       [(==/d q 'A)])
                      ([]
                       [(==/d 1 1)]
                       [(==/d q 'B)]))))])
    (list result (> *non-singleton-succeed-counter* 0) (> *suspend-depth-cutoff-counter* 0)))
  '((_.0) #t #t))

;; --- Case 3a: sole-clause guard that is itself internally ambiguous ---
;;
;; SURPRISE (documented here, not a library change -- flagged in the
;; session report as a finding for the advisor to judge):
;;
;; The outer conde/d has a single clause whose guard is a *genuinely
;; multi-answer* nested conde/d (two clauses, z = 1 vs z = 2, nothing in
;; the state discriminates between them -- classic 'nondet by the
;; documented classification). A naive reading of "multi-answer ->
;; 'nondet -> stall" would predict the *outer* conde/d also stalls here.
;;
;; It does not. conde/d-runtime only compares clauses by whether each
;; clause's guard-stream is #f (ruled out) or truthy (a candidate); it
;; never inspects *why* a truthy guard-stream is shaped like a
;; suspend pair. `(nondeterministic)` for the inner conde/d returns
;; `(cons st g-thunk)` -- structurally identical to an ordinary
;; soft-suspend `(c . f)`. With only one outer clause, there is no
;; second candidate to trigger cross-clause `(nondeterministic)`, so the
;; outer clause commits immediately: the body runs on the (unmodified)
;; entry state, and the unresolved inner ambiguity is carried forward as
;; a perpetually-retried soft-suspended follower goal.
;;
;; Net effect actually observed: q = 'A is committed and visible outside
;; on the very first trigger, exactly like a hard-suspended sole-survivor
;; guard (case 1) -- soft (nondet) and hard (depth-limit) guard
;; suspensions get the same "commit now, keep chewing on the residual
;; later" treatment when there is no sibling to compare against. This
;; generalizes the fixpoint-conjunction.md hard-suspend commitment rule
;; to nondet-suspended guards too, which is not spelled out in the design
;; notes as written. Whether this is sound in general (it appears to be,
;; here, because the ambiguous sub-conde/d's own clause bodies are empty
;; and never execute while ambiguous -- nothing about *which* branch wins
;; is ever exposed) is a judgment call left to the advisor.
(test "SURPRISE: sole-clause guard with internal multi-answer ambiguity still commits"
  (let ([result (run 1 (q x)
                  (follower (list q x)
                    (fresh/d ()
                      (conde/d
                        ([]
                         [(fresh/d (z)
                            (conde/d
                              ([] [(==/d z 1)] [])
                              ([] [(==/d z 2)] [])))]
                         [(==/d q 'A)])))))])
    (list result (> *non-singleton-succeed-counter* 0)))
  '(((A _.0)) #t))

;; --- Case 3b: the same ambiguous guard, but now genuinely cross-clause -
;;
;; Same internally-ambiguous nested conde/d as clause A's guard, but now
;; paired with a sibling clause B whose guard cleanly, definitely
;; succeeds. This is a real two-candidate collision (not the sole-clause
;; situation of 3a), so cross-clause `(nondeterministic)` fires as
;; documented: the whole conde/d stalls, and neither q nor the witness x
;; leaks.
(test "ambiguous guard + genuinely succeeding sibling stalls (no leakage)"
  (let ([result (run 1 (q x)
                  (follower (list q x)
                    (fresh/d ()
                      (conde/d
                        ([]
                         [(fresh/d (z)
                            (conde/d
                              ([] [(==/d z 1)] [])
                              ([] [(==/d z 2)] [])))]
                         [(==/d q 'A)])
                        ([]
                         [(==/d 1 1)]
                         [(==/d q 'B)])))))])
    (list result (> *non-singleton-succeed-counter* 0)))
  '(((_.0 _.1)) #t))

;; --- Case 4: guard extends the store, then a later guard conjunct fails
;;
;; guard = (==/d x 1) (=/=/d x 1): x gets bound to 1, then immediately
;; contradicted. The clause is ruled out cleanly (empty guard stream); it
;; is the only clause, so the whole conde/d fails. The x = 1 extension
;; made mid-guard must not leak -- and since the whole conde/d (and
;; hence the follower, and hence the run) fails, there is nothing left
;; to leak into.
(test "guard extension undone by later guard conjunct's failure -> whole conde/d fails"
  (let ([result (run 1 (q)
                  (follower q
                    (conde/d
                      ([]
                       [(fresh/d (x) (==/d x 1) (=/=/d x 1))]
                       [(==/d q 'A)]))))])
    (list result *fail-counter*))
  '(() 1))

;; --- Case 5: two clauses' guards both singleton-succeed, different exts
;;
;; Clause A's guard binds q = 'A; clause B's guard binds q = 'B (on the
;; same, independent entry state -- see design.md's "guards may extend
;; the store" section). Both are genuine singleton candidates with
;; incompatible extensions, so this must stall; neither extension may
;; leak to either q or the witness x.
(test "two singleton-succeeding guards with different extensions stalls (no leakage)"
  (let ([result (run 1 (q x)
                  (fresh (dummy)
                    (follower (list q x)
                      (fresh/d ()
                        (conde/d
                          ([]
                           [(==/d q 'A)]
                           [(==/d x 1)])
                          ([]
                           [(==/d q 'B)]
                           [(==/d x 2)]))))))])
    (list result (> *non-singleton-succeed-counter* 0)))
  '(((_.0 _.1)) #t))

;; --- Case 6: unique surviving guard singleton-succeeds with extensions
;;
;; Positive control for the extension-commitment design point in
;; design.md: clause A's guard binds y = 'guard-extended (a variable the
;; body never touches); clause B's guard fails cleanly (fail/d). A is
;; the sole survivor with no ambiguity at all, so it commits normally,
;; and the guard's own extension (y) travels out to the outer store
;; alongside the body's extension (q).
(test "unique singleton-succeeding guard's extension flows out with the commit"
  (let ([result (run 1 (q y)
                  (follower (list q y)
                    (fresh/d ()
                      (conde/d
                        ([]
                         [(==/d y 'guard-extended)]
                         [(==/d q 'A)])
                        ([]
                         [(fail/d)]
                         [(==/d q 'B)])))))])
    (list result (> *singleton-succeed-counter* 0)))
  '(((A guard-extended)) #t))

;; --- Case 7: suspended, then resolved by the main search's own progress
;;
;; Both clauses' guards depend on x, which is unbound when the follower
;; first installs -- both guards singleton-succeed independently (x = 1
;; vs x = 2), so the first evaluation is a genuine cross-clause
;; ambiguity and the follower stalls. The main search then grounds x via
;; a plain (== x 1) conjunct (no intervening conde entry -- the
;; retrigger comes from run's end-of-run `(trigger-followers)` call, per
;; design.md's "at end of run" trigger point). On that retrigger, clause
;; B's guard now conflicts with x = 1 and is ruled out, leaving A as the
;; sole survivor: it commits, and q = 'A appears only after the
;; retrigger.
(test "stall now, commit later: main search grounds discriminator, retrigger commits"
  (let ([result (run 1 (q)
                  (fresh (x)
                    (follower (list q x)
                      (fresh/d ()
                        (conde/d
                          ([]
                           [(==/d x 1)]
                           [(==/d q 'A)])
                          ([]
                           [(==/d x 2)]
                           [(==/d q 'B)]))))
                    (== x 1)))])
    (list result (> *singleton-succeed-counter* 0) (> *non-singleton-succeed-counter* 0)))
  '((A) #t #t))
