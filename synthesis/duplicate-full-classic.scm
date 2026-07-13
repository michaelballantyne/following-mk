;; duplicate synthesis, whole-body hole, CLASSIC search baseline: fair
;; interleaving `run 1`, plain (untyped-mode-free) evalo, NO iterative
;; deepening, NO follower, NO views. Mirrors the absento/example set of
;; experiments/duplicate-full-id-views.scm exactly, for an apples-to-apples
;; comparison against that arm's "current best" configuration.
;;
;; Run via `./run.sh synthesis/duplicate-full-classic.scm`.

(define (duplicate-prog q body)
  `(letrec ([duplicate (lambda (l) : ((list) -> list)
                         ,q)])
     ,body))

(time-test "duplicate no follower, classic search"
  (run 1 (q)
    (absento 3 q)
    (absento 4 q)
    (absento 5 q)
    ;; ex1
    (evalo (duplicate-prog q '(duplicate '())) '())
    ;; ex2
    (evalo (duplicate-prog q '(duplicate (cons 5 '()))) '(5 5))
    ;; ex3
    (evalo (duplicate-prog q '(duplicate (cons 3 (cons 4 '())))) '(3 3 4 4)))
  '(((match l
       ['() l]
       [(cons _.0 _.1) (cons _.0 (cons _.0 (duplicate _.1)))])
     (=/= ((_.0 _.1))
          ((_.0 cons))
          ((_.0 duplicate))
          ((_.1 cons))
          ((_.1 duplicate)))
     (sym _.0 _.1))))
