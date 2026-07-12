;; termination-view4.scm --- rung 4a: non-vacuous test conditions.
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

(load "experiments/termination-view3.scm") ; brings fail/d-goal,
                                            ; termination-view-app-keywords,
                                            ; and rungs 1-3

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
      (absento/d rator termination-view-app-keywords)]
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
