;; tests/untyped-interp.scm --- gates for the UNTYPED interpreter variants
;; (restricted-interp-untyped.scm and restricted-interp-untyped-following.scm).
;;
;; Covers: ground forward evaluation of the three synthesis tasks' canonical
;; bodies (rember/append/duplicate); dynamic stuckness of ill-typed operations
;; that are actually EXECUTED (=-on-non-number, match-on-number); totality of
;; cons; and follower gates (ground commit, holey stall, composition with the
;; R1/R2 structural views, example-violation refutation).

;; Structural views R1 (base-case-patho/d) and R2 (decreasing-recursiono/d),
;; used in the composition gate below.  tv2 loads tv1.
(load "views.scm")

;; Untyped program templates: NO `: type` annotation on the lambda.
(define (rember-prog-u q body)
  `(letrec ([rember (lambda (e l)
                      ,q)])
     ,body))
(define (append-prog-u q body)
  `(letrec ([append (lambda (l s)
                      ,q)])
     ,body))
(define (duplicate-prog-u q body)
  `(letrec ([duplicate (lambda (l)
                         ,q)])
     ,body))

(define rember-body-u
  '(match l ['() l] [(cons a d) (if (= a e) d (cons a (rember e d)))]))
(define append-body-u
  '(match l ['() s] [(cons a d) (cons a (append d s))]))
(define duplicate-body-u
  '(match l ['() l] [(cons a d) (cons a (cons a (duplicate d)))]))

;; ---------------------------------------------------------------------------
;; Gate 1: ground forward evaluation of the canonical bodies (evalo-u).
;; ---------------------------------------------------------------------------

(test "evalo-u: rember 5 '() -> '()"
  (run 1 (v) (evalo-u (rember-prog-u rember-body-u '(rember 5 '())) v))
  '(()))

(test "evalo-u: rember 6 (6) -> '()"
  (run 1 (v)
    (evalo-u (rember-prog-u rember-body-u '(rember 6 (cons 6 '()))) v))
  '(()))

(test "evalo-u: rember 7 (3 4 7 6) -> (3 4 6)"
  (run 1 (v)
    (evalo-u
     (rember-prog-u rember-body-u
                    '(rember 7 (cons 3 (cons 4 (cons 7 (cons 6 '()))))))
     v))
  '((3 4 6)))

(test "evalo-u: rember 5 (3 4 6 7) -> (3 4 6 7)"
  (run 1 (v)
    (evalo-u
     (rember-prog-u rember-body-u
                    '(rember 5 (cons 3 (cons 4 (cons 6 (cons 7 '()))))))
     v))
  '((3 4 6 7)))

(test "evalo-u: append '() (5 6) -> (5 6)"
  (run 1 (v)
    (evalo-u
     (append-prog-u append-body-u '(append '() (cons 5 (cons 6 '()))))
     v))
  '((5 6)))

(test "evalo-u: append (3 4 5) (6 7) -> (3 4 5 6 7)"
  (run 1 (v)
    (evalo-u
     (append-prog-u append-body-u
                    '(append (cons 3 (cons 4 (cons 5 '())))
                             (cons 6 (cons 7 '()))))
     v))
  '((3 4 5 6 7)))

(test "evalo-u: duplicate '() -> '()"
  (run 1 (v)
    (evalo-u (duplicate-prog-u duplicate-body-u '(duplicate '())) v))
  '(()))

(test "evalo-u: duplicate (5) -> (5 5)"
  (run 1 (v)
    (evalo-u
     (duplicate-prog-u duplicate-body-u '(duplicate (cons 5 '())))
     v))
  '((5 5)))

(test "evalo-u: duplicate (3 4) -> (3 3 4 4)"
  (run 1 (v)
    (evalo-u
     (duplicate-prog-u duplicate-body-u
                       '(duplicate (cons 3 (cons 4 '()))))
     v))
  '((3 3 4 4)))

;; ---------------------------------------------------------------------------
;; Gate 2: dynamic stuckness of EXECUTED ill-typed operations.
;;
;; The kept E/I (introduction/elimination) discipline forces `=` operands and
;; the `match` scrutinee to be E-forms (variables or applications), never
;; literals/constructors -- so the DYNAMIC type checks below are exercised by
;; binding a variable to a run-time value of the wrong shape and executing it.
;; ---------------------------------------------------------------------------

;; `=` on a variable that evaluates to a LIST: the numbero check on the `=`
;; operands fails at run time -> the whole program is stuck.
(test "evalo-u: (= l l) with l a list is stuck (=-on-non-number)"
  (run 1 (v)
    (evalo-u '(letrec ([f (lambda (l) (if (= l l) '() '()))])
                (f (cons 1 '())))
             v))
  '())

;; `match` on a variable that evaluates to a NUMBER: 5 is neither '() nor a
;; pair, so no clause applies -> stuck.
(test "evalo-u: match on a number-valued scrutinee is stuck"
  (run 1 (v)
    (evalo-u '(letrec ([f (lambda (e) (match e ['() '()] [(cons a d) a]))])
                (f 5))
             v))
  '())

;; I-form (quote) in an E position (a `=` operand) is rejected by the E/I
;; discipline itself -- stuck before any dynamic type check.
(test "evalo-u: (= '() '()) is stuck (I-form in E position)"
  (run 1 (v) (evalo-u '(if (= '() '()) '() '()) v))
  '())

;; control: `=` on number-valued variables takes the then-branch.
(test "evalo-u: (= e e) with e a number takes the then-branch"
  (run 1 (v)
    (evalo-u '(letrec ([f (lambda (e) (if (= e e) (cons e '()) '()))])
                (f 5))
             v))
  '((5)))

;; control: `match` on a list-valued variable takes the cons clause.
(test "evalo-u: match on a list-valued scrutinee takes the cons clause"
  (run 1 (v)
    (evalo-u '(letrec ([f (lambda (l) (match l ['() 0] [(cons a d) a]))])
                (f (cons 7 '())))
             v))
  '(7))

;; ---------------------------------------------------------------------------
;; Gate 3: totality of cons (any values, both positions).
;; ---------------------------------------------------------------------------

(test "evalo-u: (cons '() '()) -> (())"
  (run 1 (v) (evalo-u '(cons '() '()) v))
  '((())))

;; number in the cdr position: ill-typed under the typed interp, fine here.
(test "evalo-u: (cons 3 4) -> (3 . 4)"
  (run 1 (v) (evalo-u '(cons 3 4) v))
  '((3 . 4)))

;; list in the car position: also fine.
(test "evalo-u: (cons (cons 1 '()) '()) -> ((1))"
  (run 1 (v) (evalo-u '(cons (cons 1 '()) '()) v))
  '(((1))))

;; ---------------------------------------------------------------------------
;; Gate 4: follower gates for evalo-u/d.
;; ---------------------------------------------------------------------------

;; (a) ground example: the follower runs the evaluation to completion and
;;     commits the output.
(parameterize ([*suspend-depth* 1000])
  (test "evalo-u/d: ground rember commits/succeeds"
    (run 1 (v)
      (follower
        '()
        (evalo-u/d
         (rember-prog-u rember-body-u
                        '(rember 5 (cons 3 (cons 4 (cons 6 (cons 7 '()))))))
         v)))
    '((3 4 6 7))))

(parameterize ([*suspend-depth* 1000])
  (test "evalo-u/d: ground duplicate commits/succeeds"
    (run 1 (v)
      (follower
        '()
        (evalo-u/d
         (duplicate-prog-u duplicate-body-u
                           '(duplicate (cons 3 (cons 4 '()))))
         v)))
    '((3 3 4 4))))

;; (b) partially-instantiated program: the follower forces only the
;;     determinate structure and STALLS on the hole rather than diverging.
(test "evalo-u/d: holey cons stalls, hole unbound"
  (run 1 (v)
    (fresh (p)
      (follower
        (list p)
        (evalo-u/d `(cons 1 (cons ,p '())) v))))
  '((1 _.0)))

;; (c) stall then resume: main search fills the hole, follower finishes.
(test "evalo-u/d: holey cons resumes when hole filled"
  (run 1 (v)
    (fresh (p)
      (follower
        (list p)
        (evalo-u/d `(cons 1 (cons ,p '())) v))
      (== p 2)))
  '((1 2)))

;; (d) composition with R1+R2: the ground canonical rember body is ACCEPTED by
;;     both structural views and by evalo-u/d on an example.
(parameterize ([*suspend-depth* 1000])
  (test "evalo-u/d + R1 + R2: canonical rember accepted (ground)"
    (run 1 (q)
      (== q rember-body-u)
      (follower
        q
        (fresh/d ()
          (base-case-patho/d 'rember q)
          (decreasing-recursiono/d 'rember '(e l) q)
          (evalo-u/d
           (rember-prog-u q
                          '(rember 7 (cons 3 (cons 4 (cons 7 (cons 6 '()))))))
           '(3 4 6))))
      (evalo-u
       (rember-prog-u q '(rember 7 (cons 3 (cons 4 (cons 7 (cons 6 '()))))))
       '(3 4 6)))
    (list rember-body-u)))

;; (e) example violation: a body that returns the input unchanged contradicts
;;     the example; evalo-u/d refutes it when driven ground.
(parameterize ([*suspend-depth* 1000])
  (test "evalo-u/d: example-violating rember body refuted (ground)"
    (run 1 (q)
      (== q '(match l ['() l] [(cons a d) l]))
      (follower
        q
        (evalo-u/d
         (rember-prog-u q
                        '(rember 7 (cons 3 (cons 4 (cons 7 (cons 6 '()))))))
         '(3 4 6))))
    '()))
