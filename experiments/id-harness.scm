;; id-harness.scm --- iterative-deepening experiment harness.
;;
;; The central experiment: does the follower's pruning convert to large
;; savings when the main search is *size-closed* (iterative deepening on
;; program size, via *max-term-size*) rather than fair-interleaved?
;;
;; (run-id name bounds main-unsound-depth run-thunk)
;;   name              a string label for the arm
;;   bounds            a list of size bounds, tried in ascending order
;;   main-unsound-depth value for *main-unsound-depth* during each level
;;   run-thunk         (lambda (bound) ...) that performs the `run 1`
;;                     query and returns its result list.  The thunk
;;                     itself parameterizes nothing; the harness sets
;;                     *max-term-size* and *main-unsound-depth* around
;;                     the call.  The thunk's own goals must install the
;;                     watched term with (watch-size q) as the first goal.
;;
;; For each bound, in order, the harness:
;;   - parameterizes *max-term-size* = bound, *main-unsound-depth* = m-u-d
;;   - times the run-thunk with (real-time)
;;   - reads the counter globals *after* the run returns (the `run` macro
;;     resets counters at its start and prints them at its end, so a
;;     per-level snapshot has to be taken here, after the thunk returns)
;;   - prints one [LEVEL ...] line and flushes (so output survives a kill)
;;   - accumulates unify-main / conde-main / unify-follower / time
;;   - STOPS at the first level whose result is non-empty, then prints a
;;     final [TOTAL ...] line with the cumulative numbers and the answer.
;;
;; The printed per-run counter dumps from the `run` macro are left
;; interleaved in the output; the [LEVEL]/[TOTAL] lines are the summary.

(define (run-id name bounds main-unsound-depth run-thunk)
  (let loop ([bounds bounds]
             [tot-unify-main 0]
             [tot-conde-main 0]
             [tot-unify-follower 0]
             [tot-time 0])
    (if (null? bounds)
        ;; Exhausted the bounds without finding an answer.
        (begin
          (printf
           "[TOTAL ~a EXHAUSTED unify-main=~a conde-main=~a unify-follower=~a time-ms=~a answer=()]\n"
           name tot-unify-main tot-conde-main tot-unify-follower tot-time)
          (flush-output-port (current-output-port)))
        (let ([bound (car bounds)])
          (let* ([t0 (real-time)]
                 [result (parameterize ([*max-term-size* bound]
                                        [*main-unsound-depth* main-unsound-depth])
                           (run-thunk bound))]
                 [t1 (real-time)]
                 ;; Snapshot counters immediately, before the next level's
                 ;; `run` resets them.
                 [unify-main *main-unify-counter*]
                 [unify-follower *follower-unify-counter*]
                 [conde-main *main-conde-counter*]
                 [conde/d *conde/d-counter*]
                 [size-cut *size-cutoff-counter*]
                 [depth-cut *main-unsound-depth-cutoff-counter*]
                 [fail *fail-counter*]
                 [dt (- t1 t0)]
                 [answers (length result)]
                 [tot-unify-main (+ tot-unify-main unify-main)]
                 [tot-conde-main (+ tot-conde-main conde-main)]
                 [tot-unify-follower (+ tot-unify-follower unify-follower)]
                 [tot-time (+ tot-time dt)])
            (printf
             "[LEVEL ~a bound=~a answers=~a unify-main=~a conde-main=~a unify-follower=~a conde/d=~a size-cut=~a depth-cut=~a fail=~a time-ms=~a]\n"
             name bound answers unify-main conde-main unify-follower conde/d
             size-cut depth-cut fail dt)
            (flush-output-port (current-output-port))
            (if (null? result)
                (loop (cdr bounds)
                      tot-unify-main
                      tot-conde-main
                      tot-unify-follower
                      tot-time)
                (begin
                  (printf
                   "[TOTAL ~a bound=~a unify-main=~a conde-main=~a unify-follower=~a time-ms=~a answer=~s]\n"
                   name bound tot-unify-main tot-conde-main tot-unify-follower
                   tot-time result)
                  (flush-output-port (current-output-port)))))))))
