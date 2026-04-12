(define test-failed #f)
(define test-count 0)
(define test-fail-count 0)

(define-syntax test
  (syntax-rules ()
    ((_ title tested-expression expected-result)
     (begin
       (newline)
       (printf "Testing ~s\n" title)
       (set! test-count (+ test-count 1))
       (let* ((expected expected-result)
              (produced tested-expression))
         (or (equal? expected produced)
             (begin
               (set! test-failed #t)
               (set! test-fail-count (+ test-fail-count 1))
               (printf "Failed: ~s~%Expected: ~s~%Computed: ~s~%"
                     'tested-expression expected produced))))))))

(define-syntax example
  (syntax-rules ()
    ((_ title expression)
     (begin
       (newline)
       (printf "Example ~s\n" title)
       (let ((result expression))
         (printf "  => ~s\n" result))))))

(define-syntax time-test
  (syntax-rules ()
    ((_ title tested-expression expected-result)
     (time (test title tested-expression expected-result)))))

(define-syntax time-example
  (syntax-rules ()
    ((_ title expression)
     (time (example title expression)))))

(define (test-summary)
  (newline)
  (if test-failed
      (printf "~a/~a tests passed, ~a FAILED\n"
              (- test-count test-fail-count) test-count test-fail-count)
      (printf "All ~a tests passed.\n" test-count)))
