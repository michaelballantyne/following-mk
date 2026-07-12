;; new-tasks-gates.scm --- re-runnable gates for the six new synthesis tasks
;; (member?, last, swap-pairs, evens, rev-acc, interleave).  Cheap checks only.
;;
;;   ./run.sh experiments/new-tasks-gates.scm
;;
;; For each task, three gate families:
;;   (1) EVAL: ground-evaluate the canonical body on every example (must yield
;;       the expected output) plus one wrong output per task (must fail).
;;   (2) VIEWS: each follower view accepts the canonical ground body --
;;       base-case-patho/d, decreasing-recursiono/d, type-ofo/d, and
;;       non-vacuous-testso/d.  interleave's R2 is expected to REFUTE (finding).
;;   (3) WIRING: run each task's ID arm with a tiny bounds list capped well
;;       below the answer, just to prove the harness/follower stack executes.

(load "experiments/id-harness.scm")
(load "experiments/termination-view4.scm") ; R1..R4 + tyenv examples

;; ---------------------------------------------------------------------------
;; program templates + tyenvs (mirror the six *-full-id-tv4ex.scm files)
;; ---------------------------------------------------------------------------
(define (member-prog q body)
  `(letrec ([member (lambda (e l) : ((number list) -> number) ,q)]) ,body))
(define member-tyenv '((member . ((number list) -> number)) (e . number) (l . list)))
(define member-canon '(match l ['() 0] [(cons a d) (if (= a e) 1 (member e d))]))

(define (last-prog q body)
  `(letrec ([last (lambda (l) : ((list) -> number) ,q)]) ,body))
(define last-tyenv '((last . ((list) -> number)) (l . list)))
(define last-canon '(match l ['() 0] [(cons a d) (match d ['() a] [(cons b dd) (last dd)])]))

(define (swap-prog q body)
  `(letrec ([swap (lambda (l) : ((list) -> list) ,q)]) ,body))
(define swap-tyenv '((swap . ((list) -> list)) (l . list)))
(define swap-canon
  '(match l ['() '()] [(cons a d) (match d ['() (cons a '())] [(cons b dd) (cons b (cons a (swap dd)))])]))

(define (evens-prog q body)
  `(letrec ([evens (lambda (l) : ((list) -> list) ,q)]) ,body))
(define evens-tyenv '((evens . ((list) -> list)) (l . list)))
(define evens-canon
  '(match l ['() '()] [(cons a d) (match d ['() (cons a '())] [(cons b dd) (cons a (evens dd))])]))

(define (rev-prog q body)
  `(letrec ([rev (lambda (l acc) : ((list list) -> list) ,q)]) ,body))
(define rev-tyenv '((rev . ((list list) -> list)) (l . list) (acc . list)))
(define rev-canon '(match l ['() acc] [(cons a d) (rev d (cons a acc))]))

(define (interleave-prog q body)
  `(letrec ([interleave (lambda (l1 l2) : ((list list) -> list) ,q)]) ,body))
(define interleave-tyenv '((interleave . ((list list) -> list)) (l1 . list) (l2 . list)))
(define interleave-canon '(match l1 ['() l2] [(cons a d) (cons a (interleave l2 d))]))

;; ===========================================================================
;; (1) EVAL gates: canonical body evaluates to the expected output on examples,
;;     and fails on a wrong output.
;; ===========================================================================

;; member
(test "EVAL member ex1 (member 5 ())=0"
  (run 1 (v) (evalo (member-prog member-canon '(member 5 '())) v)) '(0))
(test "EVAL member ex2 (member 5 (5))=1"
  (run 1 (v) (evalo (member-prog member-canon '(member 5 (cons 5 '()))) v)) '(1))
(test "EVAL member ex3 (member 5 (6))=0"
  (run 1 (v) (evalo (member-prog member-canon '(member 5 (cons 6 '()))) v)) '(0))
(test "EVAL member ex4 (member 5 (6 5))=1"
  (run 1 (v) (evalo (member-prog member-canon '(member 5 (cons 6 (cons 5 '())))) v)) '(1))
(test "EVAL member WRONG (member 5 (5)) /= 0"
  (run 1 (v) (evalo (member-prog member-canon '(member 5 (cons 5 '()))) 0)) '())

;; last
(test "EVAL last ex1 (last (5))=5"
  (run 1 (v) (evalo (last-prog last-canon '(last (cons 5 '()))) v)) '(5))
(test "EVAL last ex2 (last (5 6))=6"
  (run 1 (v) (evalo (last-prog last-canon '(last (cons 5 (cons 6 '())))) v)) '(6))
(test "EVAL last ex3 (last (5 6 7))=7"
  (run 1 (v) (evalo (last-prog last-canon '(last (cons 5 (cons 6 (cons 7 '()))))) v)) '(7))
(test "EVAL last WRONG (last (5 6)) /= 5"
  (run 1 (v) (evalo (last-prog last-canon '(last (cons 5 (cons 6 '())))) 5)) '())

;; swap
(test "EVAL swap ex1 (swap ())=()"
  (run 1 (v) (evalo (swap-prog swap-canon '(swap '())) v)) '(()))
(test "EVAL swap ex2 (swap (5))=(5)"
  (run 1 (v) (evalo (swap-prog swap-canon '(swap (cons 5 '()))) v)) '((5)))
(test "EVAL swap ex3 (swap (5 6))=(6 5)"
  (run 1 (v) (evalo (swap-prog swap-canon '(swap (cons 5 (cons 6 '())))) v)) '((6 5)))
(test "EVAL swap ex4 (swap (5 6 7 8))=(6 5 8 7)"
  (run 1 (v) (evalo (swap-prog swap-canon '(swap (cons 5 (cons 6 (cons 7 (cons 8 '())))))) v)) '((6 5 8 7)))
(test "EVAL swap WRONG (swap (5 6)) /= (5 6)"
  (run 1 (v) (evalo (swap-prog swap-canon '(swap (cons 5 (cons 6 '())))) '(5 6))) '())

;; evens
(test "EVAL evens ex1 (evens ())=()"
  (run 1 (v) (evalo (evens-prog evens-canon '(evens '())) v)) '(()))
(test "EVAL evens ex2 (evens (5))=(5)"
  (run 1 (v) (evalo (evens-prog evens-canon '(evens (cons 5 '()))) v)) '((5)))
(test "EVAL evens ex3 (evens (5 6))=(5)"
  (run 1 (v) (evalo (evens-prog evens-canon '(evens (cons 5 (cons 6 '())))) v)) '((5)))
(test "EVAL evens ex4 (evens (5 6 7))=(5 7)"
  (run 1 (v) (evalo (evens-prog evens-canon '(evens (cons 5 (cons 6 (cons 7 '()))))) v)) '((5 7)))
(test "EVAL evens WRONG (evens (5 6)) /= (5 6)"
  (run 1 (v) (evalo (evens-prog evens-canon '(evens (cons 5 (cons 6 '())))) '(5 6))) '())

;; rev-acc
(test "EVAL rev ex1 (rev () ())=()"
  (run 1 (v) (evalo (rev-prog rev-canon '(rev '() '())) v)) '(()))
(test "EVAL rev ex2 (rev (5) ())=(5)"
  (run 1 (v) (evalo (rev-prog rev-canon '(rev (cons 5 '()) '())) v)) '((5)))
(test "EVAL rev ex3 (rev (5 6) ())=(6 5)"
  (run 1 (v) (evalo (rev-prog rev-canon '(rev (cons 5 (cons 6 '())) '())) v)) '((6 5)))
(test "EVAL rev ex4 (rev (5 6 7) ())=(7 6 5)"
  (run 1 (v) (evalo (rev-prog rev-canon '(rev (cons 5 (cons 6 (cons 7 '()))) '())) v)) '((7 6 5)))
(test "EVAL rev WRONG (rev (5 6) ()) /= (5 6)"
  (run 1 (v) (evalo (rev-prog rev-canon '(rev (cons 5 (cons 6 '())) '())) '(5 6))) '())

;; interleave
(test "EVAL interleave ex1 (interleave () ())=()"
  (run 1 (v) (evalo (interleave-prog interleave-canon '(interleave '() '())) v)) '(()))
(test "EVAL interleave ex2 (interleave () (6))=(6)"
  (run 1 (v) (evalo (interleave-prog interleave-canon '(interleave '() (cons 6 '()))) v)) '((6)))
(test "EVAL interleave ex3 (interleave (5) (6))=(5 6)"
  (run 1 (v) (evalo (interleave-prog interleave-canon '(interleave (cons 5 '()) (cons 6 '()))) v)) '((5 6)))
(test "EVAL interleave ex4 (interleave (5 7) (6 8))=(5 6 7 8)"
  (run 1 (v) (evalo (interleave-prog interleave-canon
                      '(interleave (cons 5 (cons 7 '())) (cons 6 (cons 8 '())))) v)) '((5 6 7 8)))
(test "EVAL interleave WRONG (interleave (5 7) (6 8)) /= (5 7 6 8)"
  (run 1 (v) (evalo (interleave-prog interleave-canon
                      '(interleave (cons 5 (cons 7 '())) (cons 6 (cons 8 '())))) '(5 7 6 8))) '())

;; ===========================================================================
;; (2) VIEW gates: each view accepts (=> '(_.0)) or refutes (=> '()) canonical.
;; ===========================================================================

;; --- R1 base-case-patho/d (all accept) ---
(test "R1 member"     (run 1 (q) (follower q (base-case-patho/d 'member q)     (== q member-canon)))     '(_.0))
(test "R1 last"       (run 1 (q) (follower q (base-case-patho/d 'last q)       (== q last-canon)))       '(_.0))
(test "R1 swap"       (run 1 (q) (follower q (base-case-patho/d 'swap q)       (== q swap-canon)))       '(_.0))
(test "R1 evens"      (run 1 (q) (follower q (base-case-patho/d 'evens q)      (== q evens-canon)))      '(_.0))
(test "R1 rev"        (run 1 (q) (follower q (base-case-patho/d 'rev q)        (== q rev-canon)))        '(_.0))
(test "R1 interleave" (run 1 (q) (follower q (base-case-patho/d 'interleave q) (== q interleave-canon))) '(_.0))

;; --- R2 decreasing-recursiono/d (all accept EXCEPT interleave, which refutes) ---
(test "R2 member"     (run 1 (q) (follower q (decreasing-recursiono/d 'member '(e l) q)   (== q member-canon)))     '(_.0))
(test "R2 last"       (run 1 (q) (follower q (decreasing-recursiono/d 'last '(l) q)        (== q last-canon)))       '(_.0))
(test "R2 swap"       (run 1 (q) (follower q (decreasing-recursiono/d 'swap '(l) q)        (== q swap-canon)))       '(_.0))
(test "R2 evens"      (run 1 (q) (follower q (decreasing-recursiono/d 'evens '(l) q)       (== q evens-canon)))      '(_.0))
(test "R2 rev"        (run 1 (q) (follower q (decreasing-recursiono/d 'rev '(l acc) q)     (== q rev-canon)))        '(_.0))
;; FINDING: interleave's argument-swapping recursion has no fixed decreasing
;; position -> R2 REFUTES.  This is why interleave drops R2 from its stack.
(test "R2 interleave REFUTED (argument-swap; documented finding)"
  (run 1 (q) (follower q (decreasing-recursiono/d 'interleave '(l1 l2) q) (== q interleave-canon))) '())

;; --- TY type-ofo/d (all accept at declared result type) ---
(test "TY member"     (run 1 (q) (follower q (type-ofo/d member-tyenv q 'number)     (== q member-canon)))     '(_.0))
(test "TY last"       (run 1 (q) (follower q (type-ofo/d last-tyenv q 'number)       (== q last-canon)))       '(_.0))
(test "TY swap"       (run 1 (q) (follower q (type-ofo/d swap-tyenv q 'list)         (== q swap-canon)))       '(_.0))
(test "TY evens"      (run 1 (q) (follower q (type-ofo/d evens-tyenv q 'list)        (== q evens-canon)))      '(_.0))
(test "TY rev"        (run 1 (q) (follower q (type-ofo/d rev-tyenv q 'list)          (== q rev-canon)))        '(_.0))
(test "TY interleave" (run 1 (q) (follower q (type-ofo/d interleave-tyenv q 'list)   (== q interleave-canon))) '(_.0))

;; --- NV non-vacuous-testso/d (all accept) ---
(test "NV member"     (run 1 (q) (follower q (non-vacuous-testso/d q) (== q member-canon)))     '(_.0))
(test "NV last"       (run 1 (q) (follower q (non-vacuous-testso/d q) (== q last-canon)))       '(_.0))
(test "NV swap"       (run 1 (q) (follower q (non-vacuous-testso/d q) (== q swap-canon)))       '(_.0))
(test "NV evens"      (run 1 (q) (follower q (non-vacuous-testso/d q) (== q evens-canon)))      '(_.0))
(test "NV rev"        (run 1 (q) (follower q (non-vacuous-testso/d q) (== q rev-canon)))        '(_.0))
(test "NV interleave" (run 1 (q) (follower q (non-vacuous-testso/d q) (== q interleave-canon))) '(_.0))

;; ===========================================================================
;; (3) WIRING gates: tiny bounds (11 15), well below every answer, so each run
;;     EXHAUSTS quickly -- proves the run-id + follower + evalo/d stack executes.
;; ===========================================================================

(run-id "WIRE member" '(11 15) 1000
  (lambda (bound)
    (run 1 (q)
      (watch-size q) (absento 5 q) (absento 6 q)
      (follower q
        (fresh/d ()
          (base-case-patho/d 'member q)
          (decreasing-recursiono/d 'member '(e l) q)
          (type-ofo/d member-tyenv q 'number)
          (non-vacuous-testso/d q)
          (evalo/d (member-prog q '(member 5 '())) 0)
          (evalo/d (member-prog q '(member 5 (cons 5 '()))) 1)))
      (evalo (member-prog q '(member 5 '())) 0)
      (evalo (member-prog q '(member 5 (cons 5 '()))) 1))))

(run-id "WIRE last" '(11 15) 1000
  (lambda (bound)
    (run 1 (q)
      (watch-size q) (absento 5 q) (absento 6 q) (absento 7 q)
      (follower q
        (fresh/d ()
          (base-case-patho/d 'last q)
          (decreasing-recursiono/d 'last '(l) q)
          (type-ofo/d last-tyenv q 'number)
          (non-vacuous-testso/d q)
          (evalo/d (last-prog q '(last (cons 5 '()))) 5)))
      (evalo (last-prog q '(last (cons 5 '()))) 5))))

(run-id "WIRE swap" '(11 15) 1000
  (lambda (bound)
    (run 1 (q)
      (watch-size q) (absento 5 q) (absento 6 q) (absento 7 q) (absento 8 q)
      (follower q
        (fresh/d ()
          (base-case-patho/d 'swap q)
          (decreasing-recursiono/d 'swap '(l) q)
          (type-ofo/d swap-tyenv q 'list)
          (non-vacuous-testso/d q)
          (evalo/d (swap-prog q '(swap (cons 5 (cons 6 '())))) '(6 5))))
      (evalo (swap-prog q '(swap (cons 5 (cons 6 '())))) '(6 5)))))

(run-id "WIRE evens" '(11 15) 1000
  (lambda (bound)
    (run 1 (q)
      (watch-size q) (absento 5 q) (absento 6 q) (absento 7 q)
      (follower q
        (fresh/d ()
          (base-case-patho/d 'evens q)
          (decreasing-recursiono/d 'evens '(l) q)
          (type-ofo/d evens-tyenv q 'list)
          (non-vacuous-testso/d q)
          (evalo/d (evens-prog q '(evens (cons 5 (cons 6 '())))) '(5))))
      (evalo (evens-prog q '(evens (cons 5 (cons 6 '())))) '(5)))))

(run-id "WIRE rev-acc" '(11 15) 1000
  (lambda (bound)
    (run 1 (q)
      (watch-size q) (absento 5 q) (absento 6 q) (absento 7 q)
      (follower q
        (fresh/d ()
          (base-case-patho/d 'rev q)
          (decreasing-recursiono/d 'rev '(l acc) q)
          (type-ofo/d rev-tyenv q 'list)
          (non-vacuous-testso/d q)
          (evalo/d (rev-prog q '(rev (cons 5 (cons 6 '())) '())) '(6 5))))
      (evalo (rev-prog q '(rev (cons 5 (cons 6 '())) '())) '(6 5)))))

;; interleave: R2 OMITTED (see interleave-full-id-tv4ex.scm header / R2 gate).
(run-id "WIRE interleave(noR2)" '(11 15) 1000
  (lambda (bound)
    (run 1 (q)
      (watch-size q) (absento 5 q) (absento 6 q) (absento 7 q) (absento 8 q)
      (follower q
        (fresh/d ()
          (base-case-patho/d 'interleave q)
          (type-ofo/d interleave-tyenv q 'list)
          (non-vacuous-testso/d q)
          (evalo/d (interleave-prog q '(interleave (cons 5 '()) (cons 6 '()))) '(5 6))))
      (evalo (interleave-prog q '(interleave (cons 5 '()) (cons 6 '()))) '(5 6)))))

(test-summary)
