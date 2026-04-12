(define test-failed #f)

(define-syntax test
  (syntax-rules ()
    ((_ title tested-expression expected-result)
     (begin
       (newline)
       (printf "Testing ~s\n" title)
       (let* ((expected expected-result)
              (produced tested-expression))
         (or (equal? expected produced)
             (begin
               (set! test-failed #t)
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
