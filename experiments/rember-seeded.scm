;; rember-seeded.scm --- rember whole-body-hole synthesis with the match
;; skeleton SEEDED, leaving two holes: h1 for the '() branch, h2 for the
;; (cons a d) branch.
;;
;; Context: claude/2026-07-12-174500-size-bounded-id-verdict.md found
;; that in whole-body-hole synthesis (the whole lambda body is one
;; hole), candidates below the match-skeleton size threshold are
;; caseless recursive calls -- divergent on every input, hence
;; unrefutable by examples (an example-driven evaluator, leader or
;; follower, can't finitely show a divergent term wrong). That starves
;; the follower of anything to prune on this benchmark family.
;;
;; This experiment seeds the match skeleton into the program shape, so
;; EVERY candidate has a base case ('() branch) and a structural
;; recursion point (cons branch) already fixed -- the low-size
;; population becomes example-refutable by construction. Search regime
;; is plain FAIR search: no *max-term-size*, no watch-size, no
;; *main-unsound-depth* -- the regime where the follower historically
;; showed 5-6x (see synthesis/rember-full.scm and the 2026-04-12
;; search-order note). Question: does seeding alone recover the
;; follower's value under fair search?
;;
;; Expected answer: h1 = l, h2 = (if (= a e) d (cons a (rember e d))).
;;
;; Run via:
;;   ./run.sh --timeout 900 experiments/rember-seeded.scm
;;
;; With a follower check-throttle:
;;   ./run.sh --timeout 900 --check-follower-every 20 experiments/rember-seeded.scm

(define (rember-prog h1 h2 body)
  `(letrec ([rember (lambda (e l) : ((number list) -> list)
                      (match l
                        ['() ,h1]
                        [(cons a d) ,h2]))])
     ,body))

;; --- sanity check: the expected ground answer passes all 4 examples ---

(test "rember-seeded ground sanity"
  (run 1 (q)
    (fresh (h1 h2)
      (== q (list h1 h2))
      (== h1 'l)
      (== h2 '(if (= a e) d (cons a (rember e d))))
      (evalo (rember-prog h1 h2 '(rember 5 '())) '())
      (evalo (rember-prog h1 h2 '(rember 6 (cons 6 '()))) '())
      (evalo (rember-prog h1 h2 '(rember 7 (cons 3 (cons 4 (cons 7 (cons 6 '())))))) '(3 4 6))
      (evalo (rember-prog h1 h2 '(rember 5 (cons 3 (cons 4 (cons 6 (cons 7 '())))))) '(3 4 6 7))))
  '((l (if (= a e) d (cons a (rember e d))))))

;; --- arm A: fair search, no follower ------------------------------------

(time-test "rember-seeded no follower"
  (run 1 (q)
    (fresh (h1 h2)
      (== q (list h1 h2))
      (absento 3 q)
      (absento 4 q)
      (absento 5 q)
      (absento 6 q)
      (absento 7 q)
      ;; ex1
      (evalo (rember-prog h1 h2 '(rember 5 '())) '())
      ;; ex2
      (evalo (rember-prog h1 h2 '(rember 6 (cons 6 '()))) '())
      ;; ex3
      (evalo (rember-prog h1 h2 '(rember 7 (cons 3 (cons 4 (cons 7 (cons 6 '())))))) '(3 4 6))
      ;; ex4
      (evalo (rember-prog h1 h2 '(rember 5 (cons 3 (cons 4 (cons 6 (cons 7 '())))))) '(3 4 6 7))))
  '((l (if (= a e) d (cons a (rember e d))))))

;; --- arm B: fair search + follower ---------------------------------------

(time-test "rember-seeded with follower"
  (run 1 (q)
    (fresh (h1 h2)
      (== q (list h1 h2))
      (absento 3 q)
      (absento 4 q)
      (absento 5 q)
      (absento 6 q)
      (absento 7 q)
      (follower
        q
        (fresh/d ()
          (evalo/d (rember-prog h1 h2 '(rember 5 '())) '())
          (evalo/d (rember-prog h1 h2 '(rember 6 (cons 6 '()))) '())
          (evalo/d (rember-prog h1 h2 '(rember 7 (cons 3 (cons 4 (cons 7 (cons 6 '())))))) '(3 4 6))
          (evalo/d (rember-prog h1 h2 '(rember 5 (cons 3 (cons 4 (cons 6 (cons 7 '())))))) '(3 4 6 7))))
      (evalo (rember-prog h1 h2 '(rember 5 '())) '())
      (evalo (rember-prog h1 h2 '(rember 6 (cons 6 '()))) '())
      (evalo (rember-prog h1 h2 '(rember 7 (cons 3 (cons 4 (cons 7 (cons 6 '())))))) '(3 4 6))
      (evalo (rember-prog h1 h2 '(rember 5 (cons 3 (cons 4 (cons 6 (cons 7 '())))))) '(3 4 6 7))))
  '((l (if (= a e) d (cons a (rember e d))))))
