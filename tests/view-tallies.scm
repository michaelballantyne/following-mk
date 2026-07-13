;; tests/view-tallies.scm --- gates for tally/d, the per-view attribution
;; combinator (following.scm).  tally/d wraps a /d view goal transparently and
;; attributes two per-label events: `refute` (the wrapped goal fails, #f) and
;; `force` (the wrapped goal commits a store change vs its entry state).  A
;; STALL commits nothing (returns the entry state unchanged), so it moves
;; neither counter.  See settle-tally in residual.scm for the exact semantics
;; and the view-tally bookkeeping in following.scm.
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

;; --- RESUMPTION cases: the events must be counted when they happen on a
;; RE-FIRE of a stalled view (the stashed resume thunk), not only at follower
;; installation.  Nearly all real view activity lives on resumption.

;; 4. REFUTE ON RESUMPTION: the view stalls at installation (bare hole), the
;;    main search then commits q per conde branch, and the end-of-run re-fire
;;    refutes the caseless branch.  run* explores both branches (mirroring
;;    tests/refutation.scm): (rember e d) is refuted on resume -> refute 1;
;;    the 'l branch commits with no store change -> no force.
(test "tally/d: refute on resumption -> (1 . 0)"
  (begin
    (run* (q)
      (follower q (tally/d 'RR (base-case-patho/d 'rember q)))
      (conde
        ((== q '(rember e d)))
        ((== q 'l))))
    (view-tally-ref 'RR))
  '(1 . 0))

;; A tiny forcing view for test 5: stalls while q is a hole (both shape guards
;; live), and once q commits, its body unifies `tag` -- a store extension on
;; the resumed step.
(define (tally-test-tag-of/d q tag)
  (conde/d
    ([]
     [(numbero/d q)]
     [(==/d tag 'num)])
    ([]
     [(symbolo/d q)]
     [(==/d tag 'sym)])))

;; 5. FORCE ON RESUMPTION: stall at installation, then the main search binds
;;    q = 5; the re-fire commits the numbero clause and binds tag -> force 1
;;    counted on the resumed step.  The companion test confirms the resumed
;;    commit actually flowed out (tag = num).
(test "tally/d: force on resumption -> (0 . 1)"
  (begin
    (run 1 (q tag)
      (follower (list q tag) (tally/d 'FR (tally-test-tag-of/d q tag)))
      (conde
        ((== q 5))))
    (view-tally-ref 'FR))
  '(0 . 1))

(test "tally/d: force on resumption commits the binding"
  (run 1 (q tag)
    (follower (list q tag) (tally/d 'FR (tally-test-tag-of/d q tag)))
    (conde
      ((== q 5))))
  '((5 num)))

;; 6. LABELS SURVIVE SUSPENSION/RESUMPTION: two tallied views under fresh/d
;;    both stall at installation; settle-tally re-wraps each surviving
;;    conjunct under its own label, so the residual stored in state-F still
;;    carries the labels.  On the refuting branch W1
;;    (processed first) refutes and the conjunction short-circuits, so W2 is
;;    never evaluated there; on the 'l branch both succeed without extending
;;    the store.  W1 -> (1 . 0), W2 -> (0 . 0), each under its OWN label.
(test "tally/d: labels survive worklist suspension/resumption"
  (begin
    (run* (q)
      (follower q
        (fresh/d ()
          (tally/d 'W1 (base-case-patho/d 'rember q))
          (tally/d 'W2 (non-vacuous-testso/d q))))
      (conde
        ((== q '(rember e d)))
        ((== q 'l))))
    (list (view-tally-ref 'W1) (view-tally-ref 'W2)))
  '((1 . 0) (0 . 0)))
