;; append-assoc-property-id-ty.scm --- WAVE 2b: PROPERTY / relational spec.
;; append ASSOCIATIVITY  app(app(a,b),c) = app(a, app(b,c))  over symbolic
;; bounded-shape inputs, PLUS one ground anchor.  UNTYPED generator + TY view.
;;
;; Unlike rev-involution (whose RHS is the KNOWN input, so it fixes the answer),
;; associativity's RHS is CANDIDATE-DEPENDENT and is satisfied by the return-l,
;; return-s and constant-() degenerates (proven in wave2b-property-gates.scm).
;; So the property ALONE under-pins; the single ground anchor
;;   (append (3 4) (5)) = (3 4 5)
;; kills every degenerate and forces recursion.  This arm is the FLAGSHIP:
;; property + minimal anchor.  Compare against:
;;   append-anchor-only-id-ty.scm   (the SAME anchor, no property) -> isolates
;;                                    what the associativity constraint adds
;;   append-assoc-only-id-ty.scm    (property, NO anchor)          -> degenerate
;;
;; The property is E&T-inaccessible: you cannot check app(app(a,b),c) =
;; app(a,app(b,c)) on SYMBOLIC a,b,c by ground forward runs.  ONE interpreter,
;; the same candidate nested in entangled directions, no inverse semantics.
;;
;;   ./run.sh --check-follower-every 1 --main-unsound-depth 1000 \
;;     --timeout 240 experiments/append-assoc-property-id-ty.scm

(load "restricted-interp-untyped.scm")
(load "restricted-interp-untyped-following.scm")
(load "experiments/id-harness.scm")
(load "views.scm") ; R1+R2+TY+NV; defines append-tyenv

(define (append-prog-u q body)
  `(letrec ([append (lambda (l s)
                      ,q)])
     ,body))

;; shapes: (1,1,1) and (2,1,1) associativity, plus the (3 4)(5) ground anchor.
(run-id "append-assoc-property/ty" '(11 15 19 23 27 31 35 39) 1000
  (lambda (bound)
    (run 1 (q)
      (fresh (x1 x2 x3 x4 V1 V2)
        (watch-size q)
        (absento 3 q)
        (absento 4 q)
        (absento 5 q)
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
            (tally/d 'EX (evalo-u/d (append-prog-u q `(append (cons ,x1 (cons ,x2 '())) (append (cons ,x3 '()) (cons ,x4 '())))) V2))
            (tally/d 'EX (evalo-u/d (append-prog-u q '(append (cons 3 (cons 4 '())) (cons 5 '()))) '(3 4 5)))))
        (evalo-u (append-prog-u q `(append (append (cons ,x1 '()) (cons ,x2 '())) (cons ,x3 '()))) V1)
        (evalo-u (append-prog-u q `(append (cons ,x1 '()) (append (cons ,x2 '()) (cons ,x3 '())))) V1)
        (evalo-u (append-prog-u q `(append (append (cons ,x1 (cons ,x2 '())) (cons ,x3 '())) (cons ,x4 '()))) V2)
        (evalo-u (append-prog-u q `(append (cons ,x1 (cons ,x2 '())) (append (cons ,x3 '()) (cons ,x4 '())))) V2)
        (evalo-u (append-prog-u q '(append (cons 3 (cons 4 '())) (cons 5 '()))) '(3 4 5))))))
