;; tests/engine-shape.scm --- direct settle-level shape tests for the residual
;; engine (residual.scm).  Salvaged from the old differential tests/residual-
;; engine.scm's Part 3 (the only part with no duplicate elsewhere): call
;; `settle` on a goal node from `empty-state` at depth 0 and inspect the
;; returned residual's SHAPE, checking the design note's data invariants
;; directly rather than only observing final answers through the follower.

;; A relation that recurses through a sole-survivor conde/d with no base case:
;; each self-call passes through a g-disj, so depth grows and the disj
;; budget-blocks.  Used by the budget-block shape test below.
(define-relation/d (div-rec/d)
  (conde/d
    ([x] [(==/d x 1)] [(div-rec/d)])))

;; (a) A committing goal (sole-survivor conde/d) settles to TOP + a state that
;; carries both the guard's and the body's extension.
(test "shape: committing goal yields TOP + extended state"
  (let* ([x (var (new-scope))]
         [q (var (new-scope))]
         ;; (=/=/d 'x 'x) is an always-failing guard (a symbol can't differ
         ;; from itself); self-contained so this file doesn't depend on which
         ;; `fail/d` is in scope.
         [g (conde/d
              ([] [(==/d x 1)] [(==/d q 'committed)])
              ([] [(=/=/d 'x 'x)] [(==/d q 'other)]))]
         [r (settle g empty-state 0)])
    (list (and r #t)
          (g-top? (car r))
          (walk x (state-S (cdr r)))
          (walk q (state-S (cdr r)))))
  '(#t #t 1 committed))

;; (b) A genuinely nondet conde/d (two independently-applicable guards) settles
;; to a flat residual: a g-conj of exactly one g-disj, passing the flatness
;; invariant, with a sane S-expression rendering (`(conj (disj:... ...))`).
(test "shape: nondet disj yields a flat, well-shaped residual"
  (let* ([x (var (new-scope))]
         [q (var (new-scope))]
         [g (conde/d
              ([] [(==/d x 1)] [(==/d q 1)])
              ([] [(==/d x 2)] [(==/d q 2)]))]
         [r (settle g empty-state 0)])
    (assert-flat-residual! (car r)) ; raises (=> test fails) if not flat
    (let ([sexp (residual->sexp (car r))])
      (list (g-top? (car r))
            (length (g-conj-goals (car r)))
            (car sexp)                                  ; 'conj
            (g-disj? (car (g-conj-goals (car r))))      ; sole conjunct is a disj
            (symbol? (car (cadr sexp))))))              ; renders as (disj:LABEL ..)
  '(#f 1 conj #t #t))

;; (c) A budget-blocked recursion (a relation that recurses through a
;; sole-survivor conde/d with no base case) settles to a residual whose sole
;; conjunct is a g-blocked node -- the residual analogue of hard suspension.
(test "shape: budget-blocked recursion yields a g-blocked conjunct"
  (let* ([r (settle (div-rec/d) empty-state 0)]
         [conjs (g-conj-goals (car r))])
    (assert-flat-residual! (car r))
    (list (g-top? (car r))
          (length conjs)
          (g-blocked? (car conjs))))
  '(#f 1 #t))
