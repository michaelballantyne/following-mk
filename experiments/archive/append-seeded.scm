;; append-seeded.scm --- append whole-body-hole synthesis with the match
;; skeleton SEEDED, leaving two holes: h1 for the '() branch, h2 for the
;; (cons a d) branch.  Companion to experiments/rember-seeded.scm; see
;; that file and claude/2026-07-12-174500-size-bounded-id-verdict.md for
;; motivation (seeding makes the low-size candidate population
;; example-refutable).  Plain FAIR search, no size bound.
;;
;; Expected answer: h1 = s, h2 = (cons a (append d s)).
;;
;; Run via:
;;   ./run.sh --timeout 900 experiments/append-seeded.scm

(define (append-prog h1 h2 body)
  `(letrec ([append (lambda (l s) : ((list list) -> list)
                      (match l
                        ['() ,h1]
                        [(cons a d) ,h2]))])
     ,body))

;; --- sanity check: the expected ground answer passes both examples ---

(test "append-seeded ground sanity"
  (run 1 (q)
    (fresh (h1 h2)
      (== q (list h1 h2))
      (== h1 's)
      (== h2 '(cons a (append d s)))
      (evalo (append-prog h1 h2 '(append '() (cons 5 (cons 6 '())))) '(5 6))
      (evalo (append-prog h1 h2 '(append (cons 3 (cons 4 (cons 5 '()))) (cons 6 (cons 7 '()))))
             '(3 4 5 6 7))))
  '((s (cons a (append d s)))))

;; --- arm A: fair search, no follower ------------------------------------

(time-test "append-seeded no follower"
  (run 1 (q)
    (fresh (h1 h2)
      (== q (list h1 h2))
      (absento '3 q)
      (absento '4 q)
      (absento '5 q)
      (absento '6 q)
      (absento '7 q)
      ;; ex1
      (evalo (append-prog h1 h2 '(append '() (cons 5 (cons 6 '())))) '(5 6))
      ;; ex2
      (evalo (append-prog h1 h2 '(append (cons 3 (cons 4 (cons 5 '()))) (cons 6 (cons 7 '()))))
             '(3 4 5 6 7))))
  '((s (cons a (append d s)))))

;; --- arm B: fair search + follower ---------------------------------------

(time-test "append-seeded with follower"
  (run 1 (q)
    (fresh (h1 h2)
      (== q (list h1 h2))
      (absento '3 q)
      (absento '4 q)
      (absento '5 q)
      (absento '6 q)
      (absento '7 q)
      (follower
        q
        (fresh/d ()
          (evalo/d (append-prog h1 h2 '(append '() (cons 5 (cons 6 '())))) '(5 6))
          (evalo/d (append-prog h1 h2 '(append (cons 3 (cons 4 (cons 5 '()))) (cons 6 (cons 7 '()))))
                   '(3 4 5 6 7))))
      (evalo (append-prog h1 h2 '(append '() (cons 5 (cons 6 '())))) '(5 6))
      (evalo (append-prog h1 h2 '(append (cons 3 (cons 4 (cons 5 '()))) (cons 6 (cons 7 '()))))
             '(3 4 5 6 7))))
  '((s (cons a (append d s)))))
