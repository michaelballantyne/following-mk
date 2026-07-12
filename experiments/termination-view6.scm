;; termination-view6.scm --- rung 4c: non-vacuous BRANCHES.
;;
;; Motivation (see claude/2026-07-12-201800-duplicate-task-and-postviews-
;; spotcheck.md and the post-4a residue description in
;; claude/2026-07-12-204500-examples-earn-after-cleanup.md, the F8/"~11%"
;; family): after rungs 1-4a+4b+examples, the rember stream still has a
;; family of candidates like `(if (= _.0 e) _.0 e)` or `(if (= _.0 e) X X)`:
;; UNDER THE CONDITION'S TRUTH (c1 = c2), the two branches denote the same
;; value, so the conditional is a no-op -- the candidate is behaviorally
;; identical to a strictly smaller candidate already enumerated (the if
;; stripped out). These pass the examples view (they are semantically
;; correct, just non-minimal); only a SYNTACTIC check can remove them, so
;; this is a canonicity restriction in the same family as rung 4a, not a
;; semantic one.
;;
;;   (non-vacuous-brancheso/d body)
;;     succeeds  iff  every `(if (= c1 c2) t e)` node anywhere in `body` has
;;                    NOT-vacuous branches (see below)
;;     fails     iff  some committed `(if (= c1 c2) t e)` node has vacuous
;;                    branches
;;     stalls         while some relevant position is too holey to decide
;;
;; Like rung 4a (and unlike rung 1), this is a for-ALL over every if-node in
;; the whole term, dead or live -- plain conjunction throughout, no path-OR.
;;
;; "Vacuous branches" at an `(if (= c1 c2) t e)` node means EITHER:
;;   (i)  t and e are identical program text -- the if is a no-op regardless
;;        of the condition's truth value; or
;;   (ii) {t, e} = {c1, c2} as program text, i.e. (t=c1 AND e=c2) OR
;;        (t=c2 AND e=c1) -- under the condition c1=c2, whichever branch
;;        commits, the returned value is (one of) c1/c2 either way, so the
;;        if again contributes nothing a smaller term couldn't.
;;
;; NOT(i) is exactly rung 4a's `distinct-texto/d t e`.
;;
;; NOT(ii) is "not both-match": we must FAIL when (t==c1 AND e==c2), and
;; FAIL when (t==c2 AND e==c1); stall while undetermined; succeed otherwise.
;; Encoded as an AND of two ORs, each OR itself a 2-clause conde/d exactly
;; like `patho-oro/d` (termination-view.scm): both disjuncts refute -> the
;; conde/d has no live clause -> refute; exactly one disjunct is
;; (dis)provably true -> commit it; both live -> nondeterministic -> stall.
;;   NOT(t==c1 AND e==c2)  =  (distinct t c1) OR (distinct e c2)
;;   NOT(t==c2 AND e==c1)  =  (distinct t c2) OR (distinct e c1)
;; ANDing the two ORs (via conj/d*, which is exactly plain conjunction of
;; already-built /d goals -- used standalone the same way fresh/d uses it
;; internally) gives NOT(ii). See the file-header discussion in
;; termination-view.scm for why the "both fail / one live / both live"
;; conde/d shape has the right stall discipline; the four-test gate suite at
;; the bottom of this file re-verifies it concretely on the new (t, e, c1,
;; c2) shape rather than trusting the analogy.
;;
;; --- deliberate search-space restrictions ---
;; Same two as rung 4a (RECOGNIZED-CONSTRUCTS-ONLY; no fname/no-shadowing
;; machinery needed -- this view carries no by-name environment).

(load "experiments/termination-view4.scm") ; brings fail/d-goal,
                                            ; termination-view-app-keywords,
                                            ; distinct-texto/d, and rungs 1-4a

;; ------------------------------------------------------------------
;; oro/d: plain two-way OR of two already-built /d goals, patho-oro/d style
;; (termination-view.scm): both guards fail -> conde/d fails (REFUTE);
;; exactly one guard live -> commit it (ACCEPT); both live -> stall.
;; ------------------------------------------------------------------
(define (oro/d g1 g2)
  (conde/d
    ([]
     [g1]
     [])
    ([]
     [g2]
     [])))

;; ------------------------------------------------------------------
;; pair-not-equal/d: NOT(ii) -- refute iff {t,e} = {c1,c2} as program text.
;; ------------------------------------------------------------------
(define (pair-not-equal/d t e c1 c2)
  (conj/d*
    (oro/d (distinct-texto/d t c1) (distinct-texto/d e c2))
    (oro/d (distinct-texto/d t c2) (distinct-texto/d e c1))))

;; ------------------------------------------------------------------
;; non-vacuous-brancho/d: the per-if-node check -- NOT(i) AND NOT(ii).
;; ------------------------------------------------------------------
(define (non-vacuous-brancho/d t e c1 c2)
  (conj/d*
    (distinct-texto/d t e)
    (pair-not-equal/d t e c1 c2)))

;; ------------------------------------------------------------------
;; AND over an argument/operand list (mirrors rands-non-vacuouso/d in tv4).
;; ------------------------------------------------------------------
(define (rands-non-vacuous-brancheso/d rands)
  (conde/d
    ([]
     [(==/d '() rands)]
     [])
    ([a d]
     [(==/d `(,a . ,d) rands)]
     [(non-vacuous-brancheso/d a) (rands-non-vacuous-brancheso/d d)])))

;; ------------------------------------------------------------------
;; the public relation: the whole-term walk (same clause structure as
;; non-vacuous-testso/d in termination-view4.scm).
;; ------------------------------------------------------------------
(define (non-vacuous-brancheso/d body)
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
     [(non-vacuous-brancheso/d e1) (non-vacuous-brancheso/d e2)])
    ;; (if (= e1 e2) e3 e4): the branches e3, e4 must not be vacuous w.r.t.
    ;; the condition sides e1, e2 at THIS node, AND recurse into all four
    ;; subterms (an if can nest inside a condition or either branch, dead or
    ;; not -- this is a for-all, no reachability filtering).
    ([e1 e2 e3 e4]
     [(==/d `(if (= ,e1 ,e2) ,e3 ,e4) body)]
     [(non-vacuous-brancho/d e3 e4 e1 e2)
      (non-vacuous-brancheso/d e1)
      (non-vacuous-brancheso/d e2)
      (non-vacuous-brancheso/d e3)
      (non-vacuous-brancheso/d e4)])
    ;; (match e ['() e1] [(cons x y) e2]): recurse into the scrutinee and
    ;; both branches. No shadowing restriction needed (as tv4).
    ([e e1 x y e2]
     [(==/d `(match ,e ['() ,e1] [(cons ,x ,y) ,e2]) body)
      (symbolo/d x)
      (symbolo/d y)]
     [(non-vacuous-brancheso/d e)
      (non-vacuous-brancheso/d e1)
      (non-vacuous-brancheso/d e2)])
    ;; application (rator rand ...): recurse into the operands only.
    ([rator rands]
     [(==/d `(,rator . ,rands) body)
      (symbolo/d rator)
      (absento/d rator termination-view-app-keywords)]
     [(rands-non-vacuous-brancheso/d rands)])))

;;; ------------------------------------------------------------------
;;; Validation gates. Run when this file is loaded (./run.sh loads it).
;;; ------------------------------------------------------------------

;; REFUTE (ground, family ii, t=c1 e=c2): (if (= a e) a e), as a subterm of a
;; match-skeleton body -- under a=e, both branches equal a (or e) either way.
(test "non-vacuous-brancheso/d: (if (= a e) a e) refuted (family ii, t=c1/e=c2)"
  (run 1 (q)
    (follower q
      (non-vacuous-brancheso/d
        '(match l ['() l] [(cons a d) (if (= a e) a e)]))))
  '())

;; REFUTE (ground, family i, identical branches): (if (= a e) d d).
(test "non-vacuous-brancheso/d: (if (= a e) d d) refuted (family i, identical branches)"
  (run 1 (q)
    (follower q
      (non-vacuous-brancheso/d
        '(match l ['() l] [(cons a d) (if (= a e) d d)]))))
  '())

;; REFUTE (ground, family ii swapped, t=c2 e=c1): (if (= a e) e a).
(test "non-vacuous-brancheso/d: (if (= a e) e a) refuted (family ii, t=c2/e=c1)"
  (run 1 (q)
    (follower q
      (non-vacuous-brancheso/d
        '(match l ['() l] [(cons a d) (if (= a e) e a)]))))
  '())

;; ACCEPT: canonical rember body -- branches d and (cons a (rember e d)) are
;; distinct from each other and from both condition sides a, e.
(test "non-vacuous-brancheso/d: canonical rember body accepted"
  (run 1 (q)
    (follower q
      (non-vacuous-brancheso/d
        '(match l ['() l] [(cons a d) (if (= a e) d (cons a (rember e d)))]))))
  '(_.0))

;; STALL: (if (= h1 e) h2 h3) with fresh holes h1 h2 h3 -- no refutation
;; possible yet (h2/h3 might still commit to distinct non-{c1,c2} text, or
;; to a vacuous combination), and the holes must be left unbound.
(test "non-vacuous-brancheso/d: (if (= h1 e) h2 h3) with fresh holes stalls"
  (run 1 (h1 h2 h3)
    (follower (list h1 h2 h3)
      (non-vacuous-brancheso/d `(if (= ,h1 e) ,h2 ,h3))))
  '((_.0 _.1 _.2)))
