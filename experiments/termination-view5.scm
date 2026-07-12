;; termination-view5.scm --- rung 4b: parameter relevance / occurrence.
;;
;; Motivation (see claude/2026-07-12-202500-session-close.md, "Where to pick
;; up" item 1): the task encoding declares every recursive-function parameter
;; relevant, exactly like a type annotation -- for `rember`, the symbol `e`
;; MUST occur somewhere in the committed body.  Post-4a spot check found
;; ~20-25% of the surviving stream is e-irrelevant (e never mentioned), and in
;; particular the numeral-literal variant `(rember _.2 _.1)` with `_.2`
;; constrained to `(numbero ...)` should die FREE here: a num-constrained hole
;; can never unify with the SYMBOL `e`, so both branches of the occurrence
;; check refute without any search.
;;
;;   (occurso/d x body)
;;     succeeds  iff  the symbol `x` occurs SOMEWHERE in `body`, walking raw
;;                    program-text pair structure (quote/cons/match/if/app all
;;                    included -- see below)
;;     fails     iff  `x` occurs nowhere in the committed structure of `body`
;;     stalls         while `body` is too holey to decide either way (a hole
;;                    could still commit to `x` itself, or to a pair
;;                    containing `x` somewhere inside it)
;;
;; This walks RAW pair structure rather than recursing per-construct (unlike
;; every earlier rung).  That is deliberately correct for pure textual
;; occurrence: any appearance of the symbol anywhere in the term counts,
;; regardless of whether it sits in a `quote`, a `cons`, a `match` pattern, an
;; `if` test, or an application position.  The one place a symbol could
;; "hide" from a structural walk is inside a quote literal that denotes the
;; symbol itself as DATA rather than as a variable reference -- but this
;; language's only quote form is `(quote ())`, which contains no symbols at
;; all, so there is nothing to hide.  No quote-specific clause is needed.
;;
;; --- soundness-critical / search-space caveat: shadowing ---
;;
;;  * A `match` pattern variable named the same as the classified parameter
;;    (e.g. a pattern var literally named `e`) would introduce an occurrence
;;    of the symbol that is NOT a reference to the outer parameter -- it is a
;;    fresh binding that merely happens to share a name.  A raw textual walk
;;    cannot tell these apart; it would count the shadowing occurrence as if
;;    it were a genuine use of the parameter.
;;
;;    This view does NOT add its own no-shadow guards.  It relies on the
;;    no-shadowing constraints already imposed by rungs 2 and 3
;;    (`decreasing-recursiono/d`, `type-ofo/d`), which forbid a match pattern
;;    var from being named the same as any classified name (including `e`)
;;    via `=/=/d` guards, and refute any body that shadows.  Documented here
;;    so this view is never run standalone against un-shadow-guarded bodies:
;;    IT ASSUMES THE NO-SHADOW CONSTRAINTS FROM RUNGS 2/3 ARE CO-INSTALLED.
;;
;; --- three-way behaviour, and why the num-hole case refutes ---
;;
;; Exactly the rung-1 mechanism: term-shape discrimination lives in the
;; conde/d guards.
;;   - ground, x-free body (no pairs contain x, no leaf equals x): both
;;     clauses' guards fail at the leaves -> conde/d refutes.
;;   - ground body containing x somewhere: the clause whose guard matches the
;;     leaf/pair actually containing x succeeds (possibly via one recursive
;;     path) -> succeeds.
;;   - a hole in the body: clause 1's guard `(==/d x body)` unifies the hole
;;     with x (still satisfiable); clause 2's guard `(==/d `(,a . ,d) body)`
;;     also unifies the hole against a pair pattern (also satisfiable) ->
;;     BOTH clauses live -> nondeterministic -> stall, exactly as rung 1.
;;   - a hole constrained by `(numbero/d hole)`: clause 1's guard tries to
;;     unify the symbol `x` against a number-constrained var -- this fails via
;;     the type constraint (a numbero var can never unify with a symbol).
;;     Clause 2's guard tries to unify the number-constrained var against a
;;     pair pattern `(,a . ,d)` -- this also fails via the same constraint (a
;;     numbero var can never unify with a pair).  Both clauses fail -> the
;;     whole occurso/d refutes, even though the term still has an unresolved
;;     hole.  So a body whose ONLY holes are num-constrained and is otherwise
;;     free of the literal symbol `x` REFUTES here -- exactly the numeral-
;;     literal-variant-dies-free behaviour the rung is built for.

(load "experiments/termination-view4.scm") ; loads tv3 (=> tv2 => tv1) too

;; ------------------------------------------------------------------
;; occurso/d: does the symbol x occur anywhere in body's raw pair structure?
;; ------------------------------------------------------------------
(define (occurso/d x body)
  (conde/d
    ;; this leaf IS x -- unifying a hole here commits it to x, one live way
    ;; for the occurrence to hold.
    ([]
     [(==/d x body)]
     [])
    ;; compound: body is a pair (car . cdr); x occurs in body iff it occurs
    ;; in the car OR in the cdr.
    ([a d]
     [(==/d `(,a . ,d) body)]
     [(occurs-oro/d x a d)])))

;; exists a occurrence of x in a OR in d (the two children of one pair).
(define (occurs-oro/d x a d)
  (conde/d
    ([]
     [(occurso/d x a)]
     [])
    ([]
     [(occurso/d x d)]
     [])))

;;; ------------------------------------------------------------------
;;; Validation gates.  Run when this file is loaded (./run.sh loads it).
;;; ------------------------------------------------------------------

;; REFUTE (ground, e-free): canonical shape but with distinct symbols a/d
;; standing in for what would be e -- e never occurs anywhere in the term.
(test "occurso/d: ground e-free body refuted"
  (run 1 (q)
    (follower q
      (occurso/d 'e '(match l ['() l] [(cons a d) (rember a d)]))))
  '())

;; REFUTE (num-hole-only): the only hole is constrained to be a number, and
;; the rest of the term is otherwise e-free.  A numbero-constrained var can
;; never unify with the symbol `e` (clause 1 fails) nor with a pair pattern
;; (clause 2 fails) -- so this refutes with the hole still just a
;; number-constrained var, never resolved.
(test "occurso/d: num-hole-only body refuted (numeral-literal variant dies free)"
  (run 1 (h)
    (numbero h) ; main-level constraint, shared with the follower's constraint
                ; store via h, exactly the pattern used for absento in the
                ; rember-full-id-tv4ex examples.
    (follower h
      (occurso/d 'e `(match l ['() l] [(cons a d) (rember ,h d)]))))
  '())

;; ACCEPT: canonical rember body -- e occurs twice (the `(= a e)` test and the
;; recursive call `(rember e d)`).
(test "occurso/d: canonical rember body (e occurs) accepted"
  (run 1 (q)
    (follower q
      (occurso/d 'e
        '(match l ['() l] [(cons a d) (if (= a e) d (cons a (rember e d)))]))))
  '(_.0))

;; STALL: the body's only "hole" position is the whole recursive-call
;; subterm, unconstrained -- it could commit to `e` itself, or to a pair
;; containing `e`, so this must NOT refute, and h2 must be left unbound.
(test "occurso/d: unconstrained hole stalls, h2 unbound"
  (run 1 (h2)
    (follower h2
      (occurso/d 'e `(match l ['() l] [(cons a d) ,h2]))))
  '(_.0))

;; STALL: bare hole is undetermined (could commit to x itself).
(test "occurso/d: bare hole stalls"
  (run 1 (q)
    (follower q (occurso/d 'e q)))
  '(_.0))
