;; residual-views.scm --- residual-goal ("r-form") port of views.scm's follower
;; "view" vocabulary, for the mechanical migration off the closure engine
;; (backlog item 3b).  Names mirror views.scm's, suffixed `-res`; primitives
;; are the `r`-prefixed residual constructors from residual.scm (rconde/d,
;; rfresh/d, r==/d, r=/=/d, rabsento/d, rsymbolo/d, rnumbero/d, rfail/d,
;; define-relation/d).  See views.scm for the closure-engine originals this
;; mirrors line-for-line (comments below are adapted from there -- the
;; SEMANTICS and soundness arguments are engine-agnostic, only the surface
;; syntax changed) and residual.scm's header / claude/2026-07-13-051843-
;; residual-goals-design.md for what a residual goal is.
;;
;; Ported here (backlog 3b): R1 (base-case-patho/d), R2 (decreasing-
;; recursiono/d), R2P (permuted-decreasing-recursiono/d), TY (type-ofo/d), NV
;; (non-vacuous-testso/d).
;;
;; *** R2T (terminating-recursiono/d, built on concluding-oro/d) IS NOT PORTED
;; HERE, DELIBERATELY. *** views.scm's own R2T section header records it
;; NON-VIABLE AS A FOLLOWER VIEW: concluding-oro/d is written directly against
;; the CLOSURE engine's inf/d / case-inf/d / hard-suspended representation (it
;; pattern-matches those constructors to classify each disjunct's outcome), so
;; it has no residual analogue to fall back on -- there is no small syntactic
;; substitution that makes it a residual goal.  Whether some other combinator
;; over TWO residual sub-walks could rescue whole-body R2-OR-R2P termination
;; checking (a single-frontier walk that branches only at the per-self-call
;; measure test, per the R2T section's "forward directions") is an OPEN
;; RESEARCH QUESTION, tracked as backlog item 3c ("does settle's fresh-budget
;; recompute rescue R2T"). That is a from-scratch design question, not a
;; mechanical port, so it is out of scope here and intentionally skipped.
;;
;; A NOTE ON define-relation/d VS PLAIN define BELOW.  r-forms build their
;; whole goal tree EAGERLY except at g-call boundaries (define-relation/d
;; sites): a plain `define`d function that (directly, or through a cycle of
;; sibling helpers) calls itself while walking an actual mk-term whose size
;; isn't known until settle-time will recurse infinitely at CONSTRUCTION time,
;; before any unification ever runs. Every helper below that walks the
;; candidate body's actual (possibly-unbounded, possibly-holey) AST --
;; directly or as part of a mutually-recursive family that does -- is written
;; with define-relation/d, matching the precedent set by tests/residual-
;; engine.scm's existing R1 port (base-case-patho/d-res, patho-oro/d-res,
;; rands-patho/d-res are ALL define-relation/d even though only one of them
;; recurses on itself directly -- the whole family is treated uniformly).
;; Helpers whose only recursion is over a genuine, already-finite HOST Scheme
;; list or a concrete shrinking Scheme integer (member-of/d-style set/tyenv
;; walks, nth-position counters) terminate at construction time regardless of
;; mk-term structure, so they stay plain `define`; a few of these (e.g.
;; nth-rand-decreasing/d-res) are nonetheless given define-relation/d out of
;; caution since it is always safe (never wrong, only adds one deferred
;; expansion) and this is exactly the kind of subtlety instructed to get
;; right rather than shortcut. `family-union` / `all-classified` (R2P) are
;; plain Scheme list functions with no goal in them at all -- ported byte-for-
;; byte unchanged, no r-form needed.

;; Shared "reserved keyword" list precluding rator false-positives, reused
;; across R1/R2/R2P/NV exactly as views.scm's single `view-app-keywords`
;; constant is reused across its sections.
(define view-app-keywords-res '(quote cons letrec match if))

;;; ================================================================
;;; R1: base-case-patho/d-res --- r-form port of views.scm's base-case-patho/d
;;; section (~line 61-178).  See there for the full motivation (caseless
;;; spines diverge on every input; examples can't refute that finitely, a
;;; syntactic "some control path avoids fname" check can) and the documented
;;; search-space restrictions (no-shadowing of fname; non-fname applications
;;; treated as clean-if-args-clean without recursing into the operator; no
;;; letrec clause). Unchanged here -- only the surface primitives moved to
;;; r-forms.
;;;
;;; (Definitions below match tests/residual-engine.scm's existing inline Part
;;; 2 port verbatim; that file now loads them from here instead -- see task 2
;;; of the 3b migration.)
;;; ================================================================

;; Exists a clean path through `ea` OR through `eb` (an OR of two guards
;; that discriminate on whether EACH SIDE has a clean path; both live ->
;; stall, exactly one live -> commit that side, both refute -> refute).
(define-relation/d (patho-oro/d-res fname ea eb)
  (rconde/d
    ([] [(base-case-patho/d-res fname ea)] [])
    ([] [(base-case-patho/d-res fname eb)] [])))

;; AND over an argument list: every rand must itself have a clean path.
(define-relation/d (rands-patho/d-res fname rands)
  (rconde/d
    ([] [(r==/d '() rands)] [])
    ([a d]
     [(r==/d `(,a . ,d) rands)]
     [(base-case-patho/d-res fname a) (rands-patho/d-res fname d)])))

(define-relation/d (base-case-patho/d-res fname body)
  (rconde/d
    ;; number literal -- path-clean
    ([] [(rnumbero/d body)] [])
    ;; variable reference (a bare mention of fname is fine -- it's not a call)
    ([] [(rsymbolo/d body)] [])
    ;; '() literal
    ([] [(r==/d '(quote ()) body)] [])
    ;; (cons e1 e2): both children on the same path -> AND
    ([e1 e2]
     [(r==/d `(cons ,e1 ,e2) body)]
     [(base-case-patho/d-res fname e1) (base-case-patho/d-res fname e2)])
    ;; (if (= e1 e2) e3 e4): condition on every path (AND), branches are
    ;; alternatives (OR).
    ([e1 e2 e3 e4]
     [(r==/d `(if (= ,e1 ,e2) ,e3 ,e4) body)]
     [(base-case-patho/d-res fname e1)
      (base-case-patho/d-res fname e2)
      (patho-oro/d-res fname e3 e4)])
    ;; (match e ['() e1] [(cons x y) e2]): scrutinee on every path (AND),
    ;; branches are alternatives (OR).  No-shadowing on x, y.
    ([e e1 x y e2]
     [(r==/d `(match ,e ['() ,e1] [(cons ,x ,y) ,e2]) body)
      (rsymbolo/d x)
      (rsymbolo/d y)
      (r=/=/d x fname)
      (r=/=/d y fname)]
     [(base-case-patho/d-res fname e) (patho-oro/d-res fname e1 e2)])
    ;; application (rator rand ...): rator a non-keyword symbol =/= fname.
    ;; rator = fname => this clause's guard fails => (with no other clause
    ;; live) the whole conde/d fails => this path is NOT clean.
    ([rator rands]
     [(r==/d `(,rator . ,rands) body)
      (rsymbolo/d rator)
      (r=/=/d rator fname)
      (rabsento/d rator view-app-keywords-res)]
     [(rands-patho/d-res fname rands)])))

;;; ================================================================
;;; R2: decreasing-recursiono/d-res --- r-form port of views.scm's
;;; decreasing-recursiono/d section (~line 224-542).  See there for the
;;; full soundness argument: FIXED position (not any-position, which is
;;; unsound for argument-swapping recursions), strict-descent tracking via
;;; the Scheme-level `sames`/`smallers` sets, holes-stall via conde/d guard
;;; discrimination, for-ALL (not exists) distributed as conjunction, and the
;;; documented search-space restrictions (no-shadowing of fname and every
;;; classified name; non-fname applications recursed-into-operands-only;
;;; types not modelled). Unchanged here -- only the surface primitives moved
;;; to r-forms, and `fail/d-goal` becomes `rfail/d` (residual.scm's existing
;;; always-fail leaf; no need to redefine it).
;;; ================================================================

;; ------------------------------------------------------------------
;; membership tests over a Scheme list of mk-terms (the classified sets).
;; `set`/`forbidden` are genuine, already-finite HOST Scheme lists built by
;; ordinary `cons` as the walk proceeds -- this recursion is bounded at
;; construction time regardless of the candidate body's shape, so these stay
;; plain `define` (see file header).
;; ------------------------------------------------------------------

;; Succeeds iff `a` unifies with exactly one element of `set`; refutes on
;; empty/no-match; stalls only if `a` is holey (never happens at call sites).
(define (member-of/d-res a set)
  (cond
    [(null? set) rfail/d]
    [(null? (cdr set)) (r==/d a (car set))]
    [else
     (rconde/d
       ([] [(r==/d a (car set))] [])
       ([] [(member-of/d-res a (cdr set))] []))]))

;; Succeeds iff `a` differs from every element of `set` (conjunction of =/=).
(define (not-member-of/d-res a set)
  (if (null? set)
      rsucceed/d
      (rfresh/d ()
        (r=/=/d a (car set))
        (not-member-of/d-res a (cdr set)))))

;; ------------------------------------------------------------------
;; is `a` a bare variable classified `smaller`?  (a self-call argument)
;;   succeed iff `a` is a symbol in `smallers`
;;   refute  iff `a` is a determined non-(smaller-var)
;;   stall   iff `a` is a hole
;; Not itself recursive (a leaf over the fixed shape clauses); plain define.
;; ------------------------------------------------------------------
(define (arg-decreasing/d-res a smallers)
  (rconde/d
    ;; a is a symbol -> membership in smallers decides
    ([] [(rsymbolo/d a)] [(member-of/d-res a smallers)])
    ;; a is a number literal -> not a bare var -> refute
    ([] [(rnumbero/d a)] [rfail/d])
    ;; a is '()
    ([] [(r==/d '(quote ()) a)] [rfail/d])
    ;; a is (cons ...)
    ([e1 e2] [(r==/d `(cons ,e1 ,e2) a)] [rfail/d])
    ;; a is (if (= ...) ...)
    ([e1 e2 e3 e4] [(r==/d `(if (= ,e1 ,e2) ,e3 ,e4) a)] [rfail/d])
    ;; a is (match ...)
    ([e f1 x y f2] [(r==/d `(match ,e ['() ,f1] [(cons ,x ,y) ,f2]) a)] [rfail/d])
    ;; a is an application (rator . rands)
    ([rator rands]
     [(r==/d `(,rator . ,rands) a)
      (rsymbolo/d rator)
      (rabsento/d rator view-app-keywords-res)]
     [rfail/d])))

;; ------------------------------------------------------------------
;; the slot-th operand of a self-call must be a `smaller` bare variable.
;; Recursion is bounded by `slot`, a concrete shrinking Scheme integer (the
;; parameter position, <= arity) -- terminates at construction time
;; regardless of `rands`'s actual shape.  Given define-relation/d anyway
;; (always safe; see file header) since it's a genuine member of the R2
;; self-call-checking family.
;; ------------------------------------------------------------------
(define-relation/d (nth-rand-decreasing/d-res rands slot smallers)
  (rconde/d
    ;; too few args: the slot-th operand is absent -> not decreasing -> refute
    ([] [(r==/d '() rands)] [rfail/d])
    ;; (a . d)
    ([a d]
     [(r==/d `(,a . ,d) rands)]
     [(if (= slot 1)
          (arg-decreasing/d-res a smallers)
          (nth-rand-decreasing/d-res d (- slot 1) smallers))])))

;; ------------------------------------------------------------------
;; every operand of an application must itself satisfy all-decreasing
;; (nested self-calls can hide inside operands).  AND over the operand
;; list.  Recurses on itself over the actual (possibly-unbounded, possibly-
;; holey) `rands` mk-term -> define-relation/d required.
;; ------------------------------------------------------------------
(define-relation/d (rands-all-decreasing/d-res fname rands slot sames smallers)
  (rconde/d
    ([] [(r==/d '() rands)] [])
    ([a d]
     [(r==/d `(,a . ,d) rands)]
     [(all-decreasing-at/d-res fname a slot sames smallers)
      (rands-all-decreasing/d-res fname d slot sames smallers)])))

;; ------------------------------------------------------------------
;; no match pattern var may shadow any name in `forbidden`.  Both recursions
;; are over genuine finite Scheme lists (`forbidden`, `vars`) -- bounded at
;; construction time; plain `define`.
;; ------------------------------------------------------------------
(define (all-diseq/d-res v forbidden)
  (if (null? forbidden)
      rsucceed/d
      (rfresh/d ()
        (r=/=/d v (car forbidden))
        (all-diseq/d-res v (cdr forbidden)))))

(define (no-shadow/d-res vars forbidden)
  (if (null? vars)
      rsucceed/d
      (rfresh/d ()
        (all-diseq/d-res (car vars) forbidden)
        (no-shadow/d-res (cdr vars) forbidden))))

;; ------------------------------------------------------------------
;; classify a match's cons-branch pattern vars, then check e2.  Calls back
;; into all-decreasing-at/d-res (already lazy) -- not itself self-recursive,
;; but kept in the define-relation/d family for uniformity with the rest of
;; the R2 AST-walking group (see file header).
;; ------------------------------------------------------------------
(define-relation/d (sym-scrutinee-branch/d-res fname e x y e2 slot sames smallers)
  ;; e is known to be a symbol here; membership in sames U smallers decides.
  (let ([classified (append sames smallers)])
    (rconde/d
      ;; scrutinee is a classified variable -> x,y are strictly smaller
      ([]
       [(member-of/d-res e classified)]
       [(all-decreasing-at/d-res fname e2 slot sames (cons x (cons y smallers)))])
      ;; scrutinee is an unclassified variable -> x,y get no classification
      ([]
       [(not-member-of/d-res e classified)]
       [(all-decreasing-at/d-res fname e2 slot sames smallers)]))))

(define-relation/d (match-branch-decreasing/d-res fname e x y e2 slot sames smallers)
  ;; discriminate on the scrutinee's shape; a hole makes several clauses live
  ;; -> stall.  Only a bare classified variable extends the environment.
  (rconde/d
    ;; scrutinee is a symbol -> defer to membership test
    ([] [(rsymbolo/d e)] [(sym-scrutinee-branch/d-res fname e x y e2 slot sames smallers)])
    ;; scrutinee is a number -> x,y unclassified
    ([] [(rnumbero/d e)] [(all-decreasing-at/d-res fname e2 slot sames smallers)])
    ;; scrutinee is '()
    ([] [(r==/d '(quote ()) e)] [(all-decreasing-at/d-res fname e2 slot sames smallers)])
    ;; scrutinee is (cons ...)
    ([a b] [(r==/d `(cons ,a ,b) e)] [(all-decreasing-at/d-res fname e2 slot sames smallers)])
    ;; scrutinee is (if (= ...) ...)
    ([a b c dd]
     [(r==/d `(if (= ,a ,b) ,c ,dd) e)]
     [(all-decreasing-at/d-res fname e2 slot sames smallers)])
    ;; scrutinee is (match ...)
    ([ee f1 xx yy f2]
     [(r==/d `(match ,ee ['() ,f1] [(cons ,xx ,yy) ,f2]) e)]
     [(all-decreasing-at/d-res fname e2 slot sames smallers)])
    ;; scrutinee is an application
    ([rator rands]
     [(r==/d `(,rator . ,rands) e)
      (rsymbolo/d rator)
      (rabsento/d rator view-app-keywords-res)]
     [(all-decreasing-at/d-res fname e2 slot sames smallers)])))

;; ------------------------------------------------------------------
;; the core walk: EVERY self-call in `body` is decreasing at `slot`, given
;; the environment (sames, smallers).  Conjunction over subterms throughout.
;; Self-recursive on the actual (possibly-unbounded, possibly-holey) `body`
;; mk-term (cons/if clauses) -> define-relation/d required.
;; ------------------------------------------------------------------
(define-relation/d (all-decreasing-at/d-res fname body slot sames smallers)
  (rconde/d
    ;; number literal -- no self-call
    ([] [(rnumbero/d body)] [])
    ;; variable reference -- no self-call
    ([] [(rsymbolo/d body)] [])
    ;; '() literal
    ([] [(r==/d '(quote ()) body)] [])
    ;; (cons e1 e2): both operands (AND)
    ([e1 e2]
     [(r==/d `(cons ,e1 ,e2) body)]
     [(all-decreasing-at/d-res fname e1 slot sames smallers)
      (all-decreasing-at/d-res fname e2 slot sames smallers)])
    ;; (if (= e1 e2) e3 e4): all four subterms (AND -- for-all over self-calls)
    ([e1 e2 e3 e4]
     [(r==/d `(if (= ,e1 ,e2) ,e3 ,e4) body)]
     [(all-decreasing-at/d-res fname e1 slot sames smallers)
      (all-decreasing-at/d-res fname e2 slot sames smallers)
      (all-decreasing-at/d-res fname e3 slot sames smallers)
      (all-decreasing-at/d-res fname e4 slot sames smallers)])
    ;; (match e ['() e1] [(cons x y) e2]): scrutinee AND nil-branch AND
    ;; cons-branch (with possibly-extended environment).  No-shadowing of
    ;; fname and of every classified name.
    ([e e1 x y e2]
     [(r==/d `(match ,e ['() ,e1] [(cons ,x ,y) ,e2]) body)
      (rsymbolo/d x)
      (rsymbolo/d y)
      (no-shadow/d-res (list x y) (cons fname (append sames smallers)))]
     [(all-decreasing-at/d-res fname e slot sames smallers)
      (all-decreasing-at/d-res fname e1 slot sames smallers)
      (match-branch-decreasing/d-res fname e x y e2 slot sames smallers)])
    ;; self-application (fname . rands): slot-th operand must be a smaller
    ;; bare var, AND the operands themselves must be all-decreasing.
    ([rands]
     [(r==/d `(,fname . ,rands) body)]
     [(nth-rand-decreasing/d-res rands slot smallers)
      (rands-all-decreasing/d-res fname rands slot sames smallers)])
    ;; other application (rator . rands), rator =/= fname: recurse into
    ;; operands.
    ([rator rands]
     [(r==/d `(,rator . ,rands) body)
      (rsymbolo/d rator)
      (r=/=/d rator fname)
      (rabsento/d rator view-app-keywords-res)]
     [(rands-all-decreasing/d-res fname rands slot sames smallers)])))

;; ------------------------------------------------------------------
;; the public relation: an OUTER conde/d (rconde/d) over parameter positions,
;; right-nested via ordinary Scheme recursion over the finite `params` list
;; (a genuine host list, arity known at call time) -- not itself part of the
;; body-recursive family, and never called recursively, so plain `define`
;; suffices exactly as views.scm's original.
;;   both positions live  -> stall (sound: some fixed position works)
;;   exactly one live     -> commit
;;   all refuted          -> refute
;; ------------------------------------------------------------------
(define (decreasing-recursiono/d-res fname params body)
  (let loop ([slot 1] [ps params])
    (cond
      [(null? ps) rfail/d] ; no positions -> refute
      [(null? (cdr ps))
       ;; last (or only) position: no disjunction wrapper needed
       (all-decreasing-at/d-res fname body slot (list (car ps)) '())]
      [else
       (rconde/d
         ([] [(all-decreasing-at/d-res fname body slot (list (car ps)) '())] [])
         ([] [(loop (+ slot 1) (cdr ps))] []))])))

;;; ================================================================
;;; R2P: permuted-decreasing-recursiono/d-res --- r-form port of views.scm's
;;; permuted-decreasing-recursiono/d section (~line 616-915).  See there for
;;; the full soundness argument for the injective-assignment / summed-size
;;; measure (why INJECTIVITY is required -- without it, two arguments can
;;; both be charged to the same large parameter and the multiset sum can
;;; GROW even though a naive per-position check holds), and the note that
;;; R2 and R2P are INCOMPARABLE (interleave: R2 refutes, R2P accepts;
;;; rev-acc: R2 accepts, R2P refutes -- see the differential tests in
;;; tests/residual-views.scm). Unchanged here -- only the surface primitives
;;; moved to r-forms; `arg-decreasing/d-res` (R2, above) is reused directly,
;;; matching views.scm's comment that R2P "mirrors R2's machinery."
;;; ================================================================

;; family_j's classified set = sames_j U smallers_j (the "<=" set for p_j).
;; Pure Scheme list function, no goal in it -- ported unchanged, same name.
(define (family-union pset) (append (car pset) (cdr pset)))

;; every classified name across all families (for no-shadowing).  Pure
;; Scheme, ported unchanged, same name.
(define (all-classified psets) (apply append (map family-union psets)))

;; is `a` a bare var equal-to-or-descended-from param p (<=)?  Reuses R2's
;; arg-decreasing/d-res (bare-var membership) against the family's whole <=
;; set.  Leaf (calls only arg-decreasing/d-res); plain define.
(define (arg-le/d-res a pset)
  (arg-decreasing/d-res a (family-union pset)))

;; is `a` a bare var that is a PROPER descendant of p (strict)?  Membership
;; in smallers only.
(define (arg-strict/d-res a pset)
  (arg-decreasing/d-res a (cdr pset)))

;; is `a` a bare var EQUAL to p (same-size, not strict)?  Membership in
;; sames.
(define (arg-same/d-res a pset)
  (arg-decreasing/d-res a (car pset)))

;; a pair of args assigned to a pair of params: aA <= pA, aB <= pB, and at
;; least one strict.  Not self-recursive; plain define.
(define (assign-pair/d-res aA psetA aB psetB)
  (rconde/d
    ([] [(arg-strict/d-res aA psetA)] [(arg-le/d-res aB psetB)])
    ([] [(arg-same/d-res aA psetA)] [(arg-strict/d-res aB psetB)])))

;; the assignment check at a self-call: args (a Scheme list of mk-terms) vs
;; psets (a Scheme list of families), same length.  arity 1: forced
;; identity.  arity 2: an OUTER conde/d over the two injective assignments
;; (identity, swap).  arity > 2: documented error.  Not self-recursive; plain
;; define.
(define (assignment-check/d-res args psets)
  (let ([n (length psets)])
    (cond
      [(= n 1)
       (arg-strict/d-res (car args) (car psets))]
      [(= n 2)
       (let ([a1 (car args)]
             [a2 (cadr args)]
             [p1 (car psets)]
             [p2 (cadr psets)])
         (rconde/d
           ([] ; identity: a1<-p1, a2<-p2
            [(assign-pair/d-res a1 p1 a2 p2)]
            [])
           ([] ; swap: a1<-p2, a2<-p1
            [(assign-pair/d-res a1 p2 a2 p1)]
            [])))]
      [else
       (error 'permuted-decreasing-recursiono/d-res
         "arity > 2 not supported" n)])))

;; destructure `rands` (a possibly-holey mk-list) into EXACTLY n args, then
;; call the Scheme continuation `k` (args-as-Scheme-list -> goal).  Recursion
;; is bounded by `n` = (length psets), a concrete small Scheme integer (arity
;; <= 2 here) -- terminates at construction time regardless of `rands`'s
;; actual shape; plain `define`.
(define (destructure-rands/d-res rands n k)
  (if (= n 0)
      (rconde/d
        ([] [(r==/d '() rands)] [(k '())])
        ([a d] [(r==/d `(,a . ,d) rands)] [rfail/d])) ; extra args
      (rconde/d
        ([] [(r==/d '() rands)] [rfail/d]) ; too few args
        ([a d]
         [(r==/d `(,a . ,d) rands)]
         [(destructure-rands/d-res d (- n 1)
            (lambda (rest) (k (cons a rest))))]))))

;; a self-call (fname . rands): its args must admit a valid injective
;; assignment.  Leaf (calls only destructure-rands/d-res / assignment-check/
;; d-res, not itself); plain define.
(define (self-call-perm/d-res rands psets)
  (destructure-rands/d-res rands (length psets)
    (lambda (args) (assignment-check/d-res args psets))))

;; classify a match's cons-branch pattern vars under the RIGHT family, then
;; check e2.  Calls back into all-decreasing-perm/d-res (already lazy) --
;; kept in the define-relation/d family for uniformity with the rest of the
;; R2P AST-walking group.
(define-relation/d (sym-scrutinee-perm/d-res fname e x y e2 psets)
  (let ([n (length psets)])
    (cond
      [(= n 1)
       (let* ([p0 (car psets)]
              [u0 (family-union p0)]
              [ext0 (list (cons (car p0) (cons x (cons y (cdr p0)))))])
         (rconde/d
           ([] [(member-of/d-res e u0)] [(all-decreasing-perm/d-res fname e2 ext0)])
           ([] [(not-member-of/d-res e u0)] [(all-decreasing-perm/d-res fname e2 psets)])))]
      [(= n 2)
       (let* ([p0 (car psets)]
              [p1 (cadr psets)]
              [u0 (family-union p0)]
              [u1 (family-union p1)]
              [ext0 (list (cons (car p0) (cons x (cons y (cdr p0)))) p1)]
              [ext1 (list p0 (cons (car p1) (cons x (cons y (cdr p1)))))])
         (rconde/d
           ([] [(member-of/d-res e u0)] [(all-decreasing-perm/d-res fname e2 ext0)])
           ([] [(member-of/d-res e u1)] [(all-decreasing-perm/d-res fname e2 ext1)])
           ([]
            [(rfresh/d ()
               (not-member-of/d-res e u0)
               (not-member-of/d-res e u1))]
            [(all-decreasing-perm/d-res fname e2 psets)])))]
      [else
       (error 'permuted-decreasing-recursiono/d-res
         "arity > 2 not supported" n)])))

;; discriminate on a match scrutinee's shape; a hole -> stall.  Only a bare
;; classified variable extends the environment (via sym-scrutinee-perm/d-res).
(define-relation/d (match-branch-perm/d-res fname e x y e2 psets)
  (rconde/d
    ([] [(rsymbolo/d e)] [(sym-scrutinee-perm/d-res fname e x y e2 psets)])
    ([] [(rnumbero/d e)] [(all-decreasing-perm/d-res fname e2 psets)])
    ([] [(r==/d '(quote ()) e)] [(all-decreasing-perm/d-res fname e2 psets)])
    ([a b] [(r==/d `(cons ,a ,b) e)] [(all-decreasing-perm/d-res fname e2 psets)])
    ([a b c dd]
     [(r==/d `(if (= ,a ,b) ,c ,dd) e)]
     [(all-decreasing-perm/d-res fname e2 psets)])
    ([ee f1 xx yy f2]
     [(r==/d `(match ,ee ['() ,f1] [(cons ,xx ,yy) ,f2]) e)]
     [(all-decreasing-perm/d-res fname e2 psets)])
    ([rator rands]
     [(r==/d `(,rator . ,rands) e)
      (rsymbolo/d rator)
      (rabsento/d rator view-app-keywords-res)]
     [(all-decreasing-perm/d-res fname e2 psets)])))

;; every operand of an application must itself satisfy all-decreasing
;; (nested self-calls can hide inside operands).  AND over the operand list.
;; Self-recursive on the actual `rands` mk-term -> define-relation/d
;; required.
(define-relation/d (rands-all-perm/d-res fname rands psets)
  (rconde/d
    ([] [(r==/d '() rands)] [])
    ([a d]
     [(r==/d `(,a . ,d) rands)]
     [(all-decreasing-perm/d-res fname a psets)
      (rands-all-perm/d-res fname d psets)])))

;; the core walk: EVERY self-call in `body` is permuted-decreasing, given the
;; per-parameter environment `psets`.  Conjunction over subterms throughout
;; (for-ALL over self-calls, so no path-OR).  Self-recursive on the actual
;; `body` mk-term (cons/if clauses) -> define-relation/d required.
(define-relation/d (all-decreasing-perm/d-res fname body psets)
  (rconde/d
    ;; number literal -- no self-call
    ([] [(rnumbero/d body)] [])
    ;; variable reference -- no self-call
    ([] [(rsymbolo/d body)] [])
    ;; '() literal
    ([] [(r==/d '(quote ()) body)] [])
    ;; (cons e1 e2): both operands (AND)
    ([e1 e2]
     [(r==/d `(cons ,e1 ,e2) body)]
     [(all-decreasing-perm/d-res fname e1 psets)
      (all-decreasing-perm/d-res fname e2 psets)])
    ;; (if (= e1 e2) e3 e4): all four subterms (AND)
    ([e1 e2 e3 e4]
     [(r==/d `(if (= ,e1 ,e2) ,e3 ,e4) body)]
     [(all-decreasing-perm/d-res fname e1 psets)
      (all-decreasing-perm/d-res fname e2 psets)
      (all-decreasing-perm/d-res fname e3 psets)
      (all-decreasing-perm/d-res fname e4 psets)])
    ;; (match e ['() e1] [(cons x y) e2]): scrutinee AND nil-branch AND
    ;; cons-branch (with possibly-extended env).  No-shadowing of fname and
    ;; of every classified name.
    ([e e1 x y e2]
     [(r==/d `(match ,e ['() ,e1] [(cons ,x ,y) ,e2]) body)
      (rsymbolo/d x)
      (rsymbolo/d y)
      (no-shadow/d-res (list x y) (cons fname (all-classified psets)))]
     [(all-decreasing-perm/d-res fname e psets)
      (all-decreasing-perm/d-res fname e1 psets)
      (match-branch-perm/d-res fname e x y e2 psets)])
    ;; self-application (fname . rands): args must admit a valid injective
    ;; assignment, AND the operands themselves must be all-decreasing.
    ([rands]
     [(r==/d `(,fname . ,rands) body)]
     [(self-call-perm/d-res rands psets)
      (rands-all-perm/d-res fname rands psets)])
    ;; other application (rator . rands), rator =/= fname: recurse into
    ;; operands.
    ([rator rands]
     [(r==/d `(,rator . ,rands) body)
      (rsymbolo/d rator)
      (r=/=/d rator fname)
      (rabsento/d rator view-app-keywords-res)]
     [(rands-all-perm/d-res fname rands psets)])))

;; the public relation.  Initialize psets: each parameter p_j starts in its
;; own sames_j = (p_j), smallers_j = ().  arity > 2 -> documented error.
;; Never called recursively; plain `define`, exactly like views.scm's
;; original.
(define (permuted-decreasing-recursiono/d-res fname params body)
  (if (> (length params) 2)
      (error 'permuted-decreasing-recursiono/d-res
        "arity > 2 not supported" (length params))
      (all-decreasing-perm/d-res fname body
        (map (lambda (p) (cons (list p) '())) params))))

;;; ================================================================
;;; TY: type-ofo/d-res --- r-form port of views.scm's type-ofo/d section
;;; (~line 1251-1440).  See there for the full motivation (rung 2 doesn't
;;; model types -- e.g. it accepts (rember e a) where `a` is a number
;;; standing in the list position -- this view refutes such bodies
;;; syntactically) and the documented search-space restrictions
;;; (RECOGNIZED-CONSTRUCTS-ONLY: an unrecognized body shape is REFUTED rather
;;; than accepted-without-constraint, to avoid a stall-everything catch-all
;;; clause; no-shadowing against tyenv names; only the (quote ()) literal is
;;; typed). Unchanged here -- only the surface primitives moved to r-forms.
;;; `rember-tyenv` / `append-tyenv` are plain Scheme data (assoc lists),
;;; ported byte-for-byte; `duplicate-tyenv` is NOT defined in views.scm
;;; itself (only in experiments/duplicate-untyped-id-ty.scm, out of scope
;;; here per the task), so it is intentionally not ported.
;;; ================================================================

(define type-view-app-keywords-res view-app-keywords-res) ; '(quote cons letrec match if)

;; ------------------------------------------------------------------
;; look up `name`'s type in the Scheme-level `tyenv`.  Recursion is over a
;; genuine, already-finite HOST assoc list -- bounded at construction time
;; regardless of the candidate's shape; plain `define`, as a nested rconde/d
;; that discriminates by r==/d / r=/=/d on the name (a HOLE name makes both
;; clauses live -> stall; a committed name leaves one live).  An exhausted
;; tyenv (name not found) -> refute (unbound reference is ill-typed).
;; ------------------------------------------------------------------
(define (tyenv-lookupo/d-res tyenv name type)
  (if (null? tyenv)
      rfail/d
      (let ([n (car (car tyenv))]
            [t (cdr (car tyenv))])
        (rconde/d
          ([] [(r==/d name n)] [(r==/d type t)])
          ([] [(r=/=/d name n)] [(tyenv-lookupo/d-res (cdr tyenv) name type)])))))

;; ------------------------------------------------------------------
;; type each operand of an application at its declared argument type.  The
;; rands come from the (holey) body; the argtypes come from the (ground)
;; arrow type looked up for the operator.  AND over the two lists walked
;; together.  Self-recursive (and mutually recursive with type-ofo/d-res)
;; over the actual `rands`/`argtypes` mk-terms -> define-relation/d
;; required.
;; ------------------------------------------------------------------
(define-relation/d (types-listo/d-res tyenv rands argtypes)
  (rconde/d
    ([] [(r==/d '() rands) (r==/d '() argtypes)] [])
    ([a d ta td]
     [(r==/d `(,a . ,d) rands) (r==/d `(,ta . ,td) argtypes)]
     [(type-ofo/d-res tyenv a ta) (types-listo/d-res tyenv d td)])))

;; ------------------------------------------------------------------
;; the public relation.  Self-recursive on the actual `body` mk-term (cons/
;; if/match clauses) -> define-relation/d required.
;; ------------------------------------------------------------------
(define-relation/d (type-ofo/d-res tyenv body type)
  (rconde/d
    ;; number literal : number
    ([] [(rnumbero/d body)] [(r==/d type 'number)])
    ;; variable reference : whatever tyenv says
    ([] [(rsymbolo/d body)] [(tyenv-lookupo/d-res tyenv body type)])
    ;; '() : list
    ([] [(r==/d '(quote ()) body)] [(r==/d type 'list)])
    ;; (cons e1 e2) : list, with e1 : number and e2 : list
    ([e1 e2]
     [(r==/d `(cons ,e1 ,e2) body)]
     [(r==/d type 'list)
      (type-ofo/d-res tyenv e1 'number)
      (type-ofo/d-res tyenv e2 'list)])
    ;; (match e ['() e1] [(cons x y) e2]) : e : list; e1 : T; e2 : T with
    ;; x : number, y : list added to tyenv.  No-shadowing on x, y.
    ([e e1 x y e2]
     [(r==/d `(match ,e ['() ,e1] [(cons ,x ,y) ,e2]) body)
      (rsymbolo/d x)
      (rsymbolo/d y)
      (no-shadow/d-res (list x y) (map car tyenv))]
     [(type-ofo/d-res tyenv e 'list)
      (type-ofo/d-res tyenv e1 type)
      (type-ofo/d-res (cons (cons x 'number) (cons (cons y 'list) tyenv)) e2 type)])
    ;; (if (= e1 e2) e3 e4) : e1,e2 : number; e3,e4 : T
    ([e1 e2 e3 e4]
     [(r==/d `(if (= ,e1 ,e2) ,e3 ,e4) body)]
     [(type-ofo/d-res tyenv e1 'number)
      (type-ofo/d-res tyenv e2 'number)
      (type-ofo/d-res tyenv e3 type)
      (type-ofo/d-res tyenv e4 type)])
    ;; application (rator rand ...): rator's arrow type ((t1 ... tn) -> tr)
    ;; is looked up in tyenv; result type = tr, each rand at its declared ti.
    ([rator rands ftype argtypes tr]
     [(r==/d `(,rator . ,rands) body)
      (rsymbolo/d rator)
      (rabsento/d rator type-view-app-keywords-res)]
     [(tyenv-lookupo/d-res tyenv rator ftype)
      (r==/d `(,argtypes -> ,tr) ftype)
      (r==/d type tr)
      (types-listo/d-res tyenv rands argtypes)])))

;; Plain Scheme data (identical to views.scm's) so tests/residual-views.scm
;; can drive the TY gates without also loading views.scm.
(define rember-tyenv '((rember . ((number list) -> list)) (e . number) (l . list)))
(define append-tyenv '((append . ((list list) -> list)) (l . list) (s . list)))

;;; ================================================================
;;; NV: non-vacuous-testso/d-res --- r-form port of views.scm's
;;; non-vacuous-testso/d section (~line 1441-1616).  See there for the full
;;; motivation (a CANONICITY restriction: `(if (= X X) then else)` with
;;; syntactically identical `=` arguments is refused because the else-branch
;;; is dead code and size-ordered search already enumerated the equivalent,
;;; strictly smaller then-branch) and the note that this is a for-ALL over
;;; every if-node in the whole term (dead or live), not a path predicate, so
;;; there is no path-OR anywhere -- plain conjunction throughout. Unchanged
;;; here -- only the surface primitives moved to r-forms.
;;; ================================================================

;; ------------------------------------------------------------------
;; distinct-texto/d-res: the per-if-node check.  Not recursive at all (a
;; fixed two-clause discrimination on ground-vs-holey c1/c2); plain define.
;; While either side is a hole, BOTH clauses stay live -> stall (`(= _.0 e)`
;; must not be refuted early -- _.0 may still commit to something other than
;; `e`).  Once both sides are ground program text, r==/d on ground text
;; coincides exactly with syntactic identity, so exactly one clause
;; survives.
;; ------------------------------------------------------------------
(define (distinct-texto/d-res c1 c2)
  (rconde/d
    ([] [(r==/d c1 c2)] [rfail/d])   ; committed-identical -> refute
    ([] [(r=/=/d c1 c2)] [])))       ; committed-distinct -> ok

;; ------------------------------------------------------------------
;; AND over an argument/operand list: every rand must itself be free of
;; vacuous tests (no path logic -- a for-all over the whole subterm).
;; Self-recursive (and mutually recursive with non-vacuous-testso/d-res) on
;; the actual `rands` mk-term -> define-relation/d required.
;; ------------------------------------------------------------------
(define-relation/d (rands-non-vacuouso/d-res rands)
  (rconde/d
    ([] [(r==/d '() rands)] [])
    ([a d]
     [(r==/d `(,a . ,d) rands)]
     [(non-vacuous-testso/d-res a) (rands-non-vacuouso/d-res d)])))

;; ------------------------------------------------------------------
;; the public relation: the whole-term walk.  Self-recursive on the actual
;; `body` mk-term (cons/if/match clauses) -> define-relation/d required.
;; ------------------------------------------------------------------
(define-relation/d (non-vacuous-testso/d-res body)
  (rconde/d
    ;; number literal -- no if-nodes
    ([] [(rnumbero/d body)] [])
    ;; variable reference -- no if-nodes
    ([] [(rsymbolo/d body)] [])
    ;; '() literal
    ([] [(r==/d '(quote ()) body)] [])
    ;; (cons e1 e2): recurse into both children (AND)
    ([e1 e2]
     [(r==/d `(cons ,e1 ,e2) body)]
     [(non-vacuous-testso/d-res e1) (non-vacuous-testso/d-res e2)])
    ;; (if (= e1 e2) e3 e4): e1, e2 must be distinct text at THIS node, AND
    ;; recurse into all four subterms (an if can nest inside a condition or
    ;; either branch, dead or not -- this is a for-all, no reachability
    ;; filtering).
    ([e1 e2 e3 e4]
     [(r==/d `(if (= ,e1 ,e2) ,e3 ,e4) body)]
     [(distinct-texto/d-res e1 e2)
      (non-vacuous-testso/d-res e1)
      (non-vacuous-testso/d-res e2)
      (non-vacuous-testso/d-res e3)
      (non-vacuous-testso/d-res e4)])
    ;; (match e ['() e1] [(cons x y) e2]): recurse into the scrutinee and
    ;; both branches.  No shadowing restriction needed -- this view keeps no
    ;; by-name environment for a pattern var to corrupt.
    ([e e1 x y e2]
     [(r==/d `(match ,e ['() ,e1] [(cons ,x ,y) ,e2]) body)
      (rsymbolo/d x)
      (rsymbolo/d y)]
     [(non-vacuous-testso/d-res e)
      (non-vacuous-testso/d-res e1)
      (non-vacuous-testso/d-res e2)])
    ;; application (rator rand ...): recurse into the operands only (rator
    ;; is not itself a term that can contain an if-node in this language).
    ([rator rands]
     [(r==/d `(,rator . ,rands) body)
      (rsymbolo/d rator)
      (rabsento/d rator view-app-keywords-res)]
     [(rands-non-vacuouso/d-res rands)])))
