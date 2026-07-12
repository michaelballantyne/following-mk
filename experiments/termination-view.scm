;; termination-view.scm --- a syntactic "termination view" /d constraint.
;;
;; Motivation (see claude/2026-07-12-174500-size-bounded-id-verdict.md):
;; in whole-body-hole synthesis, most low-size candidates are "caseless" --
;; every control path through the committed body contains an application of
;; the enclosing recursive function `fname`.  In a strict, effect-free
;; language such a body diverges on ALL inputs (evaluating it requires
;; completing a self-call, an infinite regress), so it satisfies no
;; example -- but an example-driven evaluator (leader OR the evalo/d
;; follower) can never refute it finitely; it dies only to unsound depth
;; cutoffs.  A SYNTACTIC analysis refutes it instantly: require that SOME
;; control path through the body contains no application of `fname`.
;;
;; `(base-case-patho/d fname body)` is that analysis, written in /d code so
;; it runs inside a follower: it stalls on holes and refutes the moment the
;; committed structure seals every path with an fname-application.
;;
;;   succeeds  iff  some control path through `body` avoids applying `fname`
;;   fails     iff  every control path through `body` applies `fname`
;;   stalls         while the term is too holey to decide either way
;;
;; The three-way behaviour falls out of conde/d for free: term-shape
;; discrimination lives in the conde/d guards, so an unbound `body` makes
;; several guards succeed at once -> nondeterministic -> stall (never
;; branch); a fully-committed shape leaves exactly one guard live.
;;
;; --- deliberate search-space restrictions (all documented, like the
;;     existing absento restrictions in the interpreter) ---
;;
;;  * No-shadowing: a `match` pattern variable named `fname` would shadow
;;    the recursive binding and break the purely-syntactic self-call test.
;;    We forbid it with (=/=/d x fname)/(=/=/d y fname) guards on the
;;    pattern vars; a body that shadows `fname` is refuted.
;;
;;  * Non-fname applications are treated as clean-if-args-clean without
;;    recursing into the operator: `(g a ...)` with g =/= fname contributes
;;    no fname-application on its path.  In these benchmarks the only
;;    binding in scope IS fname, so a g =/= fname operator can only be a
;;    non-function variable (which evalo refutes anyway); the approximation
;;    is sound for the "avoids fname" property and never wrongly refutes.
;;
;;  * `letrec` inside the body has no clause: a committed-letrec body is
;;    refuted.  The target answers (rember, append) contain no nested
;;    letrec, so this never discards a real solution here.  Add a clause
;;    recursing into the letrec-body if a task needs it.

(define termination-view-app-keywords '(quote cons letrec match if))

;; Exists a clean path through `ea` OR through `eb`.  Encoded as a conde/d
;; whose two clauses' GUARDS are the recursive checks:
;;   both guards fail       -> no clause    -> conde/d fails    (REFUTE)
;;   exactly one guard live -> commit it    -> succeed
;;   both guards live       -> nondet       -> stall  (sound; existence holds
;;                                             but we don't need to confirm)
(define (patho-oro/d fname ea eb)
  (conde/d
    ([]
     [(base-case-patho/d fname ea)]
     [])
    ([]
     [(base-case-patho/d fname eb)]
     [])))

;; AND over an argument list: every rand must itself have a clean path
;; (the rands are all evaluated on the one path, so AND is correct).
(define (rands-patho/d fname rands)
  (conde/d
    ([]
     [(==/d '() rands)]
     [])
    ([a d]
     [(==/d `(,a . ,d) rands)]
     [(base-case-patho/d fname a) (rands-patho/d fname d)])))

(define (base-case-patho/d fname body)
  (conde/d
    ;; number literal -- path-clean
    ([]
     [(numbero/d body)]
     [])
    ;; variable reference (a bare mention of fname is fine -- it's not a call)
    ([]
     [(symbolo/d body)]
     [])
    ;; '() literal
    ([]
     [(==/d '(quote ()) body)]
     [])
    ;; (cons e1 e2): both children on the same path -> AND
    ([e1 e2]
     [(==/d `(cons ,e1 ,e2) body)]
     [(base-case-patho/d fname e1) (base-case-patho/d fname e2)])
    ;; (if (= e1 e2) e3 e4): condition on every path (AND), branches are
    ;; alternatives (OR).  A whole-if path = evaluate e1, e2, then one branch,
    ;; so we need a clean path through e1 AND through e2 AND through (e3 | e4).
    ([e1 e2 e3 e4]
     [(==/d `(if (= ,e1 ,e2) ,e3 ,e4) body)]
     [(base-case-patho/d fname e1)
      (base-case-patho/d fname e2)
      (patho-oro/d fname e3 e4)])
    ;; (match e ['() e1] [(cons x y) e2]): scrutinee on every path (AND),
    ;; branches are alternatives (OR).  Impose no-shadowing on x, y.
    ([e e1 x y e2]
     [(==/d `(match ,e ['() ,e1] [(cons ,x ,y) ,e2]) body)
      (symbolo/d x)
      (symbolo/d y)
      (=/=/d x fname)
      (=/=/d y fname)]
     [(base-case-patho/d fname e) (patho-oro/d fname e1 e2)])
    ;; application (rator rand ...): rator a non-keyword symbol =/= fname.
    ;; rator = fname => this clause's guard fails => (with no other clause
    ;; live) the whole conde/d fails => this path is NOT clean.
    ([rator rands]
     [(==/d `(,rator . ,rands) body)
      (symbolo/d rator)
      (=/=/d rator fname)
      (absento/d rator termination-view-app-keywords)]
     [(rands-patho/d fname rands)])))

;;; ------------------------------------------------------------------
;;; Semantics checks.  Run when this file is loaded (./run.sh loads it).
;;; ------------------------------------------------------------------

;; 1. Ground caseless bodies: every path applies rember -> REFUTED.
(test "base-case-patho/d: ground (rember e d) is refuted"
  (run 1 (q)
    (follower q (base-case-patho/d 'rember '(rember e d))))
  '())

(test "base-case-patho/d: ground (cons a (rember e d)) is refuted"
  (run 1 (q)
    (follower q (base-case-patho/d 'rember '(cons a (rember e d)))))
  '())

;; 2. Ground body WITH a base case (the '() arm returns l) -> SUCCEEDS.
(test "base-case-patho/d: ground match with base case succeeds"
  (run 1 (q)
    (follower q
      (base-case-patho/d 'rember
        '(match l ['() l] [(cons a d) (rember e d)]))))
  '(_.0))

;; 3. Holey body with a self-call on the ONLY path -> REFUTED despite holes.
(test "base-case-patho/d: (cons h1 (rember e h2)) refuted despite holes"
  (run 1 (h1 h2)
    (follower (list h1 h2)
      (base-case-patho/d 'rember `(cons ,h1 (rember e ,h2)))))
  '())

;; 4. Holey match: h1 could be clean -> STALLS (does not refute), and must
;;    NOT over-commit -- the follower leaves h1, h2 unbound.
(test "base-case-patho/d: holey match stalls, leaves holes unbound"
  (run 1 (h1 h2)
    (follower (list h1 h2)
      (base-case-patho/d 'rember `(match l ['() ,h1] [(cons a d) ,h2]))))
  '((_.0 _.1)))

;; 5. Bare hole -> STALLS (undetermined), yielding success with q unbound.
(test "base-case-patho/d: bare hole stalls"
  (run 1 (q)
    (follower q (base-case-patho/d 'rember q)))
  '(_.0))
