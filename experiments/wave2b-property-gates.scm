;; wave2b-property-gates.scm --- ground-eval gates for the WAVE-2b property/
;; relational spec suite: append ASSOCIATIVITY and rember IDEMPOTENCE.
;;
;; Purpose: lock the degenerate analysis BEFORE spending synthesis runs.  These
;; two properties are WEAKER than rev-involution: involution `f(f(X)) = X` fixes
;; the output to the (known) input, but associativity `app(app(a,b),c) =
;; app(a,app(b,c))` and idempotence `f(f(l)) = f(l)` have a CANDIDATE-DEPENDENT
;; right-hand side, so they are satisfied by projections / identity / constants.
;; The gates prove: (i) the canonical body satisfies the property AND the ground
;; anchor; (ii) the cheap degenerates satisfy the PROPERTY ALONE (so
;; property-only synthesis will return one); (iii) the ground anchor KILLS each
;; degenerate (so property+anchor pins the real function).  This is what makes
;; the "does the property add anything over its anchor?" experiment meaningful.
;;
;;   ./run.sh --check-follower-every 1 experiments/wave2b-property-gates.scm
;;
;; Symbolic inputs use (numbero v) vars (the untyped interp evaluates a numbero
;; var to itself).  No =/= among elements: the properties are UNIVERSAL, holding
;; for all element values including collisions.

(load "restricted-interp-untyped.scm")
(load "restricted-interp-untyped-following.scm")
(load "views.scm") ; view defs (not exercised here) + append-/rember-tyenv

;; ---------------------------------------------------------------------------
;; program templates
;; ---------------------------------------------------------------------------
(define (append-prog-u q body) `(letrec ([append (lambda (l s) ,q)]) ,body))
(define (rember-prog-u q body) `(letrec ([rember (lambda (e l) ,q)]) ,body))

;; ---------------------------------------------------------------------------
;; bodies: canonical + the degenerates the WEAK property admits
;; ---------------------------------------------------------------------------
;; append: canonical, and the three cheap degenerates that satisfy associativity.
(define append-canon-u '(match l ['() s] [(cons a d) (cons a (append d s))]))
(define append-ret-s-u 's)   ; return second arg   -> assoc holds (both sides = c)
(define append-ret-l-u 'l)   ; return first arg    -> assoc holds (both sides = a)
(define append-nil-u  '(quote ())) ; constant ()   -> assoc holds (both sides = ())

;; rember: canonical, identity, and the head-only remove (the W2a degenerate).
(define rember-canon-u
  '(match l ['() l] [(cons a d) (if (= a e) d (cons a (rember e d)))]))
(define rember-id-u 'l)      ; identity            -> idempotence holds trivially
(define rember-head-u        ; drop only a head match, never recurse
  '(match l ['() l] [(cons a d) (if (= a e) d l)]))

;; ===========================================================================
;; APPEND ASSOCIATIVITY  --  app(app(a,b),c) = app(a, app(b,c))
;; property cases: shapes (1,1,1) and (2,1,1); anchor: (append (3 4) (5)) = (3 4 5)
;; ===========================================================================
(define (assoc-holds body)
  ;; both sides evaluate to the SAME fresh V (candidate-dependent RHS)
  (fresh (x1 x2 x3 x4 V1 V2)
    (numbero x1) (numbero x2) (numbero x3) (numbero x4)
    ;; (1,1,1)
    (evalo-u (append-prog-u body `(append (append (cons ,x1 '()) (cons ,x2 '())) (cons ,x3 '()))) V1)
    (evalo-u (append-prog-u body `(append (cons ,x1 '()) (append (cons ,x2 '()) (cons ,x3 '())))) V1)
    ;; (2,1,1)
    (evalo-u (append-prog-u body `(append (append (cons ,x1 (cons ,x2 '())) (cons ,x3 '())) (cons ,x4 '()))) V2)
    (evalo-u (append-prog-u body `(append (cons ,x1 (cons ,x2 '())) (append (cons ,x3 '()) (cons ,x4 '())))) V2)))

(define (append-anchor body)
  (evalo-u (append-prog-u body '(append (cons 3 (cons 4 '())) (cons 5 '()))) '(3 4 5)))

(test "assoc: CANON satisfies the associativity property"
  (run 1 (q) (assoc-holds append-canon-u)) '(_.0))
(test "assoc: CANON satisfies the ground anchor"
  (run 1 (q) (append-anchor append-canon-u)) '(_.0))
(test "assoc: return-S degenerate SATISFIES the property (weak!)"
  (run 1 (q) (assoc-holds append-ret-s-u)) '(_.0))
(test "assoc: return-L degenerate SATISFIES the property (weak!)"
  (run 1 (q) (assoc-holds append-ret-l-u)) '(_.0))
(test "assoc: constant-() degenerate SATISFIES the property (weak!)"
  (run 1 (q) (assoc-holds append-nil-u)) '(_.0))
(test "assoc: return-S FAILS the anchor (anchor kills it)"
  (run 1 (q) (append-anchor append-ret-s-u)) '())
(test "assoc: return-L FAILS the anchor (anchor kills it)"
  (run 1 (q) (append-anchor append-ret-l-u)) '())
(test "assoc: constant-() FAILS the anchor (anchor kills it)"
  (run 1 (q) (append-anchor append-nil-u)) '())

;; ===========================================================================
;; REMBER IDEMPOTENCE  --  rember e (rember e l) = rember e l
;; property cases: symbolic l of shapes len 1,2; anchor forces recurse+drop-deep
;; ===========================================================================
(define (idem-holds body)
  (fresh (e x1 x2 V1 V2)
    (numbero e) (numbero x1) (numbero x2)
    ;; len 1:  rember e (rember e (x1)) = rember e (x1)
    (evalo-u (rember-prog-u body `(rember ,e (rember ,e (cons ,x1 '())))) V1)
    (evalo-u (rember-prog-u body `(rember ,e (cons ,x1 '()))) V1)
    ;; len 2:  rember e (rember e (x1 x2)) = rember e (x1 x2)
    (evalo-u (rember-prog-u body `(rember ,e (rember ,e (cons ,x1 (cons ,x2 '()))))) V2)
    (evalo-u (rember-prog-u body `(rember ,e (cons ,x1 (cons ,x2 '())))) V2)))

(define (rember-anchor body)
  ;; drop 5 from (6 5): forces recursion PAST the 6 and drop-deeper; kills
  ;; identity (would give (6 5)) and head-only (head 6 /= 5 -> returns (6 5)).
  (evalo-u (rember-prog-u body '(rember 5 (cons 6 (cons 5 '())))) '(6)))

(test "idem: CANON satisfies the idempotence property"
  (run 1 (q) (idem-holds rember-canon-u)) '(_.0))
(test "idem: CANON satisfies the ground anchor"
  (run 1 (q) (rember-anchor rember-canon-u)) '(_.0))
(test "idem: IDENTITY degenerate SATISFIES the property (weak!)"
  (run 1 (q) (idem-holds rember-id-u)) '(_.0))
(test "idem: HEAD-ONLY degenerate SATISFIES the property (weak!)"
  (run 1 (q) (idem-holds rember-head-u)) '(_.0))
(test "idem: IDENTITY FAILS the anchor (anchor kills it)"
  (run 1 (q) (rember-anchor rember-id-u)) '())
(test "idem: HEAD-ONLY FAILS the anchor (anchor kills it)"
  (run 1 (q) (rember-anchor rember-head-u)) '())

(test-summary)
