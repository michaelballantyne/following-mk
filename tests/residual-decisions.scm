;; Per-trigger DECISION-equivalence tests: the design note's actual bar for the
;; migration -- "compare decisions (refute / commit / suspend per trigger)
;; against the closure engine, NOT byte-identical counters".
;;
;; For each scenario we run the closure follower and the residual follower over
;; the SAME main search and compare the follower-decision vector
;;   (follower-fail  follower-singleton  follower-suspend  suspend-cutoff)
;; i.e. how many triggers refuted, committed to a singleton, suspended, or hit
;; the depth budget.  These are the observable decisions.  The internal
;; conde/d-entry work count is deliberately EXCLUDED: it differs in the small
;; (settle threads state differently from conj/d-run's fixpoint), which the
;; design note anticipates and calls the wrong bar.

(define (follower-decision-vector)
  (list *fail-counter*
        *singleton-succeed-counter*
        *non-singleton-succeed-counter*
        *suspend-depth-cutoff-counter*))

;; run a thunk (a full `run`, which resets counters at entry) and read back the
;; decision vector it produced.
(define (decisions-of thunk)
  (thunk)
  (follower-decision-vector))

;; Run each side exactly once: `actual` is the residual engine's decision
;; vector, `expected` is the closure engine's.  Each `decisions-of` runs a full
;; `run` (which resets the counters on entry) and reads the vector back, so the
;; two runs don't interfere regardless of evaluation order.
(define-syntax decision-equiv
  (syntax-rules ()
    [(_ title closure-run residual-run)
     (test title
       (decisions-of (lambda () residual-run))
       (decisions-of (lambda () closure-run)))]))

;; --- refute: cons shape can't produce '()
(decision-equiv "D: refute cons-shape"
  (run* (q)
    (follower q
      (evalo/d `(letrec ([f (lambda (l) : ((list) -> list) ,q)]) (f '())) '()))
    (conde ((fresh (e1 e2) (== q `(cons ,e1 ,e2)))) ((== q 'l))))
  (run* (q)
    (follower q
      (follower-residual-goal
        (evalo/d-res `(letrec ([f (lambda (l) : ((list) -> list) ,q)]) (f '())) '())))
    (conde ((fresh (e1 e2) (== q `(cons ,e1 ,e2)))) ((== q 'l)))))

;; --- refute: type mismatch (list vs number)
(decision-equiv "D: refute type-mismatch"
  (run* (q)
    (fresh (v)
      (follower q
        (evalo/d `(letrec ([f (lambda (l) : ((list) -> number) ,q)]) (f '())) v))
      (conde ((== q '(match l ['() '()] [(cons a d) d]))) ((== q 5)))))
  (run* (q)
    (fresh (v)
      (follower q
        (follower-residual-goal
          (evalo/d-res `(letrec ([f (lambda (l) : ((list) -> number) ,q)]) (f '())) v)))
      (conde ((== q '(match l ['() '()] [(cons a d) d]))) ((== q 5))))))

;; --- refute: wrong rember else-branches (two examples; deeper search)
(decision-equiv "D: refute rember-else"
  (run* (q)
    (follower q
      (fresh/d ()
        (evalo/d `(letrec ([rember (lambda (e l) : ((number list) -> list)
                                     (match l ['() l] [(cons a d) (if (= a e) d (cons a ,q))]))])
                    (rember 5 '())) '())
        (evalo/d `(letrec ([rember (lambda (e l) : ((number list) -> list)
                                     (match l ['() l] [(cons a d) (if (= a e) d (cons a ,q))]))])
                    (rember 5 (cons 3 (cons 4 (cons 5 '()))))) '(3 4))))
    (conde ((== q 'd)) ((== q 'l)) ((== q '(rember e d)))))
  (run* (q)
    (follower q
      (follower-residual-goal
        (rfresh/d ()
          (evalo/d-res `(letrec ([rember (lambda (e l) : ((number list) -> list)
                                           (match l ['() l] [(cons a d) (if (= a e) d (cons a ,q))]))])
                          (rember 5 '())) '())
          (evalo/d-res `(letrec ([rember (lambda (e l) : ((number list) -> list)
                                           (match l ['() l] [(cons a d) (if (= a e) d (cons a ,q))]))])
                          (rember 5 (cons 3 (cons 4 (cons 5 '()))))) '(3 4)))))
    (conde ((== q 'd)) ((== q 'l)) ((== q '(rember e d))))))

;; --- suspend then resume: partial program filled in by the main search
(decision-equiv "D: resume partial cons"
  (run 1 (q)
    (fresh (p)
      (follower (list p) (evalo/d `(cons 1 ,p) q))
      (== p ''())))
  (run 1 (q)
    (fresh (p)
      (follower (list p) (follower-residual-goal (evalo/d-res `(cons 1 ,p) q)))
      (== p ''()))))

;; --- ground eval: a single committing trigger, no suspension
(decision-equiv "D: ground eval identity"
  (run 1 (q)
    (follower '()
      (evalo/d '(letrec ([double (lambda (l) : ((list) -> list) l)])
                  (double (cons 1 (cons 2 (cons 3 '()))))) q)))
  (run 1 (q)
    (follower '()
      (follower-residual-goal
        (evalo/d-res '(letrec ([double (lambda (l) : ((list) -> list) l)])
                        (double (cons 1 (cons 2 (cons 3 '()))))) q)))))

;; --- R1 base-case-patho over a fixed candidate set (refute + stall mix)
(decision-equiv "D: R1 caseless refuted, base-case committed"
  (run* (q)
    (fresh (body)
      (follower q (base-case-patho/d 'f body))
      (conde
        ((== body '(f e d)))
        ((== body '(match l ['() l] [(cons a d) (f e d)]))))))
  (run* (q)
    (fresh (body)
      (follower q (follower-residual-goal (base-case-patho/d-res 'f body)))
      (conde
        ((== body '(f e d)))
        ((== body '(match l ['() l] [(cons a d) (f e d)])))))))
