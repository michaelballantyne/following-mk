;; wave2-gates.scm --- re-runnable ground-eval gates for the three wave-2 arms
;; (rember-symbolic W2a, swap-partial W2b, rev-involution W2c).  Cheap checks
;; only: ground candidate BODIES evaluated (via top-level evalo-u) on the arm
;; specs, confirming the canonical body is accepted and the intended degenerate/
;; weakness witnesses behave as designed.  No follower, no ID synthesis.
;;
;;   ./run.sh --check-follower-every 1 experiments/wave2-gates.scm
;;
;; Symbolic inputs use (numbero v) vars as symbolic numeric literals (the untyped
;; interp evaluates a numbero var to itself); =/= constraints pin the family.

(load "restricted-interp-untyped.scm")
(load "restricted-interp-untyped-following.scm")
(load "views.scm") ; view defs (not exercised here) + rember-tyenv

;; ---------------------------------------------------------------------------
;; program templates (mirror the arm files)
;; ---------------------------------------------------------------------------
(define (rember-prog-u q body) `(letrec ([rember (lambda (e l) ,q)]) ,body))
(define (swap-prog-u q body)   `(letrec ([swap (lambda (l) ,q)]) ,body))
(define (rev-prog-u q body)    `(letrec ([rev (lambda (l acc) ,q)]) ,body))

;; ---------------------------------------------------------------------------
;; bodies
;; ---------------------------------------------------------------------------
;; rember: canonical (drops e), and the wrong "identity" body (never drops).
(define rember-canon-u
  '(match l ['() l] [(cons a d) (if (= a e) d (cons a (rember e d)))]))
(define rember-wrong-u
  '(match l ['() l] [(cons a d) (cons a (rember e d))]))

;; swap: canonical (human), and the non-recursive "swap-first-pair, splice rest"
;; weakness witness (right head, wrong tail on the 4-element input).
(define swap-canon-u
  '(match l ['() '()] [(cons a d) (match d ['() (cons a '())] [(cons b dd) (cons b (cons a (swap dd)))])]))
(define swap-witness-u
  '(match l ['() l] [(cons a d) (match d ['() l] [(cons b dd) (cons b (cons a dd))])]))

;; rev: canonical accumulator reverse, and the identity-on-l degenerate that
;; satisfies involution but not real reversal.
(define rev-canon-u
  '(match l ['() acc] [(cons a d) (rev d (cons a acc))]))
(define rev-identity-u
  '(match l ['() '()] [(cons a d) (cons a d)]))

;; ===========================================================================
;; W2a --- rember SYMBOLIC examples
;; ===========================================================================
(test "W2a rember: canonical satisfies all 3 symbolic examples"
  (run 1 (q)
    (fresh (x1 x2 x3 ea eb)
      (numbero x1) (numbero x2) (numbero x3) (numbero ea) (numbero eb)
      (=/= ea x1) (=/= ea x2) (=/= eb x3) (=/= x1 x2)
      (evalo-u (rember-prog-u rember-canon-u `(rember ,ea (cons ,x1 (cons ,x2 '())))) `(,x1 ,x2))
      (evalo-u (rember-prog-u rember-canon-u `(rember ,eb (cons ,eb (cons ,x3 '())))) `(,x3))
      (evalo-u (rember-prog-u rember-canon-u `(rember ,x1 (cons ,x1 (cons ,x2 '())))) `(,x2))))
  '(_.0))

(test "W2a rember: WRONG-identity body fails the symbolic examples"
  (run 1 (q)
    (fresh (x1 x2 x3 ea eb)
      (numbero x1) (numbero x2) (numbero x3) (numbero ea) (numbero eb)
      (=/= ea x1) (=/= ea x2) (=/= eb x3) (=/= x1 x2)
      (evalo-u (rember-prog-u rember-wrong-u `(rember ,ea (cons ,x1 (cons ,x2 '())))) `(,x1 ,x2))
      (evalo-u (rember-prog-u rember-wrong-u `(rember ,eb (cons ,eb (cons ,x3 '())))) `(,x3))
      (evalo-u (rember-prog-u rember-wrong-u `(rember ,x1 (cons ,x1 (cons ,x2 '())))) `(,x2))))
  '())

;; ===========================================================================
;; W2b --- swap PARTIAL outputs
;; ===========================================================================
(test "W2b swap: canonical satisfies the PARTIAL spec"
  (run 1 (q)
    (fresh (V2 V4)
      (evalo-u (swap-prog-u swap-canon-u '(swap '())) '())
      (evalo-u (swap-prog-u swap-canon-u '(swap (cons 5 '()))) '(5))
      (evalo-u (swap-prog-u swap-canon-u '(swap (cons 5 (cons 6 '())))) `(6 . ,V2))
      (evalo-u (swap-prog-u swap-canon-u '(swap (cons 5 (cons 6 (cons 7 (cons 8 '())))))) `(6 . ,V4))))
  '(_.0))

(test "W2b swap: non-recursive WITNESS also satisfies the PARTIAL spec (weaker)"
  (run 1 (q)
    (fresh (V2 V4)
      (evalo-u (swap-prog-u swap-witness-u '(swap '())) '())
      (evalo-u (swap-prog-u swap-witness-u '(swap (cons 5 '()))) '(5))
      (evalo-u (swap-prog-u swap-witness-u '(swap (cons 5 (cons 6 '())))) `(6 . ,V2))
      (evalo-u (swap-prog-u swap-witness-u '(swap (cons 5 (cons 6 (cons 7 (cons 8 '())))))) `(6 . ,V4))))
  '(_.0))

(test "W2b swap: WITNESS FAILS the FULL ground spec (partial is genuinely weaker)"
  (run 1 (q)
    (evalo-u (swap-prog-u swap-witness-u '(swap (cons 5 (cons 6 (cons 7 (cons 8 '())))))) '(6 5 8 7)))
  '())

(test "W2b swap: canonical satisfies the FULL ground spec (sanity)"
  (run 1 (q)
    (evalo-u (swap-prog-u swap-canon-u '(swap (cons 5 (cons 6 (cons 7 (cons 8 '())))))) '(6 5 8 7)))
  '(_.0))

;; ===========================================================================
;; W2c --- rev-acc INVOLUTION property + ground anchor
;; ===========================================================================
(test "W2c rev: canonical satisfies involution (len 0,1,2) + ground anchor"
  (run 1 (q)
    (fresh (x1 x2)
      (numbero x1) (numbero x2)
      (evalo-u (rev-prog-u rev-canon-u '(rev (rev '() '()) '())) '())
      (evalo-u (rev-prog-u rev-canon-u `(rev (rev (cons ,x1 '()) '()) '())) `(,x1))
      (evalo-u (rev-prog-u rev-canon-u `(rev (rev (cons ,x1 (cons ,x2 '())) '()) '())) `(,x1 ,x2))
      (evalo-u (rev-prog-u rev-canon-u '(rev (cons 5 (cons 6 '())) '())) '(6 5))))
  '(_.0))

(test "W2c rev: IDENTITY body satisfies involution (why the anchor is required)"
  (run 1 (q)
    (fresh (x1 x2)
      (numbero x1) (numbero x2)
      (evalo-u (rev-prog-u rev-identity-u '(rev (rev '() '()) '())) '())
      (evalo-u (rev-prog-u rev-identity-u `(rev (rev (cons ,x1 '()) '()) '())) `(,x1))
      (evalo-u (rev-prog-u rev-identity-u `(rev (rev (cons ,x1 (cons ,x2 '())) '()) '())) `(,x1 ,x2))))
  '(_.0))

(test "W2c rev: IDENTITY body FAILS the ground anchor (rev (5 6) ()) = (6 5)"
  (run 1 (q)
    (evalo-u (rev-prog-u rev-identity-u '(rev (cons 5 (cons 6 '())) '())) '(6 5)))
  '())

(test-summary)
