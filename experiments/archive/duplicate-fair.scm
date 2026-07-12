;; duplicate-fair.scm --- fair-search (interleaved, no size bound, no
;; follower) reference arm for `duplicate`, matching synthesis/append-full.scm's
;; "no follower" style.  This is the un-size-closed regime: may or may not
;; terminate within a reasonable time.  Run it under a hard wall-clock cap:
;;
;;   ./run.sh --timeout 120 experiments/duplicate-fair.scm
;;
;; time-example (not time-test) is used deliberately: we don't know in
;; advance which of the two logically-equivalent reifications ('() vs l in
;; the base case) the fair interleaved search will hit first, so there is no
;; single "expected" s-expression to assert against here.

(define (duplicate-prog q body)
  `(letrec ([duplicate (lambda (l) : ((list) -> list)
                          ,q)])
     ,body))

(time-example "duplicate no follower (fair search, no size bound, 120s cap)"
  (run 1 (q)
    (absento 3 q)
    (absento 4 q)
    (absento 5 q)
    (evalo (duplicate-prog q '(duplicate '())) '())
    (evalo (duplicate-prog q '(duplicate (cons 5 '()))) '(5 5))
    (evalo (duplicate-prog q '(duplicate (cons 3 (cons 4 '())))) '(3 3 4 4))))
