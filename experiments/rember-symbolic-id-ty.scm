;; rember-symbolic-id-ty.scm --- WAVE 2a: SYMBOLIC (parametric) examples.
;; UNTYPED generator, WITH the type view (rember).  Mirrors
;; rember-untyped-id-ty.scm exactly EXCEPT the four ground I/O examples are
;; replaced by THREE symbolic examples: inputs contain fresh logic vars
;; constrained (numbero ...) that act as symbolic numeric literals in program
;; argument position (the untyped interp's number-literal clause
;; `(numbero expr)(== expr val)` evaluates a numbero var to itself; application
;; args are evaluated at 'I so the clause is live), and outputs reuse those
;; vars.  One symbolic example denotes a whole concrete family; constant-
;; coincidence degenerates (the "evens" incident) are killed structurally by the
;; =/= constraints.
;;
;; The fresh symbolic vars are opened INSIDE the run and constrained
;; numbero + =/= BEFORE the follower, and the SAME vars/terms feed both the
;; in-follower evalo-u/d goals and the top-level evalo-u goals (shared bindings).
;; Each view goal is wrapped in tally/d ('R1 'R2 'TY 'NV 'EX); the three symbolic
;; examples share 'EX.  rember-tyenv is defined in views.scm.
;;
;; The three examples (vars x1 x2 x3 ea eb, all numbero):
;;   (a) e ABSENT from a 2-elt list -> unchanged:
;;       (rember ea (cons x1 (cons x2 '()))) = (x1 x2)   [=/= ea x1, =/= ea x2]
;;   (b) e PRESENT once, equals the head -> head dropped:
;;       (rember eb (cons eb (cons x3 '()))) = (x3)       [=/= eb x3]
;;   (c) SAME list as (a) but e equal to the first element -> first dropped:
;;       (rember x1 (cons x1 (cons x2 '()))) = (x2)       [=/= x1 x2]
;; Examples (a) and (c) are the same-l/different-e PAIR the wave-2 design calls
;; out: identical list structure, different e, so they carry the information
;; that rember depends on e (not just on l) -- the e-independence family the 4c
;; post-mortem showed the old concrete examples could not touch.
;;
;; absento 3..7 on q (kept, as the concrete rember arm does).  Bounds match
;; rember-untyped-id-ty.scm.  Gates in experiments/wave2-gates.scm confirm the
;; canonical rember body satisfies all three and the wrong-identity body fails.
;;
;;   ./run.sh --check-follower-every 1 --main-unsound-depth 1000 \
;;     --timeout 240 experiments/rember-symbolic-id-ty.scm

(load "restricted-interp-untyped.scm")
(load "restricted-interp-untyped-following.scm")
(load "experiments/id-harness.scm")
(load "views.scm") ; R1+R2+TY+NV; defines rember-tyenv

(define (rember-prog-u q body)
  `(letrec ([rember (lambda (e l)
                      ,q)])
     ,body))

(run-id "rember-symbolic/ty" '(15 19 23 27 31 35 39 43 47 51) 1000
  (lambda (bound)
    (run 1 (q)
      (fresh (x1 x2 x3 ea eb)
        (watch-size q)
        (absento 3 q)
        (absento 4 q)
        (absento 5 q)
        (absento 6 q)
        (absento 7 q)
        (numbero x1)
        (numbero x2)
        (numbero x3)
        (numbero ea)
        (numbero eb)
        (=/= ea x1)
        (=/= ea x2)
        (=/= eb x3)
        (=/= x1 x2)
        (follower
          q
          (fresh/d ()
            (tally/d 'R1 (base-case-patho/d 'rember q))
            (tally/d 'R2 (decreasing-recursiono/d 'rember '(e l) q))
            (tally/d 'TY (type-ofo/d rember-tyenv q 'list))
            (tally/d 'NV (non-vacuous-testso/d q))
            (tally/d 'EX (evalo-u/d (rember-prog-u q `(rember ,ea (cons ,x1 (cons ,x2 '())))) `(,x1 ,x2)))
            (tally/d 'EX (evalo-u/d (rember-prog-u q `(rember ,eb (cons ,eb (cons ,x3 '())))) `(,x3)))
            (tally/d 'EX (evalo-u/d (rember-prog-u q `(rember ,x1 (cons ,x1 (cons ,x2 '())))) `(,x2)))))
        (evalo-u (rember-prog-u q `(rember ,ea (cons ,x1 (cons ,x2 '())))) `(,x1 ,x2))
        (evalo-u (rember-prog-u q `(rember ,eb (cons ,eb (cons ,x3 '())))) `(,x3))
        (evalo-u (rember-prog-u q `(rember ,x1 (cons ,x1 (cons ,x2 '())))) `(,x2))))))
