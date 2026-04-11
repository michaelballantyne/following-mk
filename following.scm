;; following.scm --- committing conde + follower goals for faster-miniKanren.
;;
;; A "follower" is a conjunct that follows the main search, re-evaluating
;; at each choice point in a determinacy-directed mode: commit only steps
;; that are uniquely forced by the current state, suspend otherwise. This is
;; the same idea as the Andorra Principle from Andorra Prolog -- determinate
;; goals run first, and non-determinate goals wait until they become
;; determinate.
;;
;; The machinery: (conde/d ...) is a committing conde that commits a clause
;; only when exactly one guard succeeds singleton-style; fresh/d binds
;; variables inside such evaluation; the /d-suffixed primitive variants
;; (==/d, =/=/d, symbolo/d, absento/d, numbero/d, stringo/d) are the
;; depth-threaded versions of the basic goal constructors usable inside
;; conde/d and fresh/d. (follower name term goal) installs `goal` as a
;; follower: run it once now, and re-fire at each conde branch point and
;; again at the end of run.
;;
;; Requires mk.scm patched to carry an F slot (follower cell) in the state
;; and to call (trigger-followers) inside conde.

;;; --- check-type: a no-op dispatch; flip to check-type-runtime for sanity checks

(define-syntax check-type
  (syntax-rules ()
    [(_ v pred) v]))

#;(define-syntax check-type
  (syntax-rules ()
    [(_ v pred)
     (check-type-runtime v pred 'pred)]))

(define (check-type-runtime v pred pred-e)
  (if (pred v)
      v
      (error 'check-type (format "expected ~s, got ~s" pred-e v))))

;;; --- depth-limit parameters
;;;
;;; *determinacy-depth-limit-1*: UNSOUND cutoff.  When exceeded, the
;;; follower fails outright.  Intended as a diagnostic knob so that a
;;; diverging branch can be starved out of faster-mk's interleaving scheduler,
;;; making pruning on the surviving branch observable.  NOT a real optimization.
;;;
;;; *determinacy-depth-limit-2*: sound cutoff.  When exceeded, the follower
;;; suspends (returns the entry state paired with a resume thunk), the same
;;; recovery used if the work were genuinely incomplete.

(define *determinacy-depth-limit-1*
  (make-parameter 100000000000))

(define *determinacy-depth-limit-2*
  (make-parameter 100))

;;; When non-#f, `trigger-followers` prints the reified follower term each
;;; time it fires, so you can watch synthesis progress through the follower.
(define *print-follower-term*
  (make-parameter #f))

;;; --- counters (cheap instrumentation; print at end of run)

(define *depth-limit-1-cutoff-counter* 0)
(define *depth-limit-2-cutoff-counter* 0)
(define *==-counter* 0)
(define *==/d-counter* 0)
(define *fail-counter* 0)
(define *singleton-succeed-counter* 0)
(define *non-singleton-succeed-counter* 0)
(define *user-counter* 0)

(define-syntax increment-counter!
  (syntax-rules ()
    [(_ c) (set! c (add1 c))]))

(define (reset-counters!)
  (set! *depth-limit-1-cutoff-counter* 0)
  (set! *depth-limit-2-cutoff-counter* 0)
  (set! *==-counter* 0)
  (set! *==/d-counter* 0)
  (set! *fail-counter* 0)
  (set! *singleton-succeed-counter* 0)
  (set! *non-singleton-succeed-counter* 0)
  (set! *user-counter* 0))

(define (print-counters!)
  (printf "*depth-limit-1-cutoff-counter*: ~s\n" *depth-limit-1-cutoff-counter*)
  (printf "*depth-limit-2-cutoff-counter*: ~s\n" *depth-limit-2-cutoff-counter*)
  (printf "*==-counter*: ~s\n" *==-counter*)
  (printf "*==/d-counter*: ~s\n" *==/d-counter*)
  (printf "*fail-counter*: ~s\n" *fail-counter*)
  (printf "*singleton-succeed-counter*: ~s\n" *singleton-succeed-counter*)
  (printf "*non-singleton-succeed-counter*: ~s\n" *non-singleton-succeed-counter*)
  (printf "*user-counter*: ~s\n" *user-counter*))

;;; Goal that increments *user-counter* for ad-hoc instrumentation.
(define (user-count)
  (lambda (st)
    (increment-counter! *user-counter*)
    st))

;;; --- override == to count calls
;;;
;;; (Redefining at top-level shadows the one from mk.scm; all subsequent goal
;;; constructors see this version.  The faster-mk conde / fresh / run machinery
;;; calls the mk.scm == directly, so those paths still use the uncounted one --
;;; that's fine for our instrumentation purposes.)

(define ==-base ==)
(define (== u v)
  (lambda (st)
    (increment-counter! *==-counter*)
    ((==-base u v) st)))

;;; --- run overrides that reset/print counters and add a final trigger

(define-syntax run
  (syntax-rules ()
    ((_ n (q) g0 g ...)
     (begin
       (reset-counters!)
       (let ((result
              (take n
                    (suspend
                     ((fresh (q) g0 g ...
                        (trigger-followers)
                        (lambda (st)
                          (let ((st (state-with-scope st nonlocal-scope)))
                            (let ((z ((reify q) st)))
                              (cons z (lambda () (lambda () #f)))))))
                      empty-state)))))
         (print-counters!)
         result)))
    ((_ n (q0 q1 q ...) g0 g ...)
     (run n (x)
       (fresh (q0 q1 q ...)
         g0 g ...
         (== (list q0 q1 q ...) x))))))

(define-syntax run*
  (syntax-rules ()
    ((_ (q0 q ...) g0 g ...) (run #f (q0 q ...) g0 g ...))))

;;; --- follower
;;;
;;; (follower name term goal)
;;;   Run `goal` once against the current state in a fresh scope.
;;;   - fail    -> fail the outer search
;;;   - singleton success -> drop the follower, continue with current state
;;;   - suspended (stream) -> stash (goal . term) in state-F so that later
;;;                           triggers can re-run it as more info is learned.
;;;
;;; The `name` is only for human-readable debugging.
;;; The `term` is carried for future tracing; it has no operational role here.

(define (follower-aux user-name te t ge g)
  (lambda (st)
    (run-and-set-follower (cons (g 0) t) st)))

(define-syntax follower
  (syntax-rules ()
    [(_ name te ge)
     (let ((t te)
           (g ge))
       (follower-aux name 'te t 'ge g))]))

;;; --- stream / state shape for conde/d
;;; inf/d is a conde/d-style stream: either #f (failure), a state (singleton
;;; success), or (state . resume-thunk) (singleton success with remainder).

(define (inf/d? v)
  (or (not v)
      (and (pair? v) (state? (car v)) (procedure? (cdr v)))
      (state? v)))

(define (state? v)
  (and (list? v) (= (length v) 3)))

(define-syntax case-inf/d
  (syntax-rules ()
    ((_ e (() e0) ((c^) e2) ((c f) e3))
     (let ((stream e))
       (cond
         ((not stream) e0)
         ((not (and (pair? stream)
                 (procedure? (cdr stream))))
          (let ((c^ stream)) e2))
         (else (let ((c (car stream)) (f (cdr stream)))
                 e3)))))))

;;; --- the two depth limits

;; Unsoundly fail when reaching depth-1 limit.
(define (check-depth-1 g)
  (lambda (depth1)
    (check-type depth1 number?)
    (lambda (depth2)
      (check-type depth2 number?)
      (lambda (st)
        (check-type st state?)
        (if (> depth1 (*determinacy-depth-limit-1*))
            (begin (increment-counter! *depth-limit-1-cutoff-counter*)
                   #f) ;; UNSOUND!
            (((g (+ depth1 1)) depth2) st))))))

;; Soundly suspend when reaching depth-2 limit.
(define (check-depth-2 g-on-fallback-thunk g)
  (lambda (depth2)
    (check-type depth2 number?)
    (lambda (st)
      (check-type st state?)
      (if (> depth2 (*determinacy-depth-limit-2*))
          (begin (increment-counter! *depth-limit-2-cutoff-counter*)
                 (cons st (g-on-fallback-thunk)))
          ((g (+ depth2 1)) st)))))

;;; --- conde/d: committing conde

(define-syntax (conde/d stx)
  (syntax-case stx ()
    ((_ ((x ...) (g ...) (b ...)) ...)
     #`(check-depth-1
        (lambda (depth1)
          (check-type depth1 number?)
          (letrec ([conde/d-g (conde/d-runtime
                             (list
                              (lambda (depth2)
                                (check-type depth2 number?)
                                (lambda (st)
                                  (check-type st state?)
                                  (let ([scope (subst-scope (state-S st))])
                                    (let ([x (var scope)] ...)
                                      (cons
                                       (bind/d* st ((g depth1) depth2) ...)
                                       (lambda (depth2)
                                         (check-type depth2 number?)
                                         (lambda (st) (bind/d* st ((b depth1) depth2) ...))))))))
                              ...)
                             (lambda () conde/d-g))])
            conde/d-g))))))

(define (conde/d-runtime clauses g-thunk)
  (check-depth-2 g-thunk
    (lambda (depth2)
      (check-type depth2 number?)
      (lambda (st)
        (define (nondeterministic) (check-type (cons st (g-thunk)) inf/d?))
        (check-type st state?)
        (let ((st (state-with-scope st (new-scope)))) ;; for set-var-val at choice point entry
          (let loop ([clauses clauses] [previously-found-clause #f])
            (if (null? clauses)
                (and previously-found-clause
                     (let ([guard-result (car previously-found-clause)]
                           [body (cdr previously-found-clause)])
                       ;; commit, evaluate body
                       ((body depth2) guard-result)))
                (let* ([clause-evaluated (((car clauses) depth2) st)]
                       [guard-stream (car clause-evaluated)]
                       [body-g (cdr clause-evaluated)])
                  (let ([guard-result (evaluate-guard guard-stream body-g)])
                    (cond
                      [(not guard-result) (loop (cdr clauses) previously-found-clause)]
                      [(eq? 'nondet guard-result) (nondeterministic)]
                      [else (if previously-found-clause
                                (nondeterministic)
                                (loop (cdr clauses) guard-result))]))))))))))

(define (evaluate-guard stream body-g)
  (case-inf/d stream
    (() #f)
    ((c) (cons c body-g))
    ((c f) 'nondet)))

;;; --- bind/d / fresh/d / depth-threaded goal primitives

(define (bind/d stream g)
  (check-type stream inf/d?)
  (check-type
   (case-inf/d stream
     (() #f)
     ((c) (g c))   ;; committed and finished, so just g left to do
     ((c1 f1)      ;; committed but suspended...
      (let ([s2 (g c1)])
        (case-inf/d s2
          (() #f)              ;; g fails, so whole thing fails
          ((c2) (cons c2 f1))  ;; committed and finished, so just f1 to return to
          ;; when we return we need to do both f1 and f2
          ((c2 f2) (cons c2 (lambda (depth2) (lambda (st) (bind/d ((f1 depth2) st) (f2 depth2))))))))))
   inf/d?))

(define-syntax bind/d*
  (syntax-rules ()
    ((_ e) e)
    ((_ e g0 g ...) (bind/d* (bind/d e g0) g ...))))

(define-syntax fresh/d
  (syntax-rules ()
    ((_ (x ...) g0 g ...)
     (lambda (depth1)
       (check-type depth1 number?)
       (lambda (depth2)
         (check-type depth2 number?)
         (lambda (st)
           (let ((scope (subst-scope (state-S st))))
             (let ((x (var scope)) ...)
               (bind/d* (((g0 depth1) depth2) st) ((g depth1) depth2) ...)))))))))

;;; --- depth-limit wrappers for the primitive goal constructors used inside
;;; conde/d / fresh/d.  Each /g variant takes the same args as its base but
;;; returns a goal that accepts (depth1)(depth2)(st) thunks.

(define (wrap-for-depth-limit gc)
  (lambda args
    (let ([g (apply gc args)])
      (lambda (depth1)
        (check-type depth1 number?)
        (lambda (depth2)
          (check-type depth2 number?)
          g)))))

;; A counted == variant used as the base for ==/d, so we can tell unifications
;; inside follower evaluation apart from main-search ones in the counters.
(define (==-counted u v)
  (lambda (st)
    (increment-counter! *==/d-counter*)
    ((==-base u v) st)))

(define ==/d      (wrap-for-depth-limit ==-counted))
(define =/=/d     (wrap-for-depth-limit =/=))
(define absento/d (wrap-for-depth-limit absento))
(define symbolo/d (wrap-for-depth-limit symbolo))
(define numbero/d (wrap-for-depth-limit numbero))
(define stringo/d (wrap-for-depth-limit stringo))

;;; --- follower firing

;; Called by conde and at the end of run.  If the current state has a stored
;; follower, run it against the state; otherwise pass the state through.
(define (trigger-followers)
  (lambda (st)
    (let ((F (state-F st)))
      (if F
          (begin
            (when (*print-follower-term*)
              (let ([t (cdr F)])
                (printf
                 "~s\n"
                 ((reify t) (state-with-scope st (new-scope))))))
            (run-and-set-follower F st))
          st))))

;; Run a follower (stored as a (g . t) pair), classify the stream, and
;; store the (possibly-updated) resume thunk back on the state.
(define (run-follower-once g t)
  (lambda (st)
    (let ((st (state-with-scope st (new-scope))))
      (let ([$ ((g 0) st)])
        (case-inf/d $
          (() (begin (increment-counter! *fail-counter*) #f))
          ((c) (begin (increment-counter! *singleton-succeed-counter*) c))
          ((c f^) (begin (increment-counter! *non-singleton-succeed-counter*)
                         (cons c f^))))))))

(define (run-and-set-follower F st)
  (let ([g (car F)]
        [t (cdr F)])
    (let ([$ ((run-follower-once g t) st)])
      (check-type $ inf/d?)
      (case-inf/d $
        (() #f)
        ((c^) (state-with-F c^ #f))
        ((c^ f^) (state-with-F c^ (cons f^ t)))))))
