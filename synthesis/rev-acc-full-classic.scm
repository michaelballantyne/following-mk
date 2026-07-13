;; accumulator-reverse synthesis, whole-body hole, CLASSIC search baseline:
;; fair interleaving `run 1`, plain evalo, NO iterative deepening, NO
;; follower, NO views. Mirrors the absento/example set of
;; experiments/rev-acc-full-id-views.scm exactly, for an apples-to-apples
;; comparison against that arm's "current best" configuration.
;;
;; Run via `./run.sh synthesis/rev-acc-full-classic.scm`.

(define (rev-prog q body)
  `(letrec ([rev (lambda (l acc) : ((list list) -> list)
                   ,q)])
     ,body))

(time-test "rev-acc no follower, classic search"
  (run 1 (q)
    (absento 5 q)
    (absento 6 q)
    (absento 7 q)
    ;; ex1
    (evalo (rev-prog q '(rev '() '())) '())
    ;; ex2
    (evalo (rev-prog q '(rev (cons 5 '()) '())) '(5))
    ;; ex3
    (evalo (rev-prog q '(rev (cons 5 (cons 6 '())) '())) '(6 5))
    ;; ex4
    (evalo (rev-prog q '(rev (cons 5 (cons 6 (cons 7 '()))) '())) '(7 6 5)))
  ;; classic search found a DIFFERENT, NON-RECURSIVE program: a 4-level
  ;; nested match hardcoding the accumulator-consing pattern for lengths
  ;; 0..3, with no call to `rev` anywhere. Correct on the given examples
  ;; (which only probe lengths 0..3) but does NOT generalize to length 4+.
  ;; A genuine overfit. Also ~600x the unify(main) cost of the other classic
  ;; arms (14.1M vs tens/hundreds of thousands) -- see claude/ notebook entry
  ;; for this benchmark.
  '(((match l
       ['() acc]
       [(cons _.0 _.1)
        (match _.1
          ['() l]
          [(cons _.2 _.3)
           (match _.3
             ['() (cons _.2 (cons _.0 _.3))]
             [(cons _.4 _.5) (cons _.4 (cons _.2 (cons _.0 _.5)))])])])
     (=/= ((_.0 _.1))
          ((_.0 _.2))
          ((_.0 _.3))
          ((_.0 _.4))
          ((_.0 _.5))
          ((_.0 cons))
          ((_.0 l))
          ((_.0 match))
          ((_.1 cons))
          ((_.1 l))
          ((_.1 match))
          ((_.2 _.3))
          ((_.2 _.4))
          ((_.2 _.5))
          ((_.2 cons))
          ((_.2 match))
          ((_.3 cons))
          ((_.3 match))
          ((_.4 _.5))
          ((_.4 cons))
          ((_.5 cons)))
     (sym _.0 _.1 _.2 _.3 _.4 _.5))))
