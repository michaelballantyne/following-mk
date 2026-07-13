;; Differential tests for the residual-goal engine (residual.scm) against the
;; closure engine (following.scm).  Each scenario below is a hand-port of an
;; existing closure-engine test to the residual `r`-prefixed constructors,
;; wrapped with follower-residual-goal and driven through the SAME run /
;; main-search.  Asserting the SAME expected answer the closure test asserts is
;; a decision-equivalence check on final answers: commit / stall / refute /
;; suspend all have to land the same way for the answer to match.
;;
;; The engine is exercised through the real follower trigger path, so these
;; also validate the inf/d-protocol wrapper (settle->inf/d) and cross-trigger
;; re-settle (residual-resume).

;;; ================================================================
;;; Part 1 --- core /d control (port of determinacy-goal-forms.scm)
;;; ================================================================

(test "R: conde/d commit"
  (run* (q)
    (follower
      '()
      (follower-residual-goal
        (rfresh/d (x)
          (r==/d x 1)
          (rconde/d
            ([] [(r==/d x 1)] [(r==/d q 1)])
            ([] [(r==/d x 2)] [(r==/d q 2)]))))))
  '(1))

(test "R: conde/d nondet"
  (run* (q)
    (follower
      '()
      (follower-residual-goal
        (rfresh/d (x)
          (rconde/d
            ([] [(r==/d x 1)] [(r==/d q 1)])
            ([] [(r==/d x 2)] [(r==/d q 2)]))))))
  '(_.0))

(test "R: conde/d commit outer, nondet inner, nested"
  (run* (q)
    (follower
      '()
      (follower-residual-goal
        (rfresh/d (x y a b)
          (r==/d q (cons a b))
          (r==/d x 1)
          (rconde/d
            ([] [(r==/d x 1)]
             [(r==/d a 1)
              (rconde/d
                ([] [(r==/d y 1)] [(r==/d b 1)])
                ([] [(r==/d y 2)] [(r==/d b 2)]))])
            ([] [(r==/d x 2)] [(r==/d a 2)]))))))
  '((1 . _.0)))

(test "R: conde/d commit first, nondet second, conjunction"
  (run* (q)
    (follower
      '()
      (follower-residual-goal
        (rfresh/d (x y a b)
          (r==/d q (cons a b))
          (r==/d x 1)
          (rconde/d
            ([] [(r==/d x 1)] [(r==/d a 1)])
            ([] [(r==/d x 2)] [(r==/d a 2)]))
          (rconde/d
            ([] [(r==/d y 1)] [(r==/d b 1)])
            ([] [(r==/d y 2)] [(r==/d b 2)]))))))
  '((1 . _.0)))

(test "R: conde/d nondet first, det second; commits second"
  (run* (q)
    (follower
      '()
      (follower-residual-goal
        (rfresh/d (x y a b)
          (r==/d q (cons a b))
          (r==/d y 1)
          (rconde/d
            ([] [(r==/d x 1)] [(r==/d a 1)])
            ([] [(r==/d x 2)] [(r==/d a 2)]))
          (rconde/d
            ([] [(r==/d y 1)] [(r==/d b 1)])
            ([] [(r==/d y 2)] [(r==/d b 2)]))))))
  '((_.0 . 1)))

(test "R: conde/d nondet first, det second; commits second; return to first"
  (run* (q)
    (fresh (x y a b)
      (follower
        (list x y a b)
        (follower-residual-goal
          (rfresh/d ()
            (r==/d q (cons a b))
            (r==/d y 1)
            (rconde/d
              ([] [(r==/d x 1)] [(r==/d a 1)])
              ([] [(r==/d x 2)] [(r==/d a 2)]))
            (rconde/d
              ([] [(r==/d y 1)] [(r==/d b 1)])
              ([] [(r==/d y 2)] [(r==/d b 2)])))))
      (== x 1)))
  '((1 . 1)))

;; Diverging conjuncts terminate via budget-block (the residual analogue of
;; hard-suspend): each r/d self-call passes through a g-disj, so depth grows
;; and the disj budget-blocks, letting the conjunction settle and the follower
;; commit q = 1 from the other clause.
(define-relation/d (r/d-res)
  (rconde/d
    ([x] [(r==/d x 1)] [(r/d-res)])))

(test "R: diverging conjuncts terminate via budget-block"
  (run 1 (q)
    (follower
      q
      (follower-residual-goal
        (rconde/d
          ([] [(r==/d q 1)] [])
          ([] [(r==/d q 2)
               (rfresh/d () (r/d-res) (r/d-res))]
           []))))
    (conde
      ((== q 1))
      ((fresh ()
         (== q 2)
         (r)
         (r)))))
  '(1))

;;; ================================================================
;;; Part 2 --- R1 base-case-patho/d, ported (recursion through g-call)
;;; ================================================================

(define view-app-keywords-res '(quote cons letrec match if))

(define-relation/d (patho-oro/d-res fname ea eb)
  (rconde/d
    ([] [(base-case-patho/d-res fname ea)] [])
    ([] [(base-case-patho/d-res fname eb)] [])))

(define-relation/d (rands-patho/d-res fname rands)
  (rconde/d
    ([] [(r==/d '() rands)] [])
    ([a d]
     [(r==/d `(,a . ,d) rands)]
     [(base-case-patho/d-res fname a) (rands-patho/d-res fname d)])))

(define-relation/d (base-case-patho/d-res fname body)
  (rconde/d
    ([] [(rnumbero/d body)] [])
    ([] [(rsymbolo/d body)] [])
    ([] [(r==/d '(quote ()) body)] [])
    ([e1 e2]
     [(r==/d `(cons ,e1 ,e2) body)]
     [(base-case-patho/d-res fname e1) (base-case-patho/d-res fname e2)])
    ([e1 e2 e3 e4]
     [(r==/d `(if (= ,e1 ,e2) ,e3 ,e4) body)]
     [(base-case-patho/d-res fname e1)
      (base-case-patho/d-res fname e2)
      (patho-oro/d-res fname e3 e4)])
    ([e e1 x y e2]
     [(r==/d `(match ,e ['() ,e1] [(cons ,x ,y) ,e2]) body)
      (rsymbolo/d x)
      (rsymbolo/d y)
      (r=/=/d x fname)
      (r=/=/d y fname)]
     [(base-case-patho/d-res fname e) (patho-oro/d-res fname e1 e2)])
    ([rator rands]
     [(r==/d `(,rator . ,rands) body)
      (rsymbolo/d rator)
      (r=/=/d rator fname)
      (rabsento/d rator view-app-keywords-res)]
     [(rands-patho/d-res fname rands)])))

(test "R: base-case-patho/d ground (rember e d) is refuted"
  (run 1 (q)
    (follower q (follower-residual-goal
                  (base-case-patho/d-res 'rember '(rember e d)))))
  '())

(test "R: base-case-patho/d ground (cons a (rember e d)) is refuted"
  (run 1 (q)
    (follower q (follower-residual-goal
                  (base-case-patho/d-res 'rember '(cons a (rember e d))))))
  '())

(test "R: base-case-patho/d ground match with base case succeeds"
  (run 1 (q)
    (follower q
      (follower-residual-goal
        (base-case-patho/d-res 'rember
          '(match l ['() l] [(cons a d) (rember e d)])))))
  '(_.0))

(test "R: base-case-patho/d holey self-call on only path refuted"
  (run 1 (h1 h2)
    (follower (list h1 h2)
      (follower-residual-goal
        (base-case-patho/d-res 'rember `(cons ,h1 (rember e ,h2))))))
  '())

(test "R: base-case-patho/d holey match stalls, leaves holes unbound"
  (run 1 (h1 h2)
    (follower (list h1 h2)
      (follower-residual-goal
        (base-case-patho/d-res 'rember `(match l ['() ,h1] [(cons a d) ,h2])))))
  '((_.0 _.1)))

(test "R: base-case-patho/d bare hole stalls"
  (run 1 (q)
    (follower q (follower-residual-goal
                  (base-case-patho/d-res 'rember q))))
  '(_.0))

;;; ================================================================
;;; Part 3 --- direct settle-level shape tests (not through the follower)
;;;
;;; Call `settle` on a goal node from `empty-state` at depth 0 and inspect the
;;; returned residual's SHAPE, checking the design note's data invariants
;;; directly rather than only observing final answers through the follower.
;;; ================================================================

;; (a) A committing goal (sole-survivor conde/d) settles to TOP + a state that
;; carries both the guard's and the body's extension.
(test "R-shape: committing goal yields TOP + extended state"
  (let* ([x (var (new-scope))]
         [q (var (new-scope))]
         [g (rconde/d
              ([] [(r==/d x 1)] [(r==/d q 'committed)])
              ([] [rfail/d] [(r==/d q 'other)]))]
         [r (settle g empty-state 0)])
    (list (and r #t)
          (g-top? (car r))
          (walk x (state-S (cdr r)))
          (walk q (state-S (cdr r)))))
  '(#t #t 1 committed))

;; (b) A genuinely nondet conde/d (two independently-applicable guards) settles
;; to a flat residual: a g-conj of exactly one g-disj, passing the flatness
;; invariant, with a sane S-expression rendering (`(conj (disj:... ...))`).
(test "R-shape: nondet disj yields a flat, well-shaped residual"
  (let* ([x (var (new-scope))]
         [q (var (new-scope))]
         [g (rconde/d
              ([] [(r==/d x 1)] [(r==/d q 1)])
              ([] [(r==/d x 2)] [(r==/d q 2)]))]
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
(test "R-shape: budget-blocked recursion yields a g-blocked conjunct"
  (let* ([r (settle (r/d-res) empty-state 0)]
         [conjs (g-conj-goals (car r))])
    (assert-flat-residual! (car r))
    (list (g-top? (car r))
          (length conjs)
          (g-blocked? (car conjs))))
  '(#f 1 #t))
