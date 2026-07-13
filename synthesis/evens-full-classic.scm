;; evens synthesis, whole-body hole, CLASSIC search baseline: fair
;; interleaving `run 1`, plain evalo, NO iterative deepening, NO follower, NO
;; views. Mirrors the absento/example set of
;; experiments/evens-full-id-views.scm exactly, for an apples-to-apples
;; comparison against that arm's "current best" configuration.
;;
;; Run via `./run.sh synthesis/evens-full-classic.scm`.

(define (evens-prog q body)
  `(letrec ([evens (lambda (l) : ((list) -> list)
                     ,q)])
     ,body))

(time-test "evens no follower, classic search"
  (run 1 (q)
    (absento 5 q)
    (absento 6 q)
    (absento 7 q)
    (absento 8 q)
    ;; ex1
    (evalo (evens-prog q '(evens '())) '())
    ;; ex2
    (evalo (evens-prog q '(evens (cons 5 '()))) '(5))
    ;; ex3
    (evalo (evens-prog q '(evens (cons 5 (cons 6 '())))) '(5))
    ;; ex4
    (evalo (evens-prog q '(evens (cons 5 (cons 6 (cons 7 '()))))) '(5 7))
    ;; ex5
    (evalo (evens-prog q '(evens (cons 5 (cons 6 (cons 7 (cons 8 '())))))) '(5 7)))
  ;; classic search found a DIFFERENT (non-canonical, but correct-on-examples)
  ;; program: both base cases return `l` itself rather than rebuilding '() /
  ;; (cons a '()) -- valid since at each recursive call site l IS bound to the
  ;; matched structure (the same "return l" trick documented for swap's
  ;; machine-minimal answer). See claude/ notebook entry for this benchmark.
  '(((match l
       ['() l]
       [(cons _.0 _.1)
        (match _.1
          ['() l]
          [(cons _.2 _.3) (cons _.0 (evens _.3))])])
     (=/= ((_.0 _.1))
          ((_.0 _.2))
          ((_.0 _.3))
          ((_.0 cons))
          ((_.0 evens))
          ((_.0 l))
          ((_.0 match))
          ((_.1 cons))
          ((_.1 evens))
          ((_.1 l))
          ((_.1 match))
          ((_.2 _.3))
          ((_.2 cons))
          ((_.2 evens))
          ((_.3 cons))
          ((_.3 evens)))
     (sym _.0 _.1 _.2 _.3))))
