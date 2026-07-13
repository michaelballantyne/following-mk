;; append-assoc-only-id-ty.scm --- WAVE 2b: associativity PROPERTY ALONE, NO
;; ground anchor.  Prediction (from wave2b-property-gates.scm): returns a
;; DEGENERATE (return-l / return-s / constant-()), because the candidate-
;; dependent RHS of associativity is satisfied by all of them, and minimality-
;; first ID takes the smallest.  This is the wave-2 "weak spec admits
;; degenerates" finding, now for a relational property.  UNTYPED generator + TY.
;;
;;   ./run.sh --check-follower-every 1 --main-unsound-depth 1000 \
;;     --timeout 240 experiments/append-assoc-only-id-ty.scm

(load "restricted-interp-untyped.scm")
(load "restricted-interp-untyped-following.scm")
(load "experiments/id-harness.scm")
(load "views.scm") ; R1+R2+TY+NV; defines append-tyenv

(define (append-prog-u q body)
  `(letrec ([append (lambda (l s)
                      ,q)])
     ,body))

(run-id "append-assoc-only/ty" '(11 15 19 23 27 31 35 39) 1000
  (lambda (bound)
    (run 1 (q)
      (fresh (x1 x2 x3 x4 V1 V2)
        (watch-size q)
        (numbero x1)
        (numbero x2)
        (numbero x3)
        (numbero x4)
        (follower
          q
          (fresh/d ()
            (tally/d 'R1 (base-case-patho/d 'append q))
            (tally/d 'R2 (decreasing-recursiono/d 'append '(l s) q))
            (tally/d 'TY (type-ofo/d append-tyenv q 'list))
            (tally/d 'NV (non-vacuous-testso/d q))
            (tally/d 'EX (evalo-u/d (append-prog-u q `(append (append (cons ,x1 '()) (cons ,x2 '())) (cons ,x3 '()))) V1))
            (tally/d 'EX (evalo-u/d (append-prog-u q `(append (cons ,x1 '()) (append (cons ,x2 '()) (cons ,x3 '())))) V1))
            (tally/d 'EX (evalo-u/d (append-prog-u q `(append (append (cons ,x1 (cons ,x2 '())) (cons ,x3 '())) (cons ,x4 '()))) V2))
            (tally/d 'EX (evalo-u/d (append-prog-u q `(append (cons ,x1 (cons ,x2 '())) (append (cons ,x3 '()) (cons ,x4 '())))) V2))))
        (evalo-u (append-prog-u q `(append (append (cons ,x1 '()) (cons ,x2 '())) (cons ,x3 '()))) V1)
        (evalo-u (append-prog-u q `(append (cons ,x1 '()) (append (cons ,x2 '()) (cons ,x3 '())))) V1)
        (evalo-u (append-prog-u q `(append (append (cons ,x1 (cons ,x2 '())) (cons ,x3 '())) (cons ,x4 '()))) V2)
        (evalo-u (append-prog-u q `(append (cons ,x1 (cons ,x2 '())) (append (cons ,x3 '()) (cons ,x4 '())))) V2)))))
