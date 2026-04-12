#lang racket/base

;; raco fmt config for following-mk.
;;
;; Teaches the formatter about the miniKanren / follower forms used in this
;; repo so that they indent body-style (like lambda) rather than
;; aligned-under-operator.
;;
;; Run with: raco fmt -i <file.scm>

(provide the-formatter-map)
(require fmt/conventions fmt/core fmt/common racket/match)

;; Force the children of a conde/conde/d clause onto separate vertical
;; lines aligned under the first child.  For conde/d that's always
;; ([vars] [guards] [body]) (exactly three); for conde it's the goals
;; of the clause.
(define-pretty format-conde-clause
  #:type values
  (match doc
    [(node _ _ _ '() xs)
     (pretty-node
      (try-indent #:n 0 #:because-of xs ((format-vertical/helper) xs)))]
    [_ (pretty doc)]))

;; Dispatch `lambda` on shape.  The interpreter test programs use the
;; typed form `(lambda (args) : type body)` inside quasiquoted data.
;; When we see a `:` in the third position, format it as 3 head args
;; (args, :, type) + body; otherwise use the normal 1 head + body rule.
(define (format-lambda doc)
  (define has-colon?
    (and (node? doc)
         (let loop ([xs (node-content doc)] [seen-head? #f] [seen-args? #f])
           (cond
             [(null? xs) #f]
             [(not (visible? (car xs))) (loop (cdr xs) seen-head? seen-args?)]
             [(not seen-head?) (loop (cdr xs) #t seen-args?)]
             [(not seen-args?) (loop (cdr xs) #t #t)]
             [else (and (atom? (car xs))
                        (equal? (atom-content (car xs)) ":"))]))))
  (if has-colon?
      ((format-uniform-body/helper 3 #:require-body? #f) doc)
      ((format-uniform-body/helper 1) doc)))

(define (the-formatter-map s)
  (case s
    [("lambda") format-lambda]
    ;; Body forms: N head args, the rest is the body (indented 2 from the
    ;; opening paren of the form).
    [("fresh" "fresh/d" "run*") (format-uniform-body/helper 1)]
    [("run") (format-uniform-body/helper 2)]
    ;; (follower name term goal) — always put all arguments on their own
    ;; lines, indented 2 (like `time`).
    [("follower") (format-uniform-body/helper 0)]
    ;; (test name expr expected) / (example name expr) — name is head, rest is body.
    ;; time-test and time-example are timed variants.
    [("test" "example" "time-test" "time-example") (format-uniform-body/helper 1)]
    ;; (time body) — always put the argument on its own line, indented 2.
    [("time") (format-uniform-body/helper 0)]
    ;; conde and conde/d: each clause on its own line, and each clause's
    ;; goals (for conde) or three sub-lists (for conde/d) split onto
    ;; separate vertical lines aligned under the first child.
    [("conde" "conde/d")
     (format-uniform-body/helper 0
       #:body-formatter format-conde-clause
       #:require-body? #f)]
    ;; case-inf/d: 1 head arg (the stream), then clauses like `case`.
    [("case-inf/d")
     (format-uniform-body/helper 1
       #:body-formatter (format-clause-2/indirect)
       #:require-body? #f)]
    [else #f]))
