;; interleave synthesis, whole-body hole, CLASSIC search baseline: fair
;; interleaving `run 1`, plain evalo, NO iterative deepening, NO follower, NO
;; views. Mirrors the absento/example set of
;; experiments/interleave-full-id-views.scm (and -r2p.scm) exactly, for an
;; apples-to-apples comparison against interleave's "current best"
;; configuration (which uses R2P, since plain R2 refutes interleave's
;; canonical argument-swapping recursion -- classic search here has no
;; views at all, so that distinction doesn't apply to this baseline).
;;
;; Run via `./run.sh synthesis/interleave-full-classic.scm`.

(define (interleave-prog q body)
  `(letrec ([interleave (lambda (l1 l2) : ((list list) -> list)
                          ,q)])
     ,body))

(time-test "interleave no follower, classic search"
  (run 1 (q)
    (absento 5 q)
    (absento 6 q)
    (absento 7 q)
    (absento 8 q)
    ;; ex1
    (evalo (interleave-prog q '(interleave '() '())) '())
    ;; ex2
    (evalo (interleave-prog q '(interleave '() (cons 6 '()))) '(6))
    ;; ex3
    (evalo (interleave-prog q '(interleave (cons 5 '()) (cons 6 '()))) '(5 6))
    ;; ex4
    (evalo (interleave-prog q '(interleave (cons 5 (cons 7 '())) (cons 6 (cons 8 '())))) '(5 6 7 8)))
  ;; classic search found a DIFFERENT, still fully-general and correct
  ;; program: it adds an extra `match` on _.1 in the else-branch that
  ;; hardcodes the "second recursive-call arg is empty" case to `l2` directly
  ;; instead of computing it through recursion (interleave l2 '() = l2 by
  ;; induction, so this is a provably-equivalent unfolding, not an overfit).
  ;; Larger than the 2-clause canonical but still calls `interleave`
  ;; recursively in the general case.
  '(((match l1
       ['() l2]
       [(cons _.0 _.1)
        (cons _.0
              (match _.1
                ['() l2]
                [(cons _.2 _.3) (interleave l2 _.1)]))])
     (=/= ((_.0 _.1))
          ((_.0 cons))
          ((_.0 interleave))
          ((_.0 l2))
          ((_.0 match))
          ((_.1 _.2))
          ((_.1 _.3))
          ((_.1 cons))
          ((_.1 interleave))
          ((_.1 l2))
          ((_.1 match))
          ((_.2 interleave))
          ((_.2 l2))
          ((_.3 interleave))
          ((_.3 l2)))
     (sym _.0 _.1 _.2 _.3))))
