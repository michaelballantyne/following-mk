;; Differential tests for residual-views.scm's r-form port of the R2, R2P,
;; TY, and NV follower views (R1 is already covered by tests/residual-
;; engine.scm's Part 2; R2T is intentionally not ported -- see residual-
;; views.scm's header). Each test below is a hand-port of one of views.scm's
;; own self-check gates (its ground-truth ACCEPT/REFUTE/STALL behavior) to
;; the residual `r`-prefixed constructors + `-res`-suffixed relations, driven
;; through follower-residual-goal + the real follower/run machinery, and
;; asserting the SAME expected answer views.scm's closure-engine gate
;; asserts. That equality is a decision-equivalence check: commit / stall /
;; refute all have to land the same way for the answer to match.
;;
;; Coverage, per view: ACCEPT/ground, REFUTE/ground, STALL/holey, STALL/bare-
;; hole (the standard 4-shape pattern used throughout this codebase), plus
;; the R2P headline test (interleave's argument-swap body, which R2 refutes
;; but R2P accepts) and the R2-vs-R2P incomparability pair ((interleave d d),
;; accepted by R2 but refuted by R2P) -- these illustrate the actual
;; soundness distinction the R2/R2P pair encodes, so getting the port wrong
;; here would be a real correctness bug, not a formatting slip.
;;
;; Loaded after residual-views.scm (which is self-contained: it doesn't
;; require views.scm).

;;; ================================================================
;;; R2: decreasing-recursiono/d-res
;;; ================================================================

;; ACCEPT (ground): canonical rember body commits position 2 (d strictly-
;; smaller-than l).  Port of views.scm's "canonical rember accepted".
(test "R: decreasing-recursiono/d-res canonical rember accepted"
  (run 1 (q)
    (follower q
      (follower-residual-goal
        (decreasing-recursiono/d-res 'rember '(e l)
          '(match l ['() l] [(cons a d) (if (= a e) d (cons a (rember e d)))])))))
  '(_.0))

;; REFUTE (ground): recurs on l itself (same, not smaller) at position 2;
;; position 1 fails too.  Port of views.scm's "(rember e l) refuted".
(test "R: decreasing-recursiono/d-res (rember e l) refuted"
  (run 1 (q)
    (follower q
      (follower-residual-goal
        (decreasing-recursiono/d-res 'rember '(e l)
          '(match l ['() l] [(cons a d) (rember e l)])))))
  '())

;; STALL (holey match): leaves the holes unbound, does not refute or over-
;; commit.  Port of views.scm's "holey match stalls, holes unbound".
(test "R: decreasing-recursiono/d-res holey match stalls, holes unbound"
  (run 1 (h1 h2)
    (follower (list h1 h2)
      (follower-residual-goal
        (decreasing-recursiono/d-res 'rember '(e l)
          `(match l ['() ,h1] [(cons a d) ,h2])))))
  '((_.0 _.1)))

;; STALL (bare hole): undetermined -> q unbound.  Port of views.scm's "bare
;; hole stalls".
(test "R: decreasing-recursiono/d-res bare hole stalls"
  (run 1 (q)
    (follower q (follower-residual-goal (decreasing-recursiono/d-res 'rember '(e l) q))))
  '(_.0))

;;; ================================================================
;;; R2P: permuted-decreasing-recursiono/d-res
;;; ================================================================

;; ACCEPT (ground): canonical rember (identity assignment, position-2
;; strict) still accepted.  Port of views.scm's "canonical rember accepted".
(test "R: permuted-decreasing-recursiono/d-res canonical rember accepted"
  (run 1 (q)
    (follower q
      (follower-residual-goal
        (permuted-decreasing-recursiono/d-res 'rember '(e l)
          '(match l ['() l] [(cons a d) (if (= a e) d (cons a (rember e d)))])))))
  '(_.0))

;; REFUTE (ground): identity self-call with NOTHING strict -- (rember e l)
;; recurs on l itself.  Port of views.scm's "(rember e l) refuted (no
;; strict)".
(test "R: permuted-decreasing-recursiono/d-res (rember e l) refuted (no strict)"
  (run 1 (q)
    (follower q
      (follower-residual-goal
        (permuted-decreasing-recursiono/d-res 'rember '(e l)
          '(match l ['() l] [(cons a d) (rember e l)])))))
  '())

;; STALL (holey match): leaves the holes unbound.  Port of views.scm's
;; "holey match stalls, holes unbound".
(test "R: permuted-decreasing-recursiono/d-res holey match stalls, holes unbound"
  (run 1 (h1 h2)
    (follower (list h1 h2)
      (follower-residual-goal
        (permuted-decreasing-recursiono/d-res 'rember '(e l)
          `(match l ['() ,h1] [(cons a d) ,h2])))))
  '((_.0 _.1)))

;; STALL (bare hole): undetermined -> q unbound.  Port of views.scm's "bare
;; hole stalls".
(test "R: permuted-decreasing-recursiono/d-res bare hole stalls"
  (run 1 (q)
    (follower q (follower-residual-goal (permuted-decreasing-recursiono/d-res 'rember '(e l) q))))
  '(_.0))

;; --- THE HEADLINE TEST: interleave's argument-SWAPPING canonical body,
;; which R2 refutes (no FIXED position decreases -- position 1 gets l2 at
;; one call and d elsewhere), is ACCEPTED by R2P via the swap assignment
;; (l2<-l2 same, d<-l1 strict).  Port of views.scm's "interleave (arg-swap)
;; ACCEPTED" -- see the R2P section of views.scm / residual-views.scm for
;; the full soundness argument (the injective summed-size measure).
(test "R: permuted-decreasing-recursiono/d-res interleave (arg-swap) ACCEPTED"
  (run 1 (q)
    (follower q
      (follower-residual-goal
        (permuted-decreasing-recursiono/d-res 'interleave '(l1 l2)
          '(match l1 ['() l2] [(cons a d) (cons a (interleave l2 d))])))))
  '(_.0))

;; --- R2-vs-R2P INCOMPARABILITY: (interleave d d) -- both args descend from
;; l1 only, so NO injective assignment to distinct params exists.  R2P
;; REFUTES it (violates injectivity); plain R2 ACCEPTS it because it
;; inspects only ONE fixed slot (slot 1, where d IS smaller) and ignores the
;; collision at slot 2.  This pair is the concrete soundness distinction R2
;; vs R2P encodes -- getting either half wrong silently would be a real
;; correctness regression, not a formatting slip.  Ports of views.scm's
;; "(interleave d d) refuted (non-injective)" [R2P] and "(interleave d d)
;; ACCEPTED by R2 (fixed-position)" [R2].
(test "R: permuted-decreasing-recursiono/d-res (interleave d d) refuted (non-injective)"
  (run 1 (q)
    (follower q
      (follower-residual-goal
        (permuted-decreasing-recursiono/d-res 'interleave '(l1 l2)
          '(match l1 ['() l2] [(cons a d) (interleave d d)])))))
  '())

(test "R: decreasing-recursiono/d-res (interleave d d) ACCEPTED by R2 (fixed-position)"
  (run 1 (q)
    (follower q
      (follower-residual-goal
        (decreasing-recursiono/d-res 'interleave '(l1 l2)
          '(match l1 ['() l2] [(cons a d) (interleave d d)])))))
  '(_.0))

;;; ================================================================
;;; TY: type-ofo/d-res
;;; ================================================================

;; ACCEPT (ground): canonical rember body type-checks at list.  Port of
;; views.scm's "canonical rember accepted".
(test "R: type-ofo/d-res canonical rember accepted"
  (run 1 (q)
    (follower q
      (follower-residual-goal
        (type-ofo/d-res rember-tyenv
          '(match l ['() l] [(cons a d) (if (= a e) d (cons a (rember e d)))])
          'list))))
  '(_.0))

;; REFUTE (ground): (rember e a) -- `a` is a number (list head) passed at
;; the list argument position.  Rung 2 (R2) accepts this; the type view
;; refutes it.  Port of views.scm's "(rember e a) at list position
;; refuted".
(test "R: type-ofo/d-res (rember e a) at list position refuted"
  (run 1 (q)
    (follower q
      (follower-residual-goal
        (type-ofo/d-res rember-tyenv
          '(match l ['() l] [(cons a d) (rember e a)])
          'list))))
  '())

;; STALL (holey match arms): cannot decide, must leave the holes unbound.
;; Port of views.scm's "holey match stalls, holes unbound".
(test "R: type-ofo/d-res holey match stalls, holes unbound"
  (run 1 (h1 h2)
    (follower (list h1 h2)
      (follower-residual-goal
        (type-ofo/d-res rember-tyenv
          `(match l ['() ,h1] [(cons a d) ,h2])
          'list))))
  '((_.0 _.1)))

;; STALL (bare hole): undetermined.  Port of views.scm's "bare hole stalls".
(test "R: type-ofo/d-res bare hole stalls"
  (run 1 (q)
    (follower q (follower-residual-goal (type-ofo/d-res rember-tyenv q 'list))))
  '(_.0))

;;; ================================================================
;;; NV: non-vacuous-testso/d-res
;;; ================================================================

;; REFUTE (ground): (if (= e e) l l) -- identical condition arguments.  Port
;; of views.scm's "(if (= e e) l l) refuted".
(test "R: non-vacuous-testso/d-res (if (= e e) l l) refuted"
  (run 1 (q)
    (follower q (follower-residual-goal (non-vacuous-testso/d-res '(if (= e e) l l)))))
  '())

;; ACCEPT (ground): canonical rember body (ground, distinct symbols a/e in
;; test position).  Port of views.scm's "canonical rember body accepted".
(test "R: non-vacuous-testso/d-res canonical rember body accepted"
  (run 1 (q)
    (follower q
      (follower-residual-goal
        (non-vacuous-testso/d-res
          '(match l ['() l] [(cons a d) (if (= a e) d (cons a (rember e d)))])))))
  '(_.0))

;; STALL (holey match arms): cannot decide, must leave the holes unbound.
;; Port of views.scm's "holey match stalls, holes unbound".
(test "R: non-vacuous-testso/d-res holey match stalls, holes unbound"
  (run 1 (h1 h2)
    (follower (list h1 h2)
      (follower-residual-goal
        (non-vacuous-testso/d-res `(match l ['() ,h1] [(cons a d) ,h2])))))
  '((_.0 _.1)))

;; STALL (bare hole): undetermined.  Port of views.scm's "bare hole stalls".
(test "R: non-vacuous-testso/d-res bare hole stalls"
  (run 1 (q)
    (follower q (follower-residual-goal (non-vacuous-testso/d-res q))))
  '(_.0))
