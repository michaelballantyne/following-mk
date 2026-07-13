;; swap synthesis, whole-body hole, CLASSIC search baseline: fair
;; interleaving `run 1`, plain evalo, NO iterative deepening, NO follower, NO
;; views. Mirrors the absento/example set of
;; experiments/swap-full-id-views.scm exactly, for an apples-to-apples
;; comparison against that arm's "current best" configuration. Asserts the
;; header's "human" canonical answer (size 74); note the machine found a
;; smaller size-63 answer under ID+views (see that file's header) -- that's
;; a separate, expected divergence, not a bug here.
;;
;; Run via `./run.sh synthesis/swap-full-classic.scm`.

(define (swap-prog q body)
  `(letrec ([swap (lambda (l) : ((list) -> list)
                    ,q)])
     ,body))

(time-test "swap no follower, classic search"
  (run 1 (q)
    (absento 5 q)
    (absento 6 q)
    (absento 7 q)
    (absento 8 q)
    ;; ex1
    (evalo (swap-prog q '(swap '())) '())
    ;; ex2
    (evalo (swap-prog q '(swap (cons 5 '()))) '(5))
    ;; ex3
    (evalo (swap-prog q '(swap (cons 5 (cons 6 '())))) '(6 5))
    ;; ex4
    (evalo (swap-prog q '(swap (cons 5 (cons 6 (cons 7 (cons 8 '())))))) '(6 5 8 7)))
  ;; classic search found the SAME machine-minimal (size-63) trick documented
  ;; in experiments/swap-full-id-views.scm's header: both base cases return
  ;; `l` itself rather than rebuilding '() / (cons a '()), which is valid
  ;; since l IS the matched structure at that point. Still a correct,
  ;; fully-general recursive program -- just not the header's "human"
  ;; canonical (size 74).
  '(((match l
       ['() l]
       [(cons _.0 _.1)
        (match _.1
          ['() l]
          [(cons _.2 _.3) (cons _.2 (cons _.0 (swap _.3)))])])
     (=/= ((_.0 _.1))
          ((_.0 _.2))
          ((_.0 _.3))
          ((_.0 cons))
          ((_.0 l))
          ((_.0 match))
          ((_.0 swap))
          ((_.1 cons))
          ((_.1 l))
          ((_.1 match))
          ((_.1 swap))
          ((_.2 _.3))
          ((_.2 cons))
          ((_.2 swap))
          ((_.3 cons))
          ((_.3 swap)))
     (sym _.0 _.1 _.2 _.3))))
