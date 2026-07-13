;; member synthesis, whole-body hole, CLASSIC search baseline: fair
;; interleaving `run 1`, plain evalo, NO iterative deepening, NO follower, NO
;; views. Mirrors the absento/example set of
;; experiments/member-full-id-views.scm exactly, for an apples-to-apples
;; comparison against that arm's "current best" configuration.
;;
;; Run via `./run.sh synthesis/member-full-classic.scm`.

(define (member-prog q body)
  `(letrec ([member (lambda (e l) : ((number list) -> number)
                      ,q)])
     ,body))

(time-test "member no follower, classic search"
  (run 1 (q)
    (absento 5 q)
    (absento 6 q)
    ;; ex1
    (evalo (member-prog q '(member 5 '())) 0)
    ;; ex2
    (evalo (member-prog q '(member 5 (cons 5 '()))) 1)
    ;; ex3
    (evalo (member-prog q '(member 5 (cons 6 '()))) 0)
    ;; ex4
    (evalo (member-prog q '(member 5 (cons 6 (cons 5 '())))) 1))
  ;; classic search found a DIFFERENT, NON-RECURSIVE program: the else-branch
  ;; hardcodes "nonempty tail => 1", never actually recursing/re-checking
  ;; equality past depth 1. Correct on the given examples (which only probe
  ;; depth <=2) but does NOT generalize -- e.g. (member 5 '(6 7)) would
  ;; wrongly return 1. A genuine overfit. See claude/ notebook entry for this
  ;; benchmark.
  '(((match l
       ['() 0]
       [(cons _.0 _.1)
        (if (= _.0 e)
            1
            (match _.1
              ['() 0]
              [(cons _.2 _.3) 1]))])
     (=/= ((_.0 _.1)) ((_.0 e)) ((_.0 if)) ((_.0 match)) ((_.1 e)) ((_.1 if)) ((_.1 match)))
     (sym _.0 _.1 _.2 _.3))))
