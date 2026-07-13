;; last synthesis, whole-body hole, CLASSIC search baseline: fair
;; interleaving `run 1`, plain evalo, NO iterative deepening, NO follower, NO
;; views. Mirrors the absento/example set of
;; experiments/last-full-id-views.scm exactly, for an apples-to-apples
;; comparison against that arm's "current best" configuration.
;;
;; Run via `./run.sh synthesis/last-full-classic.scm`.

(define (last-prog q body)
  `(letrec ([last (lambda (l) : ((list) -> number)
                    ,q)])
     ,body))

(time-test "last no follower, classic search"
  (run 1 (q)
    (absento 5 q)
    (absento 6 q)
    (absento 7 q)
    ;; ex1
    (evalo (last-prog q '(last (cons 5 '()))) 5)
    ;; ex2
    (evalo (last-prog q '(last (cons 5 (cons 6 '())))) 6)
    ;; ex3
    (evalo (last-prog q '(last (cons 5 (cons 6 (cons 7 '()))))) 7))
  ;; classic search found a DIFFERENT, NON-RECURSIVE program: a 3-level
  ;; nested match that hard-codes the answer for each example length (1, 2,
  ;; 3) with no call to `last` at all. Correct on the given examples but does
  ;; not generalize past length 3 -- a genuine overfit, not the canonical
  ;; recursive definition. The outer '() branch is dead on all examples (see
  ;; experiments/last-full-id-views.scm's "DEAD NIL BRANCH" note), hence the
  ;; fresh _.0 filler there too. See claude/ notebook entry for this
  ;; benchmark.
  '(((match l
       ['() _.0]
       [(cons _.1 _.2)
        (match _.2
          ['() _.1]
          [(cons _.3 _.4)
           (match _.4
             ['() _.3]
             [(cons _.5 _.6) _.5])])])
     (=/= ((_.1 _.2)) ((_.1 match)) ((_.2 match)) ((_.3 _.4)) ((_.3 match)) ((_.4 match)))
     (sym _.1 _.2 _.3 _.4 _.5 _.6)
     (absento (5 _.0) (6 _.0) (7 _.0)))))
