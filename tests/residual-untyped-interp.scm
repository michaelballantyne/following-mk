;; tests/residual-untyped-interp.scm --- residual-engine port of
;; tests/untyped-interp.scm, for the UNTYPED /d interpreter
;; (residual-interp-untyped-following.scm).
;;
;; Same style as tests/residual-interp.scm: each closure-engine scenario is
;; re-run through follower + follower-residual-goal + the r-form interpreter
;; (evalo-u/d-r), asserting the SAME expected answer as the closure-engine
;; test it mirrors -- a decision-equivalence-by-final-answer check.
;;
;; Gate 1-3 in tests/untyped-interp.scm exercise the plain (non-/d) evalo-u
;; relation directly with `run`, with no follower involved at all -- there is
;; no residual counterpart to port for those (the r-forms only exist to give
;; /d relations a first-order representation; the plain relation is unchanged
;; and already covered by tests/untyped-interp.scm). Here those same
;; ground-eval / stuckness / totality scenarios are instead re-run through
;; follower '() + evalo-u/d-r, which is the operation this migration actually
;; needs to validate: same expected answers as running the plain relation
;; directly confirms the /d + residual path decides the same way.
;;
;; Gate 4(d) in tests/untyped-interp.scm composes evalo-u/d with the R1/R2
;; structural views (base-case-patho/d, decreasing-recursiono/d). As of this
;; port, only R1's residual counterpart (base-case-patho/d-res) exists, and
;; only inline in tests/residual-engine.scm (not yet in views.scm as a
;; reusable relation); R2's residual port (decreasing-recursiono/d-res) does
;; not exist yet. So the R1+R2 composition gate is SKIPPED here pending that
;; parallel work landing in views.scm -- see the report for this task.

;; Recursion depth needed for rember/append/duplicate ground evaluation
;; exceeds the default *suspend-depth* (20); parameterize generously, mirroring
;; the closure-engine file's gate 4(a)/(d)/(e).

;; Untyped program templates: NO `: type` annotation on the lambda.  Same
;; templates as tests/untyped-interp.scm (duplicated here rather than shared,
;; to keep this file loadable standalone against just this task's files).
(define (rember-prog-u-res q body)
  `(letrec ([rember (lambda (e l)
                      ,q)])
     ,body))
(define (append-prog-u-res q body)
  `(letrec ([append (lambda (l s)
                      ,q)])
     ,body))
(define (duplicate-prog-u-res q body)
  `(letrec ([duplicate (lambda (l)
                         ,q)])
     ,body))

(define rember-body-u-res
  '(match l ['() l] [(cons a d) (if (= a e) d (cons a (rember e d)))]))
(define append-body-u-res
  '(match l ['() s] [(cons a d) (cons a (append d s))]))
(define duplicate-body-u-res
  '(match l ['() l] [(cons a d) (cons a (cons a (duplicate d)))]))

;; ---------------------------------------------------------------------------
;; Gate 1 (residual): ground forward evaluation of the canonical bodies,
;; through follower '() + evalo-u/d-r.  Same expected answers as
;; tests/untyped-interp.scm's plain evalo-u gate 1.
;; ---------------------------------------------------------------------------

(parameterize ([*suspend-depth* 1000])
  (test "R-untyped: evalo-u/d-r rember 5 '() -> '()"
    (run 1 (v)
      (follower '() (evalo-u/d-r (rember-prog-u-res rember-body-u-res '(rember 5 '())) v)))
    '(())))

(parameterize ([*suspend-depth* 1000])
  (test "R-untyped: evalo-u/d-r rember 6 (6) -> '()"
    (run 1 (v)
      (follower '()
        (evalo-u/d-r
         (rember-prog-u-res rember-body-u-res '(rember 6 (cons 6 '())))
         v)))
    '(())))

(parameterize ([*suspend-depth* 1000])
  (test "R-untyped: evalo-u/d-r rember 7 (3 4 7 6) -> (3 4 6)"
    (run 1 (v)
      (follower '()
        (evalo-u/d-r
         (rember-prog-u-res rember-body-u-res
                            '(rember 7 (cons 3 (cons 4 (cons 7 (cons 6 '()))))))
         v)))
    '((3 4 6))))

(parameterize ([*suspend-depth* 1000])
  (test "R-untyped: evalo-u/d-r rember 5 (3 4 6 7) -> (3 4 6 7)"
    (run 1 (v)
      (follower '()
        (evalo-u/d-r
         (rember-prog-u-res rember-body-u-res
                            '(rember 5 (cons 3 (cons 4 (cons 6 (cons 7 '()))))))
         v)))
    '((3 4 6 7))))

(parameterize ([*suspend-depth* 1000])
  (test "R-untyped: evalo-u/d-r append '() (5 6) -> (5 6)"
    (run 1 (v)
      (follower '()
        (evalo-u/d-r
         (append-prog-u-res append-body-u-res '(append '() (cons 5 (cons 6 '()))))
         v)))
    '((5 6))))

(parameterize ([*suspend-depth* 1000])
  (test "R-untyped: evalo-u/d-r append (3 4 5) (6 7) -> (3 4 5 6 7)"
    (run 1 (v)
      (follower '()
        (evalo-u/d-r
         (append-prog-u-res append-body-u-res
                            '(append (cons 3 (cons 4 (cons 5 '())))
                                     (cons 6 (cons 7 '()))))
         v)))
    '((3 4 5 6 7))))

(parameterize ([*suspend-depth* 1000])
  (test "R-untyped: evalo-u/d-r duplicate '() -> '()"
    (run 1 (v)
      (follower '()
        (evalo-u/d-r (duplicate-prog-u-res duplicate-body-u-res '(duplicate '())) v)))
    '(())))

(parameterize ([*suspend-depth* 1000])
  (test "R-untyped: evalo-u/d-r duplicate (5) -> (5 5)"
    (run 1 (v)
      (follower '()
        (evalo-u/d-r
         (duplicate-prog-u-res duplicate-body-u-res '(duplicate (cons 5 '())))
         v)))
    '((5 5))))

(parameterize ([*suspend-depth* 1000])
  (test "R-untyped: evalo-u/d-r duplicate (3 4) -> (3 3 4 4)"
    (run 1 (v)
      (follower '()
        (evalo-u/d-r
         (duplicate-prog-u-res duplicate-body-u-res
                               '(duplicate (cons 3 (cons 4 '()))))
         v)))
    '((3 3 4 4))))

;; ---------------------------------------------------------------------------
;; Gate 2 (residual): dynamic stuckness of EXECUTED ill-typed operations,
;; through follower '() + evalo-u/d-r.  Same expected answers as
;; tests/untyped-interp.scm's plain evalo-u gate 2.
;; ---------------------------------------------------------------------------

(parameterize ([*suspend-depth* 1000])
  (test "R-untyped: (= l l) with l a list is stuck (=-on-non-number)"
    (run 1 (v)
      (follower '()
        (evalo-u/d-r '(letrec ([f (lambda (l) (if (= l l) '() '()))])
                        (f (cons 1 '())))
                     v)))
    '()))

(parameterize ([*suspend-depth* 1000])
  (test "R-untyped: match on a number-valued scrutinee is stuck"
    (run 1 (v)
      (follower '()
        (evalo-u/d-r '(letrec ([f (lambda (e) (match e ['() '()] [(cons a d) a]))])
                        (f 5))
                     v)))
    '()))

(parameterize ([*suspend-depth* 1000])
  (test "R-untyped: (= '() '()) is stuck (I-form in E position)"
    (run 1 (v)
      (follower '() (evalo-u/d-r '(if (= '() '()) '() '()) v)))
    '()))

(parameterize ([*suspend-depth* 1000])
  (test "R-untyped: (= e e) with e a number takes the then-branch"
    (run 1 (v)
      (follower '()
        (evalo-u/d-r '(letrec ([f (lambda (e) (if (= e e) (cons e '()) '()))])
                        (f 5))
                     v)))
    '((5))))

(parameterize ([*suspend-depth* 1000])
  (test "R-untyped: match on a list-valued scrutinee takes the cons clause"
    (run 1 (v)
      (follower '()
        (evalo-u/d-r '(letrec ([f (lambda (l) (match l ['() 0] [(cons a d) a]))])
                        (f (cons 7 '())))
                     v)))
    '(7)))

;; ---------------------------------------------------------------------------
;; Gate 3 (residual): totality of cons, through follower '() + evalo-u/d-r.
;; ---------------------------------------------------------------------------

(test "R-untyped: (cons '() '()) -> (())"
  (run 1 (v) (follower '() (evalo-u/d-r '(cons '() '()) v)))
  '((())))

(test "R-untyped: (cons 3 4) -> (3 . 4)"
  (run 1 (v) (follower '() (evalo-u/d-r '(cons 3 4) v)))
  '((3 . 4)))

(test "R-untyped: (cons (cons 1 '()) '()) -> ((1))"
  (run 1 (v) (follower '() (evalo-u/d-r '(cons (cons 1 '()) '()) v)))
  '(((1))))

;; ---------------------------------------------------------------------------
;; Gate 4 (residual): follower gates for evalo-u/d-r.
;; ---------------------------------------------------------------------------

;; (a) ground example: the follower runs the evaluation to completion and
;;     commits the output.
(parameterize ([*suspend-depth* 1000])
  (test "R-untyped: evalo-u/d-r ground rember commits/succeeds"
    (run 1 (v)
      (follower
        '()
        (evalo-u/d-r
         (rember-prog-u-res rember-body-u-res
                            '(rember 5 (cons 3 (cons 4 (cons 6 (cons 7 '()))))))
         v)))
    '((3 4 6 7))))

(parameterize ([*suspend-depth* 1000])
  (test "R-untyped: evalo-u/d-r ground duplicate commits/succeeds"
    (run 1 (v)
      (follower
        '()
        (evalo-u/d-r
         (duplicate-prog-u-res duplicate-body-u-res
                               '(duplicate (cons 3 (cons 4 '()))))
         v)))
    '((3 3 4 4))))

;; (b) partially-instantiated program: the follower forces only the
;;     determinate structure and STALLS on the hole rather than diverging.
(test "R-untyped: evalo-u/d-r holey cons stalls, hole unbound"
  (run 1 (v)
    (fresh (p)
      (follower
        (list p)
        (evalo-u/d-r `(cons 1 (cons ,p '())) v))))
  '((1 _.0)))

;; (c) stall then resume: main search fills the hole, follower finishes.
(test "R-untyped: evalo-u/d-r holey cons resumes when hole filled"
  (run 1 (v)
    (fresh (p)
      (follower
        (list p)
        (evalo-u/d-r `(cons 1 (cons ,p '())) v))
      (== p 2)))
  '((1 2)))

;; (d) composition with R1+R2: the ground canonical rember body is ACCEPTED
;;     by both residual structural views and by evalo-u/d-res on an example.
;;     Port of tests/untyped-interp.scm's "evalo-u/d + R1 + R2: canonical
;;     rember accepted (ground)", now that residual-views.scm provides
;;     base-case-patho/d-res and decreasing-recursiono/d-res as loadable
;;     relations. Composed the same way the closure original does: one
;;     rfresh/d conjoining the two views with the raw (unwrapped)
;;     evalo-u/d-res node, the whole thing wrapped in a SINGLE
;;     follower-residual-goal (evalo-u/d-r's own wrapping is for standalone
;;     use and would be the wrong shape to nest inside another conjunction).
(parameterize ([*suspend-depth* 1000])
  (test "R-untyped: evalo-u/d-res + R1 + R2: canonical rember accepted (ground)"
    (run 1 (q)
      (== q rember-body-u-res)
      (follower
        q
        (follower-residual-goal
          (rfresh/d ()
            (base-case-patho/d-res 'rember q)
            (decreasing-recursiono/d-res 'rember '(e l) q)
            (evalo-u/d-res
             (rember-prog-u-res q
                                '(rember 7 (cons 3 (cons 4 (cons 7 (cons 6 '()))))))
             '(3 4 6)))))
      (evalo-u
       (rember-prog-u-res q '(rember 7 (cons 3 (cons 4 (cons 7 (cons 6 '()))))))
       '(3 4 6)))
    (list rember-body-u-res)))

;; (e) example violation: a body that returns the input unchanged contradicts
;;     the example; evalo-u/d-r refutes it when driven ground.
(parameterize ([*suspend-depth* 1000])
  (test "R-untyped: evalo-u/d-r example-violating rember body refuted (ground)"
    (run 1 (q)
      (== q '(match l ['() l] [(cons a d) l]))
      (follower
        q
        (evalo-u/d-r
         (rember-prog-u-res q
                            '(rember 7 (cons 3 (cons 4 (cons 7 (cons 6 '()))))))
         '(3 4 6))))
    '()))
