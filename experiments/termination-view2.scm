;; termination-view2.scm --- rung 2 of the termination ladder:
;; structurally-decreasing recursion, as a /d constraint that runs inside a
;; follower.
;;
;; Rung 1 (`base-case-patho/d`, experiments/termination-view.scm) refutes
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

(load "experiments/termination-view.scm") ; for termination-view-app-keywords

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
      (absento/d rator termination-view-app-keywords)]
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
      (absento/d rator termination-view-app-keywords)]
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
      (absento/d rator termination-view-app-keywords)]
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
