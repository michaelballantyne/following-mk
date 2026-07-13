;; views.scm --- the follower "view" vocabulary: four /d constraints composed
;; into a follower alongside evalo/d during size-closed synthesis (see
;; experiments/id-harness.scm and the *-full-id-views.scm arms).  This file
;; consolidates what were four chain-loaded files (the "termination ladder");
;; load it once to get all four view relations.
;;
;; View vocabulary (the R1/R2/TY/NV/EX shorthand used in experiments/ablation.md
;; and the claude/ notes; each line: shorthand -> relation -> what it refutes):
;;
;;   R1  base-case-patho/d        refutes bodies with NO self-call-free control
;;                                path (caseless spines that diverge on every
;;                                input)
;;   R2  decreasing-recursiono/d  refutes self-calls with no single fixed
;;                                structurally-decreasing argument position
;;                                (non-terminating recursion)
;;   R2P permuted-decreasing-     INCOMPARABLE companion to R2 (not a superset):
;;       recursiono/d             refutes self-calls that admit no INJECTIVE
;;                                assignment of args to distinct params with
;;                                each arg <= its param and one strict.  Accepts
;;                                argument-permuting recursions R2 refutes
;;                                (interleave) but refutes growing-accumulator
;;                                recursions R2 accepts (rev-acc).  Per-site
;;                                assignment.  See its section for soundness.
;;   R2T terminating-recursiono/d  *** NON-VIABLE (recorded negative) ***: the
;;                                intended production view, whole-body disjunction
;;                                R2 OR R2P.  Its ACCEPT/REFUTE decisions are
;;                                correct (gates pass), but as a FOLLOWER it
;;                                DIVERGES: concluding-oro/d re-runs both walks
;;                                from scratch each re-fire, discarding each
;;                                disjunct's parked suspend-depth frontier, so a
;;                                candidate needing >1 suspend-window in the
;;                                survivor disjunct is never refuted and evalo/d
;;                                explodes on it (tiny unify-main, huge
;;                                unify-follower on duplicate/interleave).  Kept
;;                                as the documented reproduction; DO NOT use in a
;;                                production stack -- use per-task R2 or R2P.  See
;;                                claude/2026-07-13-040000-r2p-r2t-
;;                                termination-generalization.md.
;;                                Semantics as designed below: whole-body
;;                                disjunction, each
;;                                interleave (via R2P).  Refutes only when BOTH
;;                                refute.
;;   TY  type-ofo/d               refutes bodies ill-typed under the task's
;;                                declared types
;;   NV  non-vacuous-testso/d     refutes (if (= X X) ...) with syntactically
;;                                identical condition arguments (a CANONICITY
;;                                restriction, not a semantic one)
;;   EX  evalo/d over the task's  NOT defined here -- the in-follower copy of the
;;       I/O examples             task's examples, added per-arm; refutes a
;;                                candidate whose committed structure already
;;                                contradicts an example
;;
;; R1+R2 are structural termination checks; TY is a type check; NV is canonicity.
;; Two further RECORDED-NEGATIVE views (occurrence, branch-vacuity) live in
;; experiments/negative-view-*.scm; see the claude/ rung-4b/4c entries.
;;
;; Load order below is significant: R2 uses R1's `view-app-keywords`, TY uses
;; R2's `fail/d-goal`/`no-shadow/d`, NV uses TY.  The inline (test ...) forms are
;; the view self-checks; they run at load time and count in the suite.

;; === R1: base-case-patho/d --- a syntactic "termination view" /d constraint.
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

(define view-app-keywords '(quote cons letrec match if))

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
      (absento/d rator view-app-keywords)]
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

;; === R2: decreasing-recursiono/d --- rung 2 of the termination ladder:
;; structurally-decreasing recursion, as a /d constraint that runs inside a
;; follower.
;;
;; Rung 1 (`base-case-patho/d`, R1 above) refutes
;; bodies with NO self-call-free path -- caseless spines that diverge on every
;; input.  The remaining divergent population is bodies that DO have a base
;; case but still loop: recursive calls on non-decreasing arguments, e.g.
;;   (match l ['() l] [(cons a d) (rember e l)])
;; which recurs on `l` itself and diverges on any nonempty input.  Examples
;; never refute these finitely; they die only to unsound depth cutoffs.  Rung 2
;; refutes them syntactically.
;;
;;   (decreasing-recursiono/d fname params body)
;;     succeeds  iff  there is a FIXED argument position i such that EVERY
;;                    application of `fname` in `body` passes, at position i, a
;;                    bare variable that is a strict structural descendant of
;;                    the corresponding parameter p_i
;;     fails     iff  no fixed position can work (all positions refuted)
;;     stalls         while the term is too holey to decide either way
;;
;; --- soundness-critical design ---
;;
;;  * FIXED position, not any-position.  "Some argument smaller in each call"
;;    is unsound: argument-swapping recursions decrease at position 1 in one
;;    call and position 2 in another yet never globally descend.  We encode a
;;    fixed position with an OUTER conde/d, one clause per parameter position i;
;;    clause i's GUARD is the whole "all self-calls decreasing at position i"
;;    walk.  Multiple positions live -> stall; all refuted -> refute; exactly
;;    one live -> commit.  (For 2-param functions that is a 2-clause conde/d.)
;;
;;  * Strict-descent tracking.  The walk carries two Scheme-level sets of
;;    mk-terms, classified relative to p_i: `sames` (always just {p_i} here --
;;    no rebinding form in the language rebinds to a same-size value) and
;;    `smallers` (strict descendants).  At (match e ['() e1] [(cons x y) e2]):
;;    if the scrutinee e is a bare variable in sames U smallers, then within e2
;;    the pattern vars x and y join `smallers`; otherwise (e an expression, an
;;    unclassified var, or a hole once resolved to a non-classified var) x and y
;;    get NO classification.  A self-call (fname a1 ... an) is decreasing at
;;    position i iff a_i is a bare variable in `smallers`.
;;
;;  * Holes stall.  Shape discrimination lives in conde/d guards (the rung-1
;;    technique): a hole where a term of unknown shape sits makes several
;;    sibling clauses live at once -> nondeterministic -> stall, never branch,
;;    never commit a hole.
;;
;;  * for-ALL, not exists.  Unlike rung 1's exists-clean-path, decreasingness is
;;    a universal over self-calls, so it distributes as plain CONJUNCTION over
;;    subterms of if/match branches -- no path-OR.
;;
;; --- deliberate search-space restrictions (documented, like rung 1) ---
;;
;;  * No-shadowing of `fname` AND of every currently-classified variable name by
;;    a match pattern var (=/=/d guards).  Shadowing a classified name by a
;;    fresh pattern var would corrupt the by-name descent test.  A body that
;;    shadows is refuted.  (Rung 1 already forbids shadowing fname.)
;;
;;  * Non-fname applications: recurse into the operands (self-calls can hide
;;    there) but not the operator, exactly as rung 1.
;;
;;  * Types are NOT modelled.  (rember e a) with `a` the (numeric) list head is
;;    ACCEPTED here -- `a` is a strict subterm of `l`, hence "smaller" in the
;;    purely structural sense.  Such a body diverges-or-fails by evaluation and
;;    is left for examples/evalo to refute.  Rung 2 is a structural check only.


;; A /d goal that always fails, for the "wrong shape" clause bodies.  Uses
;; =/=/d (no ==/d counter perturbation): a symbol cannot be disequal to itself.
(define fail/d-goal (=/=/d 'x 'x))

;; ------------------------------------------------------------------
;; membership tests over a Scheme list of mk-terms (the classified sets)
;; ------------------------------------------------------------------

;; Succeeds iff `a` unifies with exactly one element of `set` (ground `a`,
;; distinct elements): singleton-commit; refutes on empty/no-match; stalls only
;; if `a` is holey (which never happens at the call sites -- `a` is a committed
;; symbol there).
(define (member-of/d a set)
  (cond
    [(null? set) fail/d-goal]
    [(null? (cdr set)) (==/d a (car set))]
    [else
     (conde/d
       ([]
        [(==/d a (car set))]
        [])
       ([]
        [(member-of/d a (cdr set))]
        []))]))

;; Succeeds iff `a` differs from every element of `set` (conjunction of =/=).
(define (not-member-of/d a set)
  (if (null? set)
      succeed/d
      (fresh/d ()
        (=/=/d a (car set))
        (not-member-of/d a (cdr set)))))

;; ------------------------------------------------------------------
;; is `a` a bare variable classified `smaller`?  (a self-call argument)
;;   succeed iff `a` is a symbol in `smallers`
;;   refute  iff `a` is a determined non-(smaller-var): number, '(), cons/if/
;;           match/application expression, or a symbol not in `smallers`
;;   stall   iff `a` is a hole (several shape clauses live at once)
;; ------------------------------------------------------------------
(define (arg-decreasing/d a smallers)
  (conde/d
    ;; a is a symbol -> membership in smallers decides
    ([]
     [(symbolo/d a)]
     [(member-of/d a smallers)])
    ;; a is a number literal -> not a bare var -> refute
    ([]
     [(numbero/d a)]
     [fail/d-goal])
    ;; a is '()
    ([]
     [(==/d '(quote ()) a)]
     [fail/d-goal])
    ;; a is (cons ...)
    ([e1 e2]
     [(==/d `(cons ,e1 ,e2) a)]
     [fail/d-goal])
    ;; a is (if (= ...) ...)
    ([e1 e2 e3 e4]
     [(==/d `(if (= ,e1 ,e2) ,e3 ,e4) a)]
     [fail/d-goal])
    ;; a is (match ...)
    ([e f1 x y f2]
     [(==/d `(match ,e ['() ,f1] [(cons ,x ,y) ,f2]) a)]
     [fail/d-goal])
    ;; a is an application (rator . rands)
    ([rator rands]
     [(==/d `(,rator . ,rands) a)
      (symbolo/d rator)
      (absento/d rator view-app-keywords)]
     [fail/d-goal])))

;; ------------------------------------------------------------------
;; the slot-th operand of a self-call must be a `smaller` bare variable.
;; Holey rands -> stall (rands could be '() or a pair).
;; ------------------------------------------------------------------
(define (nth-rand-decreasing/d rands slot smallers)
  (conde/d
    ;; too few args: the slot-th operand is absent -> not decreasing -> refute
    ([]
     [(==/d '() rands)]
     [fail/d-goal])
    ;; (a . d)
    ([a d]
     [(==/d `(,a . ,d) rands)]
     [(if (= slot 1)
          (arg-decreasing/d a smallers)
          (nth-rand-decreasing/d d (- slot 1) smallers))])))

;; ------------------------------------------------------------------
;; every operand of an application must itself satisfy all-decreasing (nested
;; self-calls can hide inside operands).  AND over the operand list.
;; ------------------------------------------------------------------
(define (rands-all-decreasing/d fname rands slot sames smallers)
  (conde/d
    ([]
     [(==/d '() rands)]
     [])
    ([a d]
     [(==/d `(,a . ,d) rands)]
     [(all-decreasing-at/d fname a slot sames smallers)
      (rands-all-decreasing/d fname d slot sames smallers)])))

;; ------------------------------------------------------------------
;; no match pattern var may shadow any name in `forbidden`.
;; ------------------------------------------------------------------
(define (all-diseq/d v forbidden)
  (if (null? forbidden)
      succeed/d
      (fresh/d ()
        (=/=/d v (car forbidden))
        (all-diseq/d v (cdr forbidden)))))

(define (no-shadow/d vars forbidden)
  (if (null? vars)
      succeed/d
      (fresh/d ()
        (all-diseq/d (car vars) forbidden)
        (no-shadow/d (cdr vars) forbidden))))

;; ------------------------------------------------------------------
;; classify a match's cons-branch pattern vars, then check e2.
;;   e is a bare classified var (in sames U smallers) -> x,y join smallers
;;   e is any other determined shape                  -> x,y unclassified
;;   e holey                                           -> stall
;; ------------------------------------------------------------------
(define (sym-scrutinee-branch/d fname e x y e2 slot sames smallers)
  ;; e is known to be a symbol here; membership in sames U smallers decides.
  (let ([classified (append sames smallers)])
    (conde/d
      ;; scrutinee is a classified variable -> x,y are strictly smaller
      ([]
       [(member-of/d e classified)]
       [(all-decreasing-at/d fname e2 slot sames (cons x (cons y smallers)))])
      ;; scrutinee is an unclassified variable -> x,y get no classification
      ([]
       [(not-member-of/d e classified)]
       [(all-decreasing-at/d fname e2 slot sames smallers)]))))

(define (match-branch-decreasing/d fname e x y e2 slot sames smallers)
  ;; discriminate on the scrutinee's shape; a hole makes several clauses live
  ;; -> stall.  Only a bare classified variable extends the environment.
  (conde/d
    ;; scrutinee is a symbol -> defer to membership test
    ([]
     [(symbolo/d e)]
     [(sym-scrutinee-branch/d fname e x y e2 slot sames smallers)])
    ;; scrutinee is a number -> x,y unclassified
    ([]
     [(numbero/d e)]
     [(all-decreasing-at/d fname e2 slot sames smallers)])
    ;; scrutinee is '()
    ([]
     [(==/d '(quote ()) e)]
     [(all-decreasing-at/d fname e2 slot sames smallers)])
    ;; scrutinee is (cons ...)
    ([a b]
     [(==/d `(cons ,a ,b) e)]
     [(all-decreasing-at/d fname e2 slot sames smallers)])
    ;; scrutinee is (if (= ...) ...)
    ([a b c dd]
     [(==/d `(if (= ,a ,b) ,c ,dd) e)]
     [(all-decreasing-at/d fname e2 slot sames smallers)])
    ;; scrutinee is (match ...)
    ([ee f1 xx yy f2]
     [(==/d `(match ,ee ['() ,f1] [(cons ,xx ,yy) ,f2]) e)]
     [(all-decreasing-at/d fname e2 slot sames smallers)])
    ;; scrutinee is an application
    ([rator rands]
     [(==/d `(,rator . ,rands) e)
      (symbolo/d rator)
      (absento/d rator view-app-keywords)]
     [(all-decreasing-at/d fname e2 slot sames smallers)])))

;; ------------------------------------------------------------------
;; the core walk: EVERY self-call in `body` is decreasing at `slot`, given the
;; environment (sames, smallers).  Conjunction over subterms throughout.
;; ------------------------------------------------------------------
(define (all-decreasing-at/d fname body slot sames smallers)
  (conde/d
    ;; number literal -- no self-call
    ([]
     [(numbero/d body)]
     [])
    ;; variable reference -- no self-call
    ([]
     [(symbolo/d body)]
     [])
    ;; '() literal
    ([]
     [(==/d '(quote ()) body)]
     [])
    ;; (cons e1 e2): both operands (AND)
    ([e1 e2]
     [(==/d `(cons ,e1 ,e2) body)]
     [(all-decreasing-at/d fname e1 slot sames smallers)
      (all-decreasing-at/d fname e2 slot sames smallers)])
    ;; (if (= e1 e2) e3 e4): all four subterms (AND -- for-all over self-calls)
    ([e1 e2 e3 e4]
     [(==/d `(if (= ,e1 ,e2) ,e3 ,e4) body)]
     [(all-decreasing-at/d fname e1 slot sames smallers)
      (all-decreasing-at/d fname e2 slot sames smallers)
      (all-decreasing-at/d fname e3 slot sames smallers)
      (all-decreasing-at/d fname e4 slot sames smallers)])
    ;; (match e ['() e1] [(cons x y) e2]): scrutinee AND nil-branch AND
    ;; cons-branch (with possibly-extended environment).  No-shadowing of fname
    ;; and of every classified name.
    ([e e1 x y e2]
     [(==/d `(match ,e ['() ,e1] [(cons ,x ,y) ,e2]) body)
      (symbolo/d x)
      (symbolo/d y)
      (no-shadow/d (list x y) (cons fname (append sames smallers)))]
     [(all-decreasing-at/d fname e slot sames smallers)
      (all-decreasing-at/d fname e1 slot sames smallers)
      (match-branch-decreasing/d fname e x y e2 slot sames smallers)])
    ;; self-application (fname . rands): slot-th operand must be a smaller bare
    ;; var, AND the operands themselves must be all-decreasing.
    ([rands]
     [(==/d `(,fname . ,rands) body)]
     [(nth-rand-decreasing/d rands slot smallers)
      (rands-all-decreasing/d fname rands slot sames smallers)])
    ;; other application (rator . rands), rator =/= fname: recurse into operands
    ([rator rands]
     [(==/d `(,rator . ,rands) body)
      (symbolo/d rator)
      (=/=/d rator fname)
      (absento/d rator view-app-keywords)]
     [(rands-all-decreasing/d fname rands slot sames smallers)])))

;; ------------------------------------------------------------------
;; the public relation: an OUTER conde/d over parameter positions.  Clause i's
;; guard is the whole position-i walk.  Built as a right-nested binary conde/d
;; so it works for any arity (2 clauses for our 2-param benchmarks).
;;   both positions live  -> stall (sound: some fixed position works)
;;   exactly one live     -> commit
;;   all refuted          -> refute
;; ------------------------------------------------------------------
(define (decreasing-recursiono/d fname params body)
  (let loop ([slot 1] [ps params])
    (cond
      [(null? ps) fail/d-goal] ; no positions -> refute
      [(null? (cdr ps))
       ;; last (or only) position: no disjunction wrapper needed
       (all-decreasing-at/d fname body slot (list (car ps)) '())]
      [else
       (conde/d
         ([]
          [(all-decreasing-at/d fname body slot (list (car ps)) '())]
          [])
         ([]
          [(loop (+ slot 1) (cdr ps))]
          []))])))

;;; ------------------------------------------------------------------
;;; Validation gates.  Run when this file is loaded (./run.sh loads it).
;;; ------------------------------------------------------------------

;; ACCEPT (succeed or stall -- q left unbound -> '(_.0)).

;; canonical rember body: commits position 2 (d strictly-smaller-than l).
(test "decreasing-recursiono/d: canonical rember accepted"
  (run 1 (q)
    (follower q
      (decreasing-recursiono/d 'rember '(e l)
        '(match l ['() l] [(cons a d) (if (= a e) d (cons a (rember e d)))]))))
  '(_.0))

;; canonical append body: commits position 1 (d strictly-smaller-than l).
(test "decreasing-recursiono/d: canonical append accepted"
  (run 1 (q)
    (follower q
      (decreasing-recursiono/d 'append '(l s)
        '(match l ['() s] [(cons a d) (cons a (append d s))]))))
  '(_.0))

;; rember-e-a: `a` (list head) is a strict structural descendant of l, so rung 2
;; (structural only, no types) ACCEPTS.  Left for examples/evalo to refute.
(test "decreasing-recursiono/d: (rember e a) accepted (structural, no types)"
  (run 1 (q)
    (follower q
      (decreasing-recursiono/d 'rember '(e l)
        '(match l ['() l] [(cons a d) (rember e a)]))))
  '(_.0))

;; STALL on holes: leaves the holes unbound, does not refute or over-commit.
(test "decreasing-recursiono/d: holey match stalls, holes unbound"
  (run 1 (h1 h2)
    (follower (list h1 h2)
      (decreasing-recursiono/d 'rember '(e l)
        `(match l ['() ,h1] [(cons a d) ,h2]))))
  '((_.0 _.1)))

;; bare hole stalls (undetermined) -> q unbound.
(test "decreasing-recursiono/d: bare hole stalls"
  (run 1 (q)
    (follower q (decreasing-recursiono/d 'rember '(e l) q)))
  '(_.0))

;; REFUTE (ground, no fixed position works -> '()).

;; recurs on l itself (same, not smaller) at position 2; position 1 fails too.
(test "decreasing-recursiono/d: (rember e l) refuted"
  (run 1 (q)
    (follower q
      (decreasing-recursiono/d 'rember '(e l)
        '(match l ['() l] [(cons a d) (rember e l)]))))
  '())

;; self-call operand is a cons EXPRESSION, not a bare smaller var -> refute.
(test "decreasing-recursiono/d: (rember e (cons a l)) refuted"
  (run 1 (q)
    (follower q
      (decreasing-recursiono/d 'rember '(e l)
        '(match l ['() l] [(cons a d) (rember e (cons a l))]))))
  '())

;; argument-swap: (rember d e).  d is smaller but at slot 1 (param e, no descent
;; from e); slot 2 arg e is not smaller-than l.  Both positions refute.
(test "decreasing-recursiono/d: argument-swap (rember d e) refuted"
  (run 1 (q)
    (follower q
      (decreasing-recursiono/d 'rember '(e l)
        '(match l ['() l] [(cons a d) (rember d e)]))))
  '())

;; === R2P: permuted-decreasing-recursiono/d --- a GENERALIZED termination view.
;;
;; R2 (`decreasing-recursiono/d`) demands ONE FIXED argument position that
;; structurally decreases in EVERY self-call.  That is sound but too weak for
;; argument-PERMUTING recursions: interleave's canonical body
;;   (match l1 ['() l2] [(cons a d) (cons a (interleave l2 d))])
;; swaps its arguments in the self-call -- position 1 gets l2 (parameter 2, not
;; a descendant of l1) and position 2 gets d (a descendant of l1, but at the l2
;; slot).  No fixed position decreases, so R2 refutes it, and dropping R2
;; leaves interleave infeasible (see claude/2026-07-12-214500 finding 4).
;;
;;   (permuted-decreasing-recursiono/d fname params body)
;;     succeeds  iff  EVERY self-call's arguments admit an INJECTIVE assignment
;;                    to DISTINCT formal parameters (a permutation when arities
;;                    match) such that each argument is equal-to-or-a-structural-
;;                    descendant-of its assigned parameter, and AT LEAST ONE
;;                    argument is a PROPER (strict) descendant.  The assignment
;;                    may differ per call site.
;;     fails     iff  some self-call admits no such assignment
;;     stalls         while the term is too holey to decide either way
;;
;; --- soundness argument ---
;;
;;  Consider the multiset (equivalently, the plain sum) of the CURRENT sizes of
;;  the actual arguments at a self-call.  Under an injective assignment sigma
;;  with each arg a_k satisfying  |a_k| <= |p_{sigma(k)}|  (arg is equal-to-or-a-
;;  descendant-of its assigned parameter) and at least one k strict
;;  (|a_k| < |p_{sigma(k)}|), the sum of the argument sizes at the call is
;;  STRICTLY LESS than the sum of the formal parameters' current sizes: sigma
;;  injective means each source parameter is charged at most once, so the
;;  arguments' sizes are bounded by a sub-selection of DISTINCT parameter sizes,
;;  hence  sum_k |a_k| <= sum_k |p_{sigma(k)}| <= sum_j |p_j|, with the first
;;  inequality strict by the one strict k.  So the summed parameter size
;;  strictly decreases at every self-call.  It is a natural number (sizes are
;;  finite on finite inputs), so it cannot decrease forever: recursion
;;  terminates.  Per-site assignments COMPOSE because the measure -- the sum
;;  over arguments -- is evaluated per call and does not depend on which
;;  permutation was used at any other call.
;;
;;  INJECTIVITY IS REQUIRED.  Without it, two arguments could both be charged to
;;  the same large parameter (e.g. (f d d) where d descends from p1 only): the
;;  per-position check "slot 1 decreases" holds, yet the multiset sum can GROW,
;;  and the recursion can diverge.  So R2P REFUTES (f d d) -- distinct sources
;;  for distinct args -- even though R2's fixed-position check accepts it (R2
;;  only inspects one slot and ignores the collision at the other).
;;
;; --- implementation (mirrors R2's machinery) ---
;;
;;  R2 threads (slot, sames, smallers) relative to ONE parameter.  R2P threads
;;  `psets`: a Scheme list, one entry per parameter, each entry a pair
;;  (sames_j . smallers_j) of mk-terms classified relative to p_j.  Initially
;;  sames_j = (p_j), smallers_j = ().  At a match (match e ['() e1] [(cons x y)
;;  e2]) whose scrutinee e is a bare variable classified under some family j
;;  (e in sames_j U smallers_j), the pattern vars x,y join smallers_j within e2
;;  (they are proper descendants of p_j); e is classified under at most one
;;  family, so at most one family is extended.  A self-call is checked by an
;;  INNER conde/d over injective assignments (arity 1: identity; arity 2:
;;  identity and swap), each clause's guard being the whole "all args <= their
;;  param, one strict" check; both live -> stall, one live -> commit, none ->
;;  refute.  Arity > 2 is a documented error (arity <= 2 covers the whole suite).
;;
;;  Holes stall, for-ALL distributes as conjunction, no-shadowing of fname and
;;  every classified name, non-fname operators recursed-into-operands-only --
;;  all exactly as R2.  Types are NOT modelled (same as R2): left for TY/EX.

;; family_j's classified set = sames_j U smallers_j (the "<=" set for p_j).
(define (family-union pset) (append (car pset) (cdr pset)))

;; every classified name across all families (for no-shadowing).
(define (all-classified psets) (apply append (map family-union psets)))

;; is `a` a bare var equal-to-or-descended-from param p (<=)?  Reuses R2's
;; arg-decreasing/d (bare-var membership) against the family's whole <= set.
(define (arg-le/d a pset)
  (arg-decreasing/d a (family-union pset)))

;; is `a` a bare var that is a PROPER descendant of p (strict)?  Membership in
;; smallers only.
(define (arg-strict/d a pset)
  (arg-decreasing/d a (cdr pset)))

;; is `a` a bare var EQUAL to p (same-size, not strict)?  Membership in sames.
(define (arg-same/d a pset)
  (arg-decreasing/d a (car pset)))

;; a pair of args assigned to a pair of params: aA <= pA, aB <= pB, and at
;; least one strict.  The two clause guards -- "aA strict" vs "aA same" -- are
;; MUTUALLY EXCLUSIVE (sames_A and smallers_A are disjoint: a var is p_A or a
;; proper descendant of p_A, never both), so for a ground call exactly one
;; commits (or neither -> refute; holey -> stall):
;;   aA strict -> aB need only be <=            (one strict already found)
;;   aA same   -> aB MUST be strict             (else nothing decreases)
(define (assign-pair/d aA psetA aB psetB)
  (conde/d
    ([]
     [(arg-strict/d aA psetA)]
     [(arg-le/d aB psetB)])
    ([]
     [(arg-same/d aA psetA)]
     [(arg-strict/d aB psetB)])))

;; the assignment check at a self-call: args (a Scheme list of mk-terms) vs
;; psets (a Scheme list of families), same length.  arity 1: forced identity,
;; the single arg must be strict.  arity 2: an OUTER conde/d over the two
;; injective assignments (identity, swap); both live -> stall, one -> commit,
;; none -> refute.  arity > 2: documented error.
(define (assignment-check/d args psets)
  (let ([n (length psets)])
    (cond
      [(= n 1)
       (arg-strict/d (car args) (car psets))]
      [(= n 2)
       (let ([a1 (car args)]
             [a2 (cadr args)]
             [p1 (car psets)]
             [p2 (cadr psets)])
         (conde/d
           ([] ; identity: a1<-p1, a2<-p2
            [(assign-pair/d a1 p1 a2 p2)]
            [])
           ([] ; swap: a1<-p2, a2<-p1
            [(assign-pair/d a1 p2 a2 p1)]
            [])))]
      [else
       (error 'permuted-decreasing-recursiono/d
         "arity > 2 not supported" n)])))

;; destructure `rands` (a possibly-holey mk-list) into EXACTLY n args, then
;; call the Scheme continuation `k` (args-as-Scheme-list -> goal).  Stall-safe:
;; a holey `rands` leaves the '()-clause and the pair-clause both live -> stall
;; (never over-commits a hole).  Too few / too many args -> refute (a self-call
;; of the wrong arity cannot be the well-formed recursive call).
(define (destructure-rands/d rands n k)
  (if (= n 0)
      (conde/d
        ([]
         [(==/d '() rands)]
         [(k '())])
        ([a d]
         [(==/d `(,a . ,d) rands)]
         [fail/d-goal])) ; extra args
      (conde/d
        ([]
         [(==/d '() rands)]
         [fail/d-goal]) ; too few args
        ([a d]
         [(==/d `(,a . ,d) rands)]
         [(destructure-rands/d d (- n 1)
            (lambda (rest) (k (cons a rest))))]))))

;; a self-call (fname . rands): its args must admit a valid injective assignment.
(define (self-call-perm/d rands psets)
  (destructure-rands/d rands (length psets)
    (lambda (args) (assignment-check/d args psets))))

;; classify a match's cons-branch pattern vars under the RIGHT family, then
;; check e2.  `e` is known to be a symbol here.  If e belongs to family j
;; (e in family_j's <= set), x,y join smallers_j; if e belongs to no family,
;; no extension.  The membership guards are mutually exclusive (e is in at most
;; one family), so a ground e commits exactly one clause; a still-unbound symbol
;; var makes the membership tests stall.  arity <= 2 written out explicitly.
(define (sym-scrutinee-perm/d fname e x y e2 psets)
  (let ([n (length psets)])
    (cond
      [(= n 1)
       (let* ([p0 (car psets)]
              [u0 (family-union p0)]
              [ext0 (list (cons (car p0) (cons x (cons y (cdr p0)))))])
         (conde/d
           ([]
            [(member-of/d e u0)]
            [(all-decreasing-perm/d fname e2 ext0)])
           ([]
            [(not-member-of/d e u0)]
            [(all-decreasing-perm/d fname e2 psets)])))]
      [(= n 2)
       (let* ([p0 (car psets)]
              [p1 (cadr psets)]
              [u0 (family-union p0)]
              [u1 (family-union p1)]
              [ext0 (list (cons (car p0) (cons x (cons y (cdr p0)))) p1)]
              [ext1 (list p0 (cons (car p1) (cons x (cons y (cdr p1)))))])
         (conde/d
           ([]
            [(member-of/d e u0)]
            [(all-decreasing-perm/d fname e2 ext0)])
           ([]
            [(member-of/d e u1)]
            [(all-decreasing-perm/d fname e2 ext1)])
           ([]
            [(fresh/d ()
               (not-member-of/d e u0)
               (not-member-of/d e u1))]
            [(all-decreasing-perm/d fname e2 psets)])))]
      [else
       (error 'permuted-decreasing-recursiono/d
         "arity > 2 not supported" n)])))

;; discriminate on a match scrutinee's shape; a hole -> stall.  Only a bare
;; classified variable extends the environment (via sym-scrutinee-perm/d).
(define (match-branch-perm/d fname e x y e2 psets)
  (conde/d
    ([]
     [(symbolo/d e)]
     [(sym-scrutinee-perm/d fname e x y e2 psets)])
    ([]
     [(numbero/d e)]
     [(all-decreasing-perm/d fname e2 psets)])
    ([]
     [(==/d '(quote ()) e)]
     [(all-decreasing-perm/d fname e2 psets)])
    ([a b]
     [(==/d `(cons ,a ,b) e)]
     [(all-decreasing-perm/d fname e2 psets)])
    ([a b c dd]
     [(==/d `(if (= ,a ,b) ,c ,dd) e)]
     [(all-decreasing-perm/d fname e2 psets)])
    ([ee f1 xx yy f2]
     [(==/d `(match ,ee ['() ,f1] [(cons ,xx ,yy) ,f2]) e)]
     [(all-decreasing-perm/d fname e2 psets)])
    ([rator rands]
     [(==/d `(,rator . ,rands) e)
      (symbolo/d rator)
      (absento/d rator view-app-keywords)]
     [(all-decreasing-perm/d fname e2 psets)])))

;; every operand of an application must itself satisfy all-decreasing (nested
;; self-calls can hide inside operands).  AND over the operand list.
(define (rands-all-perm/d fname rands psets)
  (conde/d
    ([]
     [(==/d '() rands)]
     [])
    ([a d]
     [(==/d `(,a . ,d) rands)]
     [(all-decreasing-perm/d fname a psets)
      (rands-all-perm/d fname d psets)])))

;; the core walk: EVERY self-call in `body` is permuted-decreasing, given the
;; per-parameter environment `psets`.  Conjunction over subterms throughout
;; (for-ALL over self-calls, so no path-OR).  Mirrors R2's all-decreasing-at/d.
(define (all-decreasing-perm/d fname body psets)
  (conde/d
    ;; number literal -- no self-call
    ([]
     [(numbero/d body)]
     [])
    ;; variable reference -- no self-call
    ([]
     [(symbolo/d body)]
     [])
    ;; '() literal
    ([]
     [(==/d '(quote ()) body)]
     [])
    ;; (cons e1 e2): both operands (AND)
    ([e1 e2]
     [(==/d `(cons ,e1 ,e2) body)]
     [(all-decreasing-perm/d fname e1 psets)
      (all-decreasing-perm/d fname e2 psets)])
    ;; (if (= e1 e2) e3 e4): all four subterms (AND)
    ([e1 e2 e3 e4]
     [(==/d `(if (= ,e1 ,e2) ,e3 ,e4) body)]
     [(all-decreasing-perm/d fname e1 psets)
      (all-decreasing-perm/d fname e2 psets)
      (all-decreasing-perm/d fname e3 psets)
      (all-decreasing-perm/d fname e4 psets)])
    ;; (match e ['() e1] [(cons x y) e2]): scrutinee AND nil-branch AND cons-
    ;; branch (with possibly-extended env).  No-shadowing of fname and of every
    ;; classified name.
    ([e e1 x y e2]
     [(==/d `(match ,e ['() ,e1] [(cons ,x ,y) ,e2]) body)
      (symbolo/d x)
      (symbolo/d y)
      (no-shadow/d (list x y) (cons fname (all-classified psets)))]
     [(all-decreasing-perm/d fname e psets)
      (all-decreasing-perm/d fname e1 psets)
      (match-branch-perm/d fname e x y e2 psets)])
    ;; self-application (fname . rands): args must admit a valid injective
    ;; assignment, AND the operands themselves must be all-decreasing.
    ([rands]
     [(==/d `(,fname . ,rands) body)]
     [(self-call-perm/d rands psets)
      (rands-all-perm/d fname rands psets)])
    ;; other application (rator . rands), rator =/= fname: recurse into operands.
    ([rator rands]
     [(==/d `(,rator . ,rands) body)
      (symbolo/d rator)
      (=/=/d rator fname)
      (absento/d rator view-app-keywords)]
     [(rands-all-perm/d fname rands psets)])))

;; the public relation.  Initialize psets: each parameter p_j starts in its own
;; sames_j = (p_j), smallers_j = ().  arity > 2 -> documented error.
(define (permuted-decreasing-recursiono/d fname params body)
  (if (> (length params) 2)
      (error 'permuted-decreasing-recursiono/d
        "arity > 2 not supported" (length params))
      (all-decreasing-perm/d fname body
        (map (lambda (p) (cons (list p) '())) params))))

;;; ------------------------------------------------------------------
;;; Validation gates.  Run when this file is loaded (./run.sh loads it).
;;; ------------------------------------------------------------------

;; ACCEPT (succeed or stall -- q left unbound -> '(_.0)).

;; THE HEADLINE: interleave's argument-SWAPPING canonical body, which R2
;; refutes, is ACCEPTED by R2P via the swap assignment (l2<-l2 same, d<-l1
;; strict).
(test "permuted-decreasing-recursiono/d: interleave (arg-swap) ACCEPTED"
  (run 1 (q)
    (follower q
      (permuted-decreasing-recursiono/d 'interleave '(l1 l2)
        '(match l1 ['() l2] [(cons a d) (cons a (interleave l2 d))]))))
  '(_.0))

;; canonical rember (identity, position-2 strict) still accepted.
(test "permuted-decreasing-recursiono/d: canonical rember accepted"
  (run 1 (q)
    (follower q
      (permuted-decreasing-recursiono/d 'rember '(e l)
        '(match l ['() l] [(cons a d) (if (= a e) d (cons a (rember e d)))]))))
  '(_.0))

;; canonical append (identity, position-1 strict) still accepted.
(test "permuted-decreasing-recursiono/d: canonical append accepted"
  (run 1 (q)
    (follower q
      (permuted-decreasing-recursiono/d 'append '(l s)
        '(match l ['() s] [(cons a d) (cons a (append d s))]))))
  '(_.0))

;; STALL on holes: leaves the holes unbound, does not refute or over-commit.
(test "permuted-decreasing-recursiono/d: holey match stalls, holes unbound"
  (run 1 (h1 h2)
    (follower (list h1 h2)
      (permuted-decreasing-recursiono/d 'rember '(e l)
        `(match l ['() ,h1] [(cons a d) ,h2]))))
  '((_.0 _.1)))

;; STALL on a self-call whose argument is a bare hole (cannot classify yet).
(test "permuted-decreasing-recursiono/d: self-call with holey arg stalls"
  (run 1 (h)
    (follower h
      (permuted-decreasing-recursiono/d 'rember '(e l)
        `(match l ['() l] [(cons a d) (rember e ,h)]))))
  '(_.0))

;; bare hole stalls (undetermined) -> q unbound.
(test "permuted-decreasing-recursiono/d: bare hole stalls"
  (run 1 (q)
    (follower q (permuted-decreasing-recursiono/d 'rember '(e l) q)))
  '(_.0))

;; REFUTE (ground, no valid injective assignment -> '()).

;; identity self-call with NOTHING strict: (rember e l) recurs on l itself.
(test "permuted-decreasing-recursiono/d: (rember e l) refuted (no strict)"
  (run 1 (q)
    (follower q
      (permuted-decreasing-recursiono/d 'rember '(e l)
        '(match l ['() l] [(cons a d) (rember e l)]))))
  '())

;; ASCENDING self-call: (rember e (cons a l)) -- arg is a cons EXPRESSION, not a
;; bare descendant var, at every position -> refute.
(test "permuted-decreasing-recursiono/d: (rember e (cons a l)) refuted (ascending)"
  (run 1 (q)
    (follower q
      (permuted-decreasing-recursiono/d 'rember '(e l)
        '(match l ['() l] [(cons a d) (rember e (cons a l))]))))
  '())

;; NON-INJECTIVE: (interleave d d) -- both args descend from l1 only, so no
;; injective assignment to distinct params exists -> REFUTE (violates
;; injectivity), even though slot 1 alone decreases (which is what R2 accepts).
(test "permuted-decreasing-recursiono/d: (interleave d d) refuted (non-injective)"
  (run 1 (q)
    (follower q
      (permuted-decreasing-recursiono/d 'interleave '(l1 l2)
        '(match l1 ['() l2] [(cons a d) (interleave d d)]))))
  '())

;; CURIOSITY (recorded, not a soundness gate): plain R2 ACCEPTS (interleave d d)
;; because it inspects only ONE fixed slot (slot 1, where d IS smaller) and
;; ignores the collision at slot 2.  R2P refutes it (test above).  This makes
;; the fixed-position-vs-injective difference concrete.
(test "decreasing-recursiono/d: (interleave d d) ACCEPTED by R2 (fixed-position)"
  (run 1 (q)
    (follower q
      (decreasing-recursiono/d 'interleave '(l1 l2)
        '(match l1 ['() l2] [(cons a d) (interleave d d)]))))
  '(_.0))

;; === R2T: terminating-recursiono/d --- whole-body disjunction R2 OR R2P.
;;
;; *** NON-VIABLE AS A FOLLOWER VIEW (recorded negative, 2026-07-13). ***
;; The accept/refute SEMANTICS below are correct and all gates pass, but the
;; combinator concluding-oro/d DIVERGES when used in a real follower: on its
;; both-live re-fire paths it re-runs both disjunct walks from scratch and
;; discards each disjunct's parked suspend-depth frontier, so a candidate whose
;; termination proof in the surviving disjunct needs more than one suspend-depth
;; window (sd=20) is never refuted -- evalo/d then evaluates the non-terminating
;; candidate to the depth ceiling and the follower explodes (measured: tiny
;; unify-main, exploding unify-follower on duplicate and interleave; clean
;; machine).  Root cause is structural: an OR of two INDEPENDENTLY-suspending
;; whole-body /d checks cannot achieve the cross-fire deepening the sound
;; suspend-depth cutoff relies on, because each disjunct's frontier lives in its
;; own committed scope and the follower carries a single state -- you can neither
;; commit one disjunct's scope (that would unsoundly assert it) nor carry both.
;; DECISION: use per-task measure selection instead (R2 default; R2P for
;; argument-permuting recursion such as interleave -- interleave feasibility is
;; already delivered by R2P alone, 108,475 unify @ bound 35).  Forward
;; directions in the backlog: (1) a unified single-frontier walk that branches
;; only at the per-self-call measure test (one committed state); (2) reorder
;; conj/d-run's resume worklist so cheap refuters run before evalo/d.  Full
;; mechanism: claude/2026-07-13-040000-r2p-r2t-termination-generalization.md.
;;

;; R2 and R2P are INCOMPARABLE (see the R2P section and gates): R2 accepts
;; rev-acc's growing-accumulator recursion (fixed position l decreases; the
;; accumulator argument is simply ignored) but refutes interleave's
;; argument-swap; R2P accepts interleave (injective multiset measure) but
;; refutes rev-acc (the accumulator arg (cons a acc) is LARGER than acc, so the
;; summed measure cannot decrease).  The production view is their disjunction.
;;
;;   (terminating-recursiono/d fname params body)
;;     succeeds  iff  the FULL R2 check succeeds on `body` OR the FULL R2P
;;                    check succeeds on `body`
;;     fails     iff  BOTH refute
;;     stalls         otherwise (no disjunct has succeeded and at least one is
;;                    still undetermined)
;;
;; --- soundness ---
;;
;;  Each disjunct is a COMPLETE well-founded measure checked over ALL self-call
;;  sites of the body: R2 = "some fixed argument position strictly decreases at
;;  every self-call"; R2P = "at every self-call the injective-assignment
;;  multiset sum strictly decreases".  The disjunction just says "the function
;;  terminates by the fixed-position measure or by the injective-multiset
;;  measure" -- both well-founded, so either alone implies termination.
;;  PER-SITE MIXING of the two measures would be UNSOUND (the classic
;;  measure-alternation trap: one call decreases measure A while growing B, the
;;  next decreases B while growing A, and neither ever bottoms out).  This
;;  relation never mixes: it is all-sites-R2 OR all-sites-R2P, each disjunct
;;  evaluated over the whole body.
;;
;; --- concluding-oro/d: OR of two pure /d CHECKS that can conclude success ---
;;
;; Why not the existing `oro/d` (experiments/negative-view-branch-vacuity.scm),
;; the two-clause conde/d with the disjuncts as guards?  Evaluated against the
;; truth table this view needs:
;;
;;   g1 refutes + g2 stalls  -> oro/d: one live clause -> commit-with-resume
;;                              -> STALL         (correct: must not refute)
;;   both refute             -> oro/d: REFUTE    (correct)
;;   g1 stalls + g2 succeeds -> oro/d: two live guards -> nondeterministic ->
;;                              STALL             (WRONG: the disjunction is
;;                              definitively true; should SUCCEED)
;;   both succeed            -> oro/d: STALL, permanently -- semantically fine
;;                              for a check but the goal re-fires at every
;;                              trigger forever, and for R2T both-accept is the
;;                              COMMON case (most surviving bodies satisfy both
;;                              measures)
;;
;; oro/d is committed-choice (guards must be mutually exclusive to conclude);
;; a disjunction of overlapping checks needs different success semantics, so
;; we build concluding-oro/d directly on the inf/d representation.  It
;; evaluates BOTH disjuncts against the entry state and combines outcomes
;; (S = singleton success, T = soft-suspended, H = hard-suspended, R = refuted):
;;
;;   r1 = R              -> return g2's stream UNCHANGED  (disjunction = g2)
;;   r2 = R              -> return r1 UNCHANGED           (disjunction = g1)
;;   any S (both live)   -> succeed with the ENTRY state  (conclude, no
;;                          extensions leak)
;;   any T (both live)   -> soft-stall; retry the whole disjunction
;;   else (H/H)          -> hard-stall; retry the whole disjunction
;;
;; EXTENSIONS: a disjunct's store extensions (bindings, =/=, symbolo, ...)
;; reach the outer state ONLY in the two collapse rows, where the other
;; disjunct has DEFINITIVELY refuted and the survivor is therefore forced --
;; its stream (partial extensions, resume thunk and all) is returned
;; unchanged, which is exactly conde/d's one-live-clause commit discipline.
;; /d refutation is definitive under state extension (the basis of follower
;; refutation soundness), so the collapse is permanent and sound.  In every
;; other success row the disjunction is true but WHICH disjunct holds is not
;; forced, so no extension is forced: we return the entry state and conclude.
;; (Discarding a pure check's extensions is always sound -- it only forgoes
;; pruning.)  The disjuncts here are pure checks, so nothing of value is
;; discarded.

;; classify an inf/d result (see case-inf/d in following.scm).
(define (inf/d-kind r)
  (case-inf/d r
    [() 'refute]
    [(c) 'success]
    [(c f) 'soft]
    [(ch fh) 'hard]))

(define (concluding-oro/d g1 g2)
  (lambda (unsound-fail-depth)
    (letrec ([or-g
              (lambda (suspend-depth)
                (lambda (st)
                  (let ([r1 (((g1 unsound-fail-depth) suspend-depth) st)])
                    (if (not r1)
                        ;; g1 definitively refuted: the disjunction IS g2.
                        (((g2 unsound-fail-depth) suspend-depth) st)
                        (let ([r2 (((g2 unsound-fail-depth) suspend-depth) st)])
                          (if (not r2)
                              ;; g2 definitively refuted: the disjunction IS g1.
                              r1
                              (let ([k1 (inf/d-kind r1)]
                                    [k2 (inf/d-kind r2)])
                                (cond
                                  ;; some disjunct definitively true -> conclude;
                                  ;; entry state (no extension is forced).
                                  [(or (eq? k1 'success) (eq? k2 'success))
                                   st]
                                  ;; some disjunct soft-suspended -> soft-stall,
                                  ;; retry the whole disjunction.
                                  [(or (eq? k1 'soft) (eq? k2 'soft))
                                   (cons st or-g)]
                                  ;; both hard-suspended -> defer to retrigger.
                                  [else (make-hard-suspended st or-g)]))))))))])
      or-g)))

;; the public relation: R2 OR R2P, whole-body each.
(define (terminating-recursiono/d fname params body)
  (concluding-oro/d
    (decreasing-recursiono/d fname params body)
    (permuted-decreasing-recursiono/d fname params body)))

;;; ------------------------------------------------------------------
;;; Validation gates.  Run when this file is loaded (./run.sh loads it).
;;; ------------------------------------------------------------------

;; ACCEPT: the two halves of the R2/R2P incomparability, both now accepted.

;; rev-acc: R2 accepts (fixed position l), R2P refutes (growing accumulator).
(test "terminating-recursiono/d: rev-acc accepted (via R2 disjunct)"
  (run 1 (q)
    (follower q
      (terminating-recursiono/d 'rev '(l acc)
        '(match l ['() acc] [(cons a d) (rev d (cons a acc))]))))
  '(_.0))

;; interleave: R2 refutes (argument swap), R2P accepts (swap assignment).
(test "terminating-recursiono/d: interleave accepted (via R2P disjunct)"
  (run 1 (q)
    (follower q
      (terminating-recursiono/d 'interleave '(l1 l2)
        '(match l1 ['() l2] [(cons a d) (cons a (interleave l2 d))]))))
  '(_.0))

;; canonical rember: BOTH disjuncts accept -> the disjunction concludes
;; success (this is the row where oro/d would have stalled forever).
(test "terminating-recursiono/d: canonical rember accepted (both disjuncts)"
  (run 1 (q)
    (follower q
      (terminating-recursiono/d 'rember '(e l)
        '(match l ['() l] [(cons a d) (if (= a e) d (cons a (rember e d)))]))))
  '(_.0))

;; (interleave d d): R2P refutes (non-injective) but R2 accepts (slot 1
;; decreases in every call -- a sound fixed-position measure; the body DOES
;; terminate), so the disjunction ACCEPTS.
(test "terminating-recursiono/d: (interleave d d) accepted (via R2 disjunct)"
  (run 1 (q)
    (follower q
      (terminating-recursiono/d 'interleave '(l1 l2)
        '(match l1 ['() l2] [(cons a d) (interleave d d)]))))
  '(_.0))

;; (rember d e): R2 refutes (argument swap) but R2P accepts (swap assignment
;; d<-l strict, e<-e same), so the disjunction ACCEPTS.
(test "terminating-recursiono/d: (rember d e) accepted (via R2P disjunct)"
  (run 1 (q)
    (follower q
      (terminating-recursiono/d 'rember '(e l)
        '(match l ['() l] [(cons a d) (rember d e)]))))
  '(_.0))

;; REFUTE: only when BOTH measures reject.

(test "terminating-recursiono/d: (rember e l) refuted (both measures reject)"
  (run 1 (q)
    (follower q
      (terminating-recursiono/d 'rember '(e l)
        '(match l ['() l] [(cons a d) (rember e l)]))))
  '())

(test "terminating-recursiono/d: (rember e (cons a l)) refuted (both reject)"
  (run 1 (q)
    (follower q
      (terminating-recursiono/d 'rember '(e l)
        '(match l ['() l] [(cons a d) (rember e (cons a l))]))))
  '())

;; STALL: one disjunct refutes, the other stalls -> must STALL, not refute.

;; R2 refutes this whole body outright (both slots fail at the ground
;; self-call (rember d e), and a refuted conjunct dominates the stalled hole);
;; R2P stalls (self-call fine via swap; the nil-branch hole is undecided).
(test "terminating-recursiono/d: R2-refutes/R2P-stalls -> stalls, hole unbound"
  (run 1 (h)
    (follower h
      (terminating-recursiono/d 'rember '(e l)
        `(match l ['() ,h] [(cons a d) (rember d e)]))))
  '(_.0))

;; mirror image: R2P refutes this body outright ((interleave d d) is
;; non-injective, refuted conjunct dominates); R2 stalls (slot 1 fine, the
;; nil-branch hole is undecided).
(test "terminating-recursiono/d: R2P-refutes/R2-stalls -> stalls, hole unbound"
  (run 1 (h)
    (follower h
      (terminating-recursiono/d 'interleave '(l1 l2)
        `(match l1 ['() ,h] [(cons a d) (interleave d d)]))))
  '(_.0))

;; STALL on plain holes, holes left unbound.
(test "terminating-recursiono/d: holey match stalls, holes unbound"
  (run 1 (h1 h2)
    (follower (list h1 h2)
      (terminating-recursiono/d 'rember '(e l)
        `(match l ['() ,h1] [(cons a d) ,h2]))))
  '((_.0 _.1)))

(test "terminating-recursiono/d: bare hole stalls"
  (run 1 (q)
    (follower q (terminating-recursiono/d 'rember '(e l) q)))
  '(_.0))

;; === TY: type-ofo/d --- rung 3 / third follower view: a /d TYPE checker
;; for the restricted language, composed into a follower alongside rungs 1 & 2.
;;
;; Rungs 1 (`base-case-patho/d`) and 2 (`decreasing-recursiono/d`) are purely
;; STRUCTURAL termination checks.  Rung 2 explicitly does NOT model types: it
;; ACCEPTS `(rember e a)` where `a` is the (numeric) list head passed at the
;; (list) recursion position, because `a` is a strict structural descendant of
;; `l`.  Such a body is ill-typed and evaluation-refutable, but examples only
;; refute it via unsound depth cutoffs.  This view refutes it syntactically the
;; instant the committed structure violates the declared types.
;;
;;   (type-ofo/d tyenv body type)
;;     succeeds  iff  `body` type-checks at `type` under `tyenv`
;;     fails     iff  the committed structure is ill-typed at `type`
;;     stalls         while the term is too holey to decide either way
;;
;; `tyenv` is a Scheme-level assoc list of (name . type) where name is an
;; mk-term (usually a ground symbol) and type is a ground type term.  Types:
;;   number | list | ((t1 ... tn) -> tr)   (arrows only via the letrec annot.)
;;
;; The three-way stall/commit/refute behaviour is inherited from conde/d, the
;; rung-1/2 technique: term-shape discrimination lives in the guards, so a hole
;; leaves several sibling clauses live -> stall; a committed shape leaves one.
;;
;; --- deliberate search-space restrictions (documented, like rungs 1 & 2) ---
;;
;;  * RECOGNIZED-CONSTRUCTS-ONLY.  The task allows being conservative on
;;    unrecognized constructs (letrec-in-body, non-recursive-fn applications,
;;    non-'() quote literals) by succeeding without constraining -- but a
;;    conde/d catch-all clause is always live and would make EVERYTHING stall.
;;    So instead we REQUIRE recognized constructs: an unrecognized body is
;;    REFUTED.  This is a search-space restriction (like no-shadowing), not a
;;    soundness statement about the language.  On these benchmarks the only
;;    binding in scope is the recursive fn, and the target answers contain no
;;    nested letrec or foreign application, so nothing real is discarded.
;;
;;  * No-shadowing: a match pattern var may not shadow any name already in
;;    `tyenv` (all tyenv names are type-classified).  Shadowing would corrupt
;;    the by-name type lookup.  A body that shadows is refuted.  (=/=/d guards,
;;    exactly as rungs 1 & 2.)
;;
;;  * Only the `(quote ())` quote literal is typed (-> list); any other quote
;;    form is refuted.  The language's interpreter only produces (quote ()).


(define type-view-app-keywords view-app-keywords) ; '(quote cons letrec match if)

;; ------------------------------------------------------------------
;; look up `name`'s type in the Scheme-level `tyenv`.  Written as a nested
;; conde/d that discriminates by ==/d / =/=/d on the name: a HOLE name makes
;; both clauses live -> stall; a committed name leaves one live.  An exhausted
;; tyenv (name not found) -> refute (unbound reference is ill-typed).
;; ------------------------------------------------------------------
(define (tyenv-lookupo/d tyenv name type)
  (if (null? tyenv)
      fail/d-goal
      (let ([n (car (car tyenv))]
            [t (cdr (car tyenv))])
        (conde/d
          ([]
           [(==/d name n)]
           [(==/d type t)])
          ([]
           [(=/=/d name n)]
           [(tyenv-lookupo/d (cdr tyenv) name type)])))))

;; ------------------------------------------------------------------
;; type each operand of an application at its declared argument type.  The
;; rands come from the (holey) body; the argtypes come from the (ground) arrow
;; type looked up for the operator.  AND over the two lists walked together;
;; a length mismatch (arity error) -> refute; a holey rand tail -> stall.
;; ------------------------------------------------------------------
(define (types-listo/d tyenv rands argtypes)
  (conde/d
    ([]
     [(==/d '() rands) (==/d '() argtypes)]
     [])
    ([a d ta td]
     [(==/d `(,a . ,d) rands) (==/d `(,ta . ,td) argtypes)]
     [(type-ofo/d tyenv a ta) (types-listo/d tyenv d td)])))

;; ------------------------------------------------------------------
;; the public relation.
;; ------------------------------------------------------------------
(define (type-ofo/d tyenv body type)
  (conde/d
    ;; number literal : number
    ([]
     [(numbero/d body)]
     [(==/d type 'number)])
    ;; variable reference : whatever tyenv says
    ([]
     [(symbolo/d body)]
     [(tyenv-lookupo/d tyenv body type)])
    ;; '() : list
    ([]
     [(==/d '(quote ()) body)]
     [(==/d type 'list)])
    ;; (cons e1 e2) : list, with e1 : number and e2 : list
    ([e1 e2]
     [(==/d `(cons ,e1 ,e2) body)]
     [(==/d type 'list)
      (type-ofo/d tyenv e1 'number)
      (type-ofo/d tyenv e2 'list)])
    ;; (match e ['() e1] [(cons x y) e2]) : e : list; e1 : T; e2 : T with
    ;; x : number, y : list added to tyenv.  No-shadowing on x, y.
    ([e e1 x y e2]
     [(==/d `(match ,e ['() ,e1] [(cons ,x ,y) ,e2]) body)
      (symbolo/d x)
      (symbolo/d y)
      (no-shadow/d (list x y) (map car tyenv))]
     [(type-ofo/d tyenv e 'list)
      (type-ofo/d tyenv e1 type)
      (type-ofo/d (cons (cons x 'number) (cons (cons y 'list) tyenv)) e2 type)])
    ;; (if (= e1 e2) e3 e4) : e1,e2 : number; e3,e4 : T
    ([e1 e2 e3 e4]
     [(==/d `(if (= ,e1 ,e2) ,e3 ,e4) body)]
     [(type-ofo/d tyenv e1 'number)
      (type-ofo/d tyenv e2 'number)
      (type-ofo/d tyenv e3 type)
      (type-ofo/d tyenv e4 type)])
    ;; application (rator rand ...): rator's arrow type ((t1 ... tn) -> tr) is
    ;; looked up in tyenv; result type = tr, each rand at its declared ti.
    ([rator rands ftype argtypes tr]
     [(==/d `(,rator . ,rands) body)
      (symbolo/d rator)
      (absento/d rator type-view-app-keywords)]
     [(tyenv-lookupo/d tyenv rator ftype)
      (==/d `(,argtypes -> ,tr) ftype)
      (==/d type tr)
      (types-listo/d tyenv rands argtypes)])))

;;; ------------------------------------------------------------------
;;; Validation gates.  Run when this file is loaded (./run.sh loads it).
;;; ------------------------------------------------------------------

(define rember-tyenv '((rember . ((number list) -> list)) (e . number) (l . list)))
(define append-tyenv '((append . ((list list) -> list)) (l . list) (s . list)))

;; ACCEPT: canonical rember body type-checks at list.
(test "type-ofo/d: canonical rember accepted"
  (run 1 (q)
    (follower q
      (type-ofo/d rember-tyenv
        '(match l ['() l] [(cons a d) (if (= a e) d (cons a (rember e d)))])
        'list)))
  '(_.0))

;; ACCEPT: canonical append body type-checks at list.
(test "type-ofo/d: canonical append accepted"
  (run 1 (q)
    (follower q
      (type-ofo/d append-tyenv
        '(match l ['() s] [(cons a d) (cons a (append d s))])
        'list)))
  '(_.0))

;; REFUTE (ground): (rember e a) -- `a` is a number (list head) passed at the
;; list argument position.  Rung 2 accepts this; the type view refutes it.
(test "type-ofo/d: (rember e a) at list position refuted"
  (run 1 (q)
    (follower q
      (type-ofo/d rember-tyenv
        '(match l ['() l] [(cons a d) (rember e a)])
        'list)))
  '())

;; REFUTE (ground): (cons l l) as the whole body -- `l` (a list) at the number
;; position of cons.
(test "type-ofo/d: (cons l l) refuted"
  (run 1 (q)
    (follower q
      (type-ofo/d rember-tyenv '(cons l l) 'list)))
  '())

;; STALL: holey match arms -- cannot decide, must leave the holes unbound.
(test "type-ofo/d: holey match stalls, holes unbound"
  (run 1 (h1 h2)
    (follower (list h1 h2)
      (type-ofo/d rember-tyenv
        `(match l ['() ,h1] [(cons a d) ,h2])
        'list)))
  '((_.0 _.1)))

;; STALL: bare hole is undetermined.
(test "type-ofo/d: bare hole stalls"
  (run 1 (q)
    (follower q (type-ofo/d rember-tyenv q 'list)))
  '(_.0))

;; === NV: non-vacuous-testso/d --- rung 4a: non-vacuous test conditions.
;;
;; Motivation (see
;; claude/2026-07-12-201800-duplicate-task-and-postviews-spotcheck.md, post-
;; views spot check): ~33% of the rember stream surviving rungs 1-3 is
;; `(if (= X X) then else)` with syntactically identical `=` arguments -- the
;; else-branch is dead code, so the candidate is semantically equivalent to
;; its own then-branch, which size-ordered search already enumerated at a
;; strictly smaller size.  Refusing these is therefore a CANONICITY
;; restriction (it never discards the minimal answer to any task), not a
;; semantic one: no real solution needs a vacuous `(= X X)` test.
;;
;;   (non-vacuous-testso/d body)
;;     succeeds  iff  every `(if (= c1 c2) ...)` node anywhere in `body` has
;;                    c1, c2 syntactically DISTINCT as program text
;;     fails     iff  some committed `(if (= c1 c2) ...)` node has c1
;;                    identical to c2 as program text
;;     stalls         while some relevant condition position is too holey to
;;                    decide
;;
;; Unlike rung 1 (`base-case-patho/d`), this is NOT a path predicate -- it is
;; a for-ALL over every if-node in the whole term, dead or live.  So there is
;; no path-OR anywhere here: recursion into every subterm (both if-branches,
;; the match scrutinee and both branches, every cons/application child) is
;; plain conjunction.
;;
;; The per-if check, `distinct-texto/d`, is the stall-friendly identity test
;; also used elsewhere in this ladder's design discussions: while either side
;; is a hole, BOTH the "identical" and "distinct" clauses stay live -> stall.
;; This is correct: `(= _.0 e)` must NOT be refuted early merely because _.0
;; is not YET known to differ from `e` -- _.0 may still commit to `e` itself
;; (vacuous, refute) or to something else (fine).  Once both sides are ground
;; program text, ==/d on ground text coincides exactly with syntactic
;; identity, so exactly one clause survives:
;;
;;   (define (distinct-texto/d c1 c2)
;;     (conde/d
;;       ([] [(==/d c1 c2)] [fail/d-goal])   ; committed-identical -> refute
;;       ([] [(=/=/d c1 c2)] [])))            ; committed-distinct -> ok
;;
;; --- deliberate search-space restrictions (documented, like rungs 1-3) ---
;;
;;  * RECOGNIZED-CONSTRUCTS-ONLY, exactly as rung 3: an unrecognized body
;;    shape (nested letrec, a non-'() quote literal, ...) is REFUTED rather
;;    than accepted-without-constraint, to avoid a catch-all clause that
;;    would make every term stall.  Not exercised on these benchmarks'
;;    answers.
;;
;;  * No fname/no-shadowing machinery here: this view carries no by-name
;;    environment (unlike rungs 2 and 3), so match pattern vars need no
;;    disequality guards -- there is nothing they could corrupt.


;; ------------------------------------------------------------------
;; distinct-texto/d: the per-if-node check.  See file header.
;; ------------------------------------------------------------------
(define (distinct-texto/d c1 c2)
  (conde/d
    ([]
     [(==/d c1 c2)]
     [fail/d-goal])
    ([]
     [(=/=/d c1 c2)]
     [])))

;; ------------------------------------------------------------------
;; AND over an argument/operand list: every rand must itself be free of
;; vacuous tests (no path logic -- a for-all over the whole subterm).
;; ------------------------------------------------------------------
(define (rands-non-vacuouso/d rands)
  (conde/d
    ([]
     [(==/d '() rands)]
     [])
    ([a d]
     [(==/d `(,a . ,d) rands)]
     [(non-vacuous-testso/d a) (rands-non-vacuouso/d d)])))

;; ------------------------------------------------------------------
;; the public relation: the whole-term walk.
;; ------------------------------------------------------------------
(define (non-vacuous-testso/d body)
  (conde/d
    ;; number literal -- no if-nodes
    ([]
     [(numbero/d body)]
     [])
    ;; variable reference -- no if-nodes
    ([]
     [(symbolo/d body)]
     [])
    ;; '() literal
    ([]
     [(==/d '(quote ()) body)]
     [])
    ;; (cons e1 e2): recurse into both children (AND)
    ([e1 e2]
     [(==/d `(cons ,e1 ,e2) body)]
     [(non-vacuous-testso/d e1) (non-vacuous-testso/d e2)])
    ;; (if (= e1 e2) e3 e4): e1, e2 must be distinct text at THIS node, AND
    ;; recurse into all four subterms (an if can nest inside a condition or
    ;; either branch, dead or not -- this is a for-all, no reachability
    ;; filtering).
    ([e1 e2 e3 e4]
     [(==/d `(if (= ,e1 ,e2) ,e3 ,e4) body)]
     [(distinct-texto/d e1 e2)
      (non-vacuous-testso/d e1)
      (non-vacuous-testso/d e2)
      (non-vacuous-testso/d e3)
      (non-vacuous-testso/d e4)])
    ;; (match e ['() e1] [(cons x y) e2]): recurse into the scrutinee and
    ;; both branches.  No shadowing restriction needed -- this view keeps no
    ;; by-name environment for a pattern var to corrupt.
    ([e e1 x y e2]
     [(==/d `(match ,e ['() ,e1] [(cons ,x ,y) ,e2]) body)
      (symbolo/d x)
      (symbolo/d y)]
     [(non-vacuous-testso/d e)
      (non-vacuous-testso/d e1)
      (non-vacuous-testso/d e2)])
    ;; application (rator rand ...): recurse into the operands only (rator is
    ;; not itself a term that can contain an if-node in this language).
    ([rator rands]
     [(==/d `(,rator . ,rands) body)
      (symbolo/d rator)
      (absento/d rator view-app-keywords)]
     [(rands-non-vacuouso/d rands)])))

;;; ------------------------------------------------------------------
;;; Validation gates.  Run when this file is loaded (./run.sh loads it).
;;; ------------------------------------------------------------------

;; REFUTE (ground): (if (= e e) l l) -- identical condition arguments.
(test "non-vacuous-testso/d: (if (= e e) l l) refuted"
  (run 1 (q)
    (follower q (non-vacuous-testso/d '(if (= e e) l l))))
  '())

;; REFUTE (ground condition, hole elsewhere): the if-node's condition is
;; committed-identical (2 = 2) even though the else-branch is still a hole --
;; refutation must not wait on unrelated holes elsewhere in the term.
(test "non-vacuous-testso/d: match with (if (= 2 2) d _.h) refuted"
  (run 1 (h)
    (follower h
      (non-vacuous-testso/d
        `(match l ['() l] [(cons a d) (if (= 2 2) d ,h)]))))
  '())

;; ACCEPT: canonical rember body (ground, distinct symbols a/e in test
;; position).
(test "non-vacuous-testso/d: canonical rember body accepted"
  (run 1 (q)
    (follower q
      (non-vacuous-testso/d
        '(match l ['() l] [(cons a d) (if (= a e) d (cons a (rember e d)))]))))
  '(_.0))

;; STALL: (if (= h1 e) l l) with h1 a fresh hole -- must NOT refute, and must
;; leave h1 unbound (h1 could still commit to something other than `e`).
(test "non-vacuous-testso/d: (if (= h1 e) l l) with fresh h1 stalls"
  (run 1 (h1)
    (follower h1 (non-vacuous-testso/d `(if (= ,h1 e) l l))))
  '(_.0))

;; STALL: holey match arms -- cannot decide, must leave the holes unbound.
(test "non-vacuous-testso/d: holey match stalls, holes unbound"
  (run 1 (h1 h2)
    (follower (list h1 h2)
      (non-vacuous-testso/d `(match l ['() ,h1] [(cons a d) ,h2]))))
  '((_.0 _.1)))

;; STALL: bare hole is undetermined.
(test "non-vacuous-testso/d: bare hole stalls"
  (run 1 (q)
    (follower q (non-vacuous-testso/d q)))
  '(_.0))
