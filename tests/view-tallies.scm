;; tests/view-tallies.scm --- gates for tally/d, the per-view attribution
;; combinator (following.scm).  tally/d wraps a /d view goal transparently and
;; attributes two per-label events: `refute` (the wrapped goal fails, #f) and
;; `force` (the wrapped goal commits a store change vs its entry state).  A
;; STALL commits nothing (returns the entry state unchanged), so it moves
;; neither counter.  See the tally/d block in following.scm for the exact
;; semantics and documented blind spots.
;;
;; DEPENDS on views.scm already being loaded (for base-case-patho/d); in
;; test-all.scm this file is loaded after tests/untyped-interp.scm, which loads
;; views.scm.  `run` resets *view-tally-alist* at the start of every run, so
;; each test below reads the tally produced by its own run.

;; 1. REFUTE: a tally/d-wrapped view whose /d evaluation fails on a ground bad
;;    candidate.  (rember e d) is caseless (every path applies rember), so
;;    base-case-patho/d refutes it -> refute 1, force 0.
(test "tally/d: view refuting a ground bad candidate -> (refute . force) = (1 . 0)"
  (begin
    (run 1 (q)
      (follower q (tally/d 'R1 (base-case-patho/d 'rember '(rember e d)))))
    (view-tally-ref 'R1))
  '(1 . 0))

;; 2. FORCE: a small custom /d goal that unifies the outer term, extending the
;;    substitution -> force 1, refute 0.  The run itself commits q = 5.
(test "tally/d: view forcing a binding -> (refute . force) = (0 . 1)"
  (begin
    (run 1 (q)
      (follower q (tally/d 'FORCE (==/d q 5))))
    (view-tally-ref 'FORCE))
  '(0 . 1))

;; 2b. Sanity: the forcing run actually returns the forced value.
(test "tally/d: forcing run commits the binding"
  (run 1 (q)
    (follower q (tally/d 'FORCE (==/d q 5))))
  '(5))

;; 3. STALL: a tally/d-wrapped view on a bare hole is undetermined; it commits
;;    nothing and returns the entry state -> neither counter moves.  With no
;;    entry ever created, view-tally-ref reports (0 . 0).
(test "tally/d: stalling view moves neither counter -> (0 . 0)"
  (begin
    (run 1 (q)
      (follower q (tally/d 'STALL (base-case-patho/d 'rember q))))
    (view-tally-ref 'STALL))
  '(0 . 0))
