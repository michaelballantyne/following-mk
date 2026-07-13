;; residual.scm --- first-order (residual-goal) representation of the /d search.
;;
;; Design note: claude/2026-07-13-051843-residual-goals-design.md.
;;
;; A suspended follower is a *residual goal*: a goal term whose finished parts
;; are deleted, whose failed parts are pruned, and whose blocked parts sit
;; there as syntax.  Evaluation is `settle`: rewrite a goal against the store
;; as far as determinacy allows.  This replaces the closure engine's four-way
;; `inf/d` stream + resume closures with plain data.
;;
;;   settle : Goal x State x Depth -> #f | (cons residual-Goal State)
;;
;;   #f                         -> the candidate is refuted
;;   (cons TOP st)              -> fully determinate success (TOP = empty conj)
;;   (cons residual st)         -> suspended; residual is a flat conjunction of
;;                                 blocked g-disj nodes (store- or budget-blocked)
;;
;; This file is loaded ALONGSIDE the closure engine (following.scm) during
;; migration, so its surface constructors are prefixed `r` (rconde/d, rfresh/d,
;; r==/d, ...) to avoid clashing.  At cutover they take the canonical names and
;; the closure engine is deleted.
;;
;; NOT YET IMPLEMENTED: the stamp fast path.  The design note's incrementality
;; story (each node carries the store version it last settled against, so an
;; unchanged store is an O(1) pointer comparison instead of a re-settle) is NOT
;; built here.  It is an optimization, orthogonal to decisions, and is deferred
;; to cutover (migration-plan steps 5-6).  Until then EVERY trigger re-settles
;; every residual conjunct from scratch -- correct but not incremental.  Do not
;; read the design note as describing this file's behavior on that point.
;;
;; DEPTH / BUDGET.  Unlike the tentative "budget per g-call" in the design note,
;; depth is counted at g-disj (= one conde/d evaluation), exactly matching the
;; closure engine's `check-suspend-depth` (which wraps each conde/d).  g-call is
;; lazy but *free*: expanding a relation costs no depth, matching fresh/d (which
;; the closure engine also does not charge).  Every relational recursion passes
;; through a g-disj, so this still bounds divergence, and it reproduces the
;; closure engine's suspend accounting for decision-equivalence.  See the
;; migration notebook entry for the measured justification.

;;; ------------------------------------------------------------------
;;; The datatype (all of it)
;;; ------------------------------------------------------------------

;; Leaf: a determinate primitive goal (==, =/=, absento, symbolo, numbero,
;; stringo).  `goal` is the base mk goal (state -> state|#f); `tag`/`args` are
;; kept for printing/provenance only.  A leaf never survives settling.
(define-record-type g-prim (fields tag args goal))

;; Conjunction.  `goals` is a list; '() is TOP (fully determinate success).
(define-record-type g-conj (fields goals))

;; Committed-choice disjunction (NOT a search split): guarded alternatives that
;; wait and commit.  `alts` is a list of g-alt; `name` a source label.
(define-record-type g-disj (fields name alts))

;; One alternative of a g-disj: a guard conjunction and a body conjunction.
;; The guard decides whether the alternative applies (determinacy test); the
;; body is the committed work.  Both are goal nodes (g-conj by construction).
(define-record-type g-alt (fields guard body))

;; The recursion knot: a deferred relation call.  `build` : args-list -> Goal
;; (a static closure -- the pristine generator for the body, capturing nothing
;; dynamic).  `name`/`args` are the schedulable metadata.  A g-call is expanded
;; lazily by settle so that CONSTRUCTING a recursive relation's goal tree
;; terminates.
(define-record-type g-call (fields name build args))

;; A budget-blocked (depth-exceeded) g-disj -- the residual analogue of the
;; closure engine's hard-suspended record.  It wraps the disj it couldn't
;; expand.  The distinction from a bare (store-blocked) g-disj is load-bearing:
;; conj quiescence re-sweeps STORE-blocked leftovers when the store grows, but
;; NEVER re-sweeps budget-blocked ones within a pass (they can't make progress
;; on a store change and re-expanding them each pass diverges) -- exactly
;; conj/d-run's soft-vs-hard worklist split.  A g-blocked is re-attempted only
;; at the next trigger, when depth resets to 0 (fresh budget).
(define-record-type g-blocked (fields disj))

;; TOP, the empty conjunction / fully-determinate success.
(define g-top (make-g-conj '()))
(define (g-top? g) (and (g-conj? g) (null? (g-conj-goals g))))

;;; ------------------------------------------------------------------
;;; settle
;;; ------------------------------------------------------------------

;; settle : Goal State Depth -> #f | (cons residual-conj State)
;; residual-conj is ALWAYS a g-conj (flat pool of blocked disjuncts); TOP on
;; full success.
(define (settle g st depth)
  (cond
    [(g-prim? g) (settle-prim g st)]
    [(g-conj? g) (settle-conj (g-conj-goals g) st depth)]
    [(g-disj? g) (settle-disj g st depth)]
    [(g-call? g) (settle-call g st depth)]
    ;; g-blocked is the TRIGGER-PATH re-attempt only: a budget-blocked disj
    ;; carried in the residual conjunction is re-settled with the current
    ;; (trigger-fresh) budget.  It is NOT reached mid-pass at commit -- the
    ;; commit case seeds g-blocked leftovers into settle-conj's hard pool, which
    ;; never re-settles them within the pass (see settle-disj).
    [(g-blocked? g) (settle-disj (g-blocked-disj g) st depth)]
    [else (error 'settle "not a goal node" g)]))

;; Split a list of flat residual conjuncts into store-blocked (soft, g-disj)
;; and budget-blocked (hard, g-blocked) pools.
(define (partition-blocked nodes)
  (let loop ([nodes nodes] [soft '()] [hard '()])
    (cond
      [(null? nodes) (values (reverse soft) (reverse hard))]
      [(g-blocked? (car nodes)) (loop (cdr nodes) soft (cons (car nodes) hard))]
      [else (loop (cdr nodes) (cons (car nodes) soft) hard)])))

;; A leaf commits into the store or fails; never residual.
(define (settle-prim g st)
  (let ([st^ ((g-prim-goal g) st)])
    (if st^ (cons g-top st^) #f)))

;; A g-call always expands (no depth cost) and settles its body at the same
;; depth.  Recursion is bounded by the g-disj inside the expansion, so a
;; g-call never appears in a residual under this policy.
(define (settle-call g st depth)
  (let ([body ((g-call-build g) (g-call-args g))])
    (settle body st depth)))

;; settle-conj: settle children in order, threading the state, dropping TOPs
;; and splicing each child's residual (a flat conj) into a leftover pool.  #f if
;; any child fails.  After a pass, if the store grew, re-sweep the leftovers
;; (quiescence).  Residual = flat g-conj of the surviving leftovers.
;;
;; soft/hard are the INITIAL leftover pools -- empty for a plain conjunction,
;; but a committing g-disj seeds them with the surviving guard's residual (its
;; store-blocked disjs into soft, budget-blocked into hard) so that guard
;; obligation joins the body's settle in one pass, exactly matching
;; conde/d-runtime's `(conj/d-run sd (list body) c (list f) '())`.
(define settle-conj
  (case-lambda
    [(goals st depth) (settle-conj goals st depth '() '())]
    [(goals st depth soft hard)
     (let pass ([goals goals]
                [st st]
                [soft soft] ; store-blocked leftovers (g-disj); re-swept on change
                [hard hard] ; budget-blocked leftovers (g-blocked); deferred
                [entry-M (subst-map (state-S st))]
                [entry-C (state-C st)])
       (cond
         [(null? goals)
          (let ([changed? (or (not (eq? entry-M (subst-map (state-S st))))
                              (not (eq? entry-C (state-C st))))])
            (if (and (pair? soft) changed?)
                ;; store grew this pass -> re-sweep only the store-blocked
                ;; leftovers; keep the budget-blocked ones aside untouched
                (pass soft st '() hard (subst-map (state-S st)) (state-C st))
                (cons (make-g-conj (append soft hard)) st)))]
         [else
          (let ([r (settle (car goals) st depth)])
            (and r
                 (let-values ([(s h) (partition-blocked (g-conj-goals (car r)))])
                   (pass (cdr goals)
                         (cdr r)
                         (append soft s)
                         (append hard h)
                         entry-M
                         entry-C))))]))]))

;; settle-disj: the committing conde.  Mirrors conde/d-runtime exactly.
;;   depth > *suspend-depth*  -> budget-blocked: leave the whole disj residual
;;                               (hard suspend), state unchanged
;;   else evaluate each alt's guard speculatively from the base store at depth+1:
;;     0 guards apply  -> #f              (refute)
;;     1 guard  applies -> COMMIT: adopt its guard-state, settle the BODY at
;;                         depth+1 with the guard's residual seeded into the
;;                         conj pools (soft store-blocked, hard budget-blocked)
;;                         -- NOT re-settled as goals, so a diverging guard's
;;                         budget-blocked tail is deferred to the next trigger
;;                         instead of being re-expanded here
;;     >=2 guards apply -> stall: leave the whole disj residual, state unchanged
;;                         (re-checked from scratch on the next settle)
(define (settle-disj g st depth)
  (if (> depth (*suspend-depth*))
      (begin
        (increment-counter! *suspend-depth-cutoff-counter*)
        (record-depth-cutoff! (g-disj-name g))
        (cons (make-g-conj (list (make-g-blocked g))) st))
      (let ([d1 (+ depth 1)])
        (increment-counter! *conde/d-counter*)
        (record-depth-entry! (g-disj-name g) depth)
        (let loop ([alts (g-disj-alts g)]
                   [found #f]   ; #f or (list guard-residual guard-state body)
                   [alive '()]) ; surviving alts scanned so far, reversed
          (if (null? alts)
              (if found
                  ;; exactly one alternative applied -> commit.  The body goals
                  ;; settle; the guard's own residual enters the conj pools
                  ;; directly (soft re-swept only if the pass changes the store,
                  ;; hard deferred to the next trigger) -- exactly
                  ;; conde/d-runtime's (conj/d-run sd (list body) c (list f) '()).
                  (let ([guard-residual (car found)]
                        [guard-state (cadr found)]
                        [body (caddr found)])
                    (let-values ([(s h) (partition-blocked
                                         (g-conj-goals guard-residual))])
                      (settle-conj (g-conj-goals body) guard-state d1 s h)))
                  ;; no alternative applied -> refute
                  #f)
              (let ([r (settle (g-alt-guard (car alts)) st d1)])
                (cond
                  ;; guard failed: drop this alt PERMANENTLY.  Failure is
                  ;; monotone -- a guard that fails against this base store fails
                  ;; against every larger one -- so a failed alt is dead for good
                  ;; and never re-enters `alive`.
                  [(not r) (loop (cdr alts) found alive)]
                  [found
                   ;; a second alternative applies -> stall.  Rebuild the disj
                   ;; WITHOUT the alternatives whose guards failed this pass:
                   ;; keep the survivors scanned so far (in `alive`), this second
                   ;; survivor, and the UNSCANNED tail (alts after this one,
                   ;; never tested this pass -- keeping them is required, they
                   ;; may still apply).  Name preserved for the depth tally.
                   ;; Decisions unchanged: a pruned guard would have failed
                   ;; again; only the re-settle/re-trigger work count shrinks.
                   (let ([pruned (make-g-disj
                                  (g-disj-name g)
                                  (append (reverse (cons (car alts) alive))
                                          (cdr alts)))])
                     (cons (make-g-conj (list pruned)) st))]
                  [else
                   (loop (cdr alts)
                         (list (car r) (cdr r) (g-alt-body (car alts)))
                         (cons (car alts) alive))])))))))

;;; ------------------------------------------------------------------
;;; Follower integration
;;;
;;; A residual follower goal plugs into the EXISTING closure-engine follower
;;; machinery (follower / run-and-set-follower / trigger-followers) by matching
;;; the inf/d protocol at the follower-goal boundary: settle, then convert the
;;; result to #f / state / (state . resume).  Each trigger settles from depth 0
;;; (matching the closure engine, where only top-level re-fires refresh depth).
;;; ------------------------------------------------------------------

(define (settle->inf/d G st)
  (let ([r (settle G st 0)])
    (cond
      [(not r) #f]                              ; refuted
      [(g-top? (car r)) (cdr r)]                ; singleton success
      [else
       ;; suspended (soft): check the flatness invariant on every trigger --
       ;; O(residual width), turns the design note's prose invariant into a
       ;; checked property at the one place every live residual passes through.
       (assert-flat-residual! (car r))
       (cons (cdr r) (residual-resume (car r)))])))

;; Resume thunk of the shape conj/d-run / run-and-set-follower expect:
;; (lambda (suspend-depth) (lambda (st) inf/d)).  suspend-depth is ignored --
;; a residual always re-settles from depth 0.
(define (residual-resume resid)
  (lambda (_sd)
    (lambda (st)
      (settle->inf/d resid st))))

;; Wrap a residual goal node G as a /d goal usable with (follower term ...):
;; (lambda (unsound-fail-depth) (lambda (suspend-depth) (lambda (st) inf/d))).
(define (follower-residual-goal G)
  (lambda (_ufd)
    (lambda (_sd)
      (lambda (st)
        (settle->inf/d G st)))))

;;; ------------------------------------------------------------------
;;; Residual surface constructors (prefixed `r` during migration)
;;; ------------------------------------------------------------------

;; Primitive leaves.  ==/d is counted as follower work (==-counted); the rest
;; go through the base constraint goals, which the mk.scm unify counter already
;; attributes to *follower-unify-counter* while *in-follower-eval?* is set.
(define (r==/d u v)      (make-g-prim '== (list u v) (==-counted u v)))
(define (r=/=/d u v)     (make-g-prim '=/= (list u v) (=/= u v)))
(define (rabsento/d u v) (make-g-prim 'absento (list u v) (absento u v)))
(define (rsymbolo/d u)   (make-g-prim 'symbolo (list u) (symbolo u)))
(define (rnumbero/d u)   (make-g-prim 'numbero (list u) (numbero u)))
(define (rstringo/d u)   (make-g-prim 'stringo (list u) (stringo u)))

;; The always-succeed leaf (used by staging base cases): TOP.
(define rsucceed/d g-top)
;; The always-fail leaf: an honest failing primitive (goal returns #f on every
;; state), so settle-prim refutes.
(define rfail/d (make-g-prim 'fail '() (lambda (st) #f)))

;; rfresh/d: allocate fresh vars (at build/expansion time) and return a conj.
;; No runtime fresh node; binders exist only in source.
(define-syntax rfresh/d
  (syntax-rules ()
    [(_ (x ...) g ...)
     (let ([x (var (new-scope))] ...)
       (make-g-conj (list g ...)))]))

;; rconde/d: build a g-disj whose alternatives pair the guard conjunction with
;; the body conjunction.  Clause shape ((x ...) (guard ...) (body ...)) -- the
;; per-repo 3-bracket convention.  Fresh clause vars are shared between guard
;; and body of the same clause.  The source label is computed at expansion time
;; (basename:line, like the closure conde/d) for the depth tally.
(define-syntax (rconde/d stx)
  (syntax-case stx ()
    [(_ ((x ...) (g ...) (b ...)) ...)
     (let ()
       (define (basename p)
         (let loop ([i (- (string-length p) 1)])
           (cond
             [(< i 0) p]
             [(char=? (string-ref p i) #\/) (substring p (+ i 1) (string-length p))]
             [else (loop (- i 1))])))
       (define ann (syntax->annotation stx))
       (define label
         (if ann
             (let* ([src (annotation-source ann)]
                    [sfd (source-object-sfd src)]
                    [path (source-file-descriptor-path sfd)]
                    [bfp (source-object-bfp src)]
                    [loc (call-with-values (lambda () (locate-source sfd bfp #t)) list)])
               (if (>= (length loc) 2)
                   (string-append (basename path) ":" (number->string (cadr loc)))
                   (string-append (basename path) "@" (number->string bfp))))
             "rconde/d?"))
       #`(make-g-disj
          #,label
          (list (let ([x (var (new-scope))] ...)
                  (make-g-alt (make-g-conj (list g ...))
                              (make-g-conj (list b ...))))
                ...)))]))

;; define-relation/d: define a /d relation whose call site returns a g-call
;; (deferred expansion), so recursive relations construct in finite time.  The
;; body constructs the relation's goal tree when expanded.
(define-syntax define-relation/d
  (syntax-rules ()
    [(_ (name arg ...) body0 body ...)
     (define (name arg ...)
       (make-g-call 'name
                    (lambda (args)
                      (apply (lambda (arg ...) body0 body ...) args))
                    (list arg ...)))]))

;;; ------------------------------------------------------------------
;;; Printing / invariant checks (for the differential harness)
;;; ------------------------------------------------------------------

;; Render a residual goal node as an S-expression (printability motivation).
(define (residual->sexp g)
  (cond
    [(g-prim? g) (cons (g-prim-tag g) (g-prim-args g))]
    [(g-conj? g) (cons 'conj (map residual->sexp (g-conj-goals g)))]
    [(g-disj? g) (cons (string->symbol (string-append "disj:" (g-disj-name g)))
                       (map (lambda (a)
                              (list 'alt
                                    (residual->sexp (g-alt-guard a))
                                    (residual->sexp (g-alt-body a))))
                            (g-disj-alts g)))]
    [(g-call? g) (cons (g-call-name g) '(...))]
    [(g-blocked? g) (list 'blocked (residual->sexp (g-blocked-disj g)))]
    [else g]))

;; Assert the flatness invariants of a live residual (design note):
;;   TOP-free, ==-free, constraint-free, conj-free at top level;
;;   only g-disj nodes appear as conjuncts.
(define (assert-flat-residual! resid)
  (unless (g-conj? resid)
    (error 'assert-flat-residual! "residual is not a conj" resid))
  (for-each
   (lambda (c)
     (unless (or (g-disj? c) (g-blocked? c))
       (error 'assert-flat-residual! "non-disj conjunct in residual"
              (residual->sexp c))))
   (g-conj-goals resid)))
