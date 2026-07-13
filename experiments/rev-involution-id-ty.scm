;; rev-involution-id-ty.scm --- WAVE 2c: COMPOSITION / PROPERTY spec.
;; UNTYPED generator, WITH the type view (accumulator reverse).  Mirrors
;; rev-acc-untyped-id-ty.scm EXCEPT the I/O examples are the INVOLUTION property
;; `(rev (rev X '()) '()) = X` for symbolic bounded-shape inputs X, applied by
;; NESTING the candidate rev twice in the letrec body.  No per-operator inverse
;; semantics anywhere -- ONE interpreter run of the SAME candidate in entangled
;; directions.  X is a structural list of (numbero ...) vars; the expected
;; output value is the X value itself.
;;
;; rev-tyenv is defined here.  Second parameter `acc` is a pure accumulator, so
;; R2 must commit position 1.  Views wrapped in tally/d ('R1 'R2 'TY 'NV 'EX);
;; examples share 'EX.
;;
;; The examples (vars x1 x2, numbero; NO =/= -- pure involution needs no
;; distinctness, and the gates confirm no degenerate requires it):
;;   involution len 0:  (rev (rev '() '()) '())                       = ()
;;   involution len 1:  (rev (rev (cons x1 '()) '()) '())             = (x1)
;;   involution len 2:  (rev (rev (cons x1 (cons x2 '())) '()) '())   = (x1 x2)
;;   GROUND ANCHOR:     (rev (cons 5 (cons 6 '())) '())               = (6 5)
;;
;; WHY THE ANCHOR IS REQUIRED: involution ALONE is satisfied by the IDENTITY
;; function (id(id(X)) = X), so the involution examples cannot distinguish real
;; reverse from identity.  The single-application ground anchor (rev (5 6) ())
;; = (6 5) kills the identity degenerate -- id((5 6)) = (5 6) /= (6 5).
;; Verified in experiments/wave2-gates.scm: the identity body
;;   (match l ['() '()] [(cons a d) (cons a d)])
;; satisfies all involution examples but FAILS the anchor.  (NOTE: the task
;; brief's suggested "identity" body (cons a l) is NOT an involution witness --
;; it GROWS the list, so it fails involution too; the true identity above is
;; the correct degenerate.)
;;
;; SUSPEND-DEPTH: double application doubles follower depth pressure inside
;; synthesis (a *suspend-depth* concern for the main-loop measurement run, NOT
;; for these gates -- the gates use top-level evalo-u, no follower).  The
;; ground-eval gate on the canonical body at max length 2 runs fast, so length 2
;; is kept; if a synthesis run diverges, drop to length 1.
;;
;;   ./run.sh --check-follower-every 1 --main-unsound-depth 1000 \
;;     --timeout 240 experiments/rev-involution-id-ty.scm

(load "restricted-interp-untyped.scm")
(load "restricted-interp-untyped-following.scm")
(load "experiments/id-harness.scm")
(load "views.scm") ; R1+R2+TY+NV view definitions

(define rev-tyenv '((rev . ((list list) -> list)) (l . list) (acc . list)))

(define (rev-prog-u q body)
  `(letrec ([rev (lambda (l acc)
                   ,q)])
     ,body))

(run-id "rev-involution/ty" '(11 15 19 23 27 31 35 39) 1000
  (lambda (bound)
    (run 1 (q)
      (fresh (x1 x2)
        (watch-size q)
        (absento 5 q)
        (absento 6 q)
        (absento 7 q)
        (numbero x1)
        (numbero x2)
        (follower
          q
          (fresh/d ()
            (tally/d 'R1 (base-case-patho/d 'rev q))
            (tally/d 'R2 (decreasing-recursiono/d 'rev '(l acc) q))
            (tally/d 'TY (type-ofo/d rev-tyenv q 'list))
            (tally/d 'NV (non-vacuous-testso/d q))
            (tally/d 'EX (evalo-u/d (rev-prog-u q '(rev (rev '() '()) '())) '()))
            (tally/d 'EX (evalo-u/d (rev-prog-u q `(rev (rev (cons ,x1 '()) '()) '())) `(,x1)))
            (tally/d 'EX (evalo-u/d (rev-prog-u q `(rev (rev (cons ,x1 (cons ,x2 '())) '()) '())) `(,x1 ,x2)))
            (tally/d 'EX (evalo-u/d (rev-prog-u q '(rev (cons 5 (cons 6 '())) '())) '(6 5)))))
        (evalo-u (rev-prog-u q '(rev (rev '() '()) '())) '())
        (evalo-u (rev-prog-u q `(rev (rev (cons ,x1 '()) '()) '())) `(,x1))
        (evalo-u (rev-prog-u q `(rev (rev (cons ,x1 (cons ,x2 '())) '()) '())) `(,x1 ,x2))
        (evalo-u (rev-prog-u q '(rev (cons 5 (cons 6 '())) '())) '(6 5))))))
