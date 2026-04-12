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
      [(_ v pred) (check-type-runtime v pred 'pred)]))

(define (check-type-runtime v pred pred-e)
  (if (pred v)
      v
      (error 'check-type (format "expected ~s, got ~s" pred-e v))))

;;; --- depth parameters
;;;
;;; *unsound-fail-depth*: UNSOUND cutoff.  When exceeded, the
;;; follower fails outright.  Intended as a diagnostic knob so that a
;;; diverging branch can be starved out of faster-mk's interleaving scheduler,
;;; making pruning on the surviving branch observable.  NOT a real optimization.
;;;
;;; *suspend-depth*: sound cutoff.  When exceeded, the follower
;;; suspends (returns the entry state paired with a resume thunk), the same
;;; recovery used if the work were genuinely incomplete.

(define *unsound-fail-depth* (make-parameter +inf.0))

(define *suspend-depth* (make-parameter 10))

;;; --- main-search parameters (threaded through the outer state, not
;;; the follower's internal search)
;;;
;;; *main-unsound-depth*: UNSOUND cutoff on the main search.  Each
;;; patched `conde` in mk.scm increments the main-search depth counter
;;; `state-D`; when D exceeds this limit, the branch fails outright.
;;; Parallel to `*unsound-fail-depth*` for the follower; same caveat
;;; (not an optimization, a diagnostic knob for starving diverging
;;; branches).  Default +inf.0 (disabled).
;;;
;;; *check-follower-every*: throttle on how often the follower is
;;; fired from the main search's conde hook.  `state-FC` counts conde
;;; calls since the last follower fire; the follower is only triggered
;;; when FC reaches this value (and FC is reset to 0 when it does).
;;; Default 1 means "fire on every conde" (the original behavior).

(define *main-unsound-depth* (make-parameter +inf.0))

(define *check-follower-every* (make-parameter 1))

;;; When non-#f, `trigger-followers` prints the reified follower term each
;;; time it fires, so you can watch synthesis progress through the follower.
(define *print-follower-term* (make-parameter #f))

;;; Call this to install a Ctrl-C (SIGINT) handler that dumps the counter
;;; snapshot and exits.  Useful for peeking at progress during a
;;; non-terminating search.  Opt-in because it replaces chez's default
;;; interrupt behavior (reset to REPL), which you want for interactive use.
(define (install-interrupt-counter-dump!)
  (keyboard-interrupt-handler (lambda ()
                                (printf "\n--- interrupted; counter snapshot ---\n")
                                (print-counters!)
                                (exit 1))))

;;; --- counters (cheap instrumentation; print at end of run)

(define *unsound-fail-depth-cutoff-counter* 0)
(define *suspend-depth-cutoff-counter* 0)
(define *main-unsound-depth-cutoff-counter* 0)
(define *==-counter* 0)
(define *==/d-counter* 0)
(define *fail-counter* 0)
(define *singleton-succeed-counter* 0)
(define *non-singleton-succeed-counter* 0)
;; A follower trigger is "externally productive" if walking the
;; follower's term under the post-trigger substitution differs from
;; walking it under the pre-trigger substitution -- i.e. the trigger
;; committed at least one new binding visible to the outer search via
;; a variable reachable from the term.  Internal fresh-var bindings
;; don't count.
(define *externally-productive-trigger-counter* 0)
(define *externally-unproductive-trigger-counter* 0)
(define *user-counter* 0)

(define-syntax increment-counter!
  (syntax-rules ()
    [(_ c) (set! c (add1 c))]))

(define (reset-counters!)
  (set! *unsound-fail-depth-cutoff-counter* 0)
  (set! *suspend-depth-cutoff-counter* 0)
  (set! *main-unsound-depth-cutoff-counter* 0)
  (set! *==-counter* 0)
  (set! *==/d-counter* 0)
  (set! *fail-counter* 0)
  (set! *singleton-succeed-counter* 0)
  (set! *non-singleton-succeed-counter* 0)
  (set! *externally-productive-trigger-counter* 0)
  (set! *externally-unproductive-trigger-counter* 0)
  (set! *user-counter* 0))

(define (print-counters!)
  (printf "*unsound-fail-depth-cutoff-counter*: ~s\n" *unsound-fail-depth-cutoff-counter*)
  (printf "*suspend-depth-cutoff-counter*: ~s\n" *suspend-depth-cutoff-counter*)
  (printf "*main-unsound-depth-cutoff-counter*: ~s\n" *main-unsound-depth-cutoff-counter*)
  (printf "*==-counter*: ~s\n" *==-counter*)
  (printf "*==/d-counter*: ~s\n" *==/d-counter*)
  (printf "*fail-counter*: ~s\n" *fail-counter*)
  (printf "*singleton-succeed-counter*: ~s\n" *singleton-succeed-counter*)
  (printf "*non-singleton-succeed-counter*: ~s\n" *non-singleton-succeed-counter*)
  (printf "*externally-productive-trigger-counter*: ~s\n" *externally-productive-trigger-counter*)
  (printf "*externally-unproductive-trigger-counter*: ~s\n" *externally-unproductive-trigger-counter*)
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
    [(_ n (q) g0 g ...)
     (begin
       (reset-counters!)
       (let ([result (take n
                           (suspend ((fresh (q)
                                       g0
                                       g ...
                                       (trigger-followers)
                                       (lambda (st)
                                         (let ([st (state-with-scope st nonlocal-scope)])
                                           (let ([z ((reify q) st)])
                                             (cons z
                                                   (lambda ()
                                                     (lambda ()
                                                       #f)))))))
                                     empty-state)))])
         (print-counters!)
         result))]
    [(_ n (q0 q1 q ...) g0 g ...)
     (run n (x)
       (fresh (q0 q1 q ...)
         g0
         g ...
         (== (list q0 q1 q ...) x)))]))

(define-syntax run*
  (syntax-rules ()
    [(_ (q0 q ...) g0 g ...)
     (run #f (q0 q ...)
       g0
       g ...)]))

;;; --- follower
;;;
;;; (follower term goal)
;;;   Run `goal` once against the current state in a fresh scope.
;;;   - fail    -> fail the outer search
;;;   - singleton success -> drop the follower, continue with current state
;;;   - suspended (stream) -> stash (goal . term) in state-F so that later
;;;                           triggers can re-run it as more info is learned.
;;;
;;; The `term` is what the outer search cares about; it's used for
;;; productivity measurement (walk* term before vs after each trigger)
;;; and for `*print-follower-term*` tracing.

(define (follower-aux t g)
  (lambda (st)
    (run-and-set-follower (cons (g 0) t) st)))

(define-syntax follower
  (syntax-rules ()
    [(_ te ge)
     (let ([t te]
           [g ge])
       (follower-aux t g))]))

;;; --- stream / state shape for conde/d
;;; inf/d is a conde/d-style stream: either #f (failure), a state (singleton
;;; success), or (state . resume-thunk) (singleton success with remainder).

(define (inf/d? v)
  (or (not v) (and (pair? v) (state? (car v)) (procedure? (cdr v))) (state? v)))

(define (state? v)
  (and (list? v) (= (length v) 5)))

(define-syntax case-inf/d
  (syntax-rules ()
    [(_ e (() e0) ((c^) e2) ((c f) e3))
     (let ([stream e])
       (cond
         [(not stream) e0]
         [(not (and (pair? stream) (procedure? (cdr stream)))) (let ([c^ stream]) e2)]
         [else
          (let ([c (car stream)]
                [f (cdr stream)])
            e3)]))]))

;;; --- the two depth checks

;; Unsoundly fail when reaching *unsound-fail-depth*.
(define (check-unsound-fail-depth g)
  (lambda (unsound-fail-depth)
    (check-type unsound-fail-depth number?)
    (lambda (suspend-depth)
      (check-type suspend-depth number?)
      (lambda (st)
        (check-type st state?)
        (if (> unsound-fail-depth (*unsound-fail-depth*))
            (begin
              (increment-counter! *unsound-fail-depth-cutoff-counter*)
              #f) ;; UNSOUND!
            (((g (+ unsound-fail-depth 1)) suspend-depth) st))))))

;; Soundly suspend when reaching *suspend-depth*.
(define (check-suspend-depth g-on-fallback-thunk g)
  (lambda (suspend-depth)
    (check-type suspend-depth number?)
    (lambda (st)
      (check-type st state?)
      (if (> suspend-depth (*suspend-depth*))
          (begin
            (increment-counter! *suspend-depth-cutoff-counter*)
            (cons st (g-on-fallback-thunk)))
          ((g (+ suspend-depth 1)) st)))))

;;; --- conde/d: committing conde

(define-syntax (conde/d
                 stx)
  (syntax-case stx ()
    [(_ ((x ...) (g ...) (b ...)) ...)
     #`(check-unsound-fail-depth
        (lambda (unsound-fail-depth)
          (check-type unsound-fail-depth number?)
          (letrec ([conde/d-g
                    (conde/d-runtime
                     (list (lambda (suspend-depth)
                             (check-type suspend-depth number?)
                             (lambda (st)
                               (check-type st state?)
                               (let ([scope (subst-scope (state-S st))])
                                 (let ([x (var scope)] ...)
                                   (cons ((((conj/d* g ...) unsound-fail-depth) suspend-depth) st)
                                         (lambda (suspend-depth)
                                           (check-type suspend-depth number?)
                                           (lambda (st)
                                             ((((conj/d* b ...) unsound-fail-depth) suspend-depth) st)))))))) ...)
                     (lambda ()
                       conde/d-g))])
            conde/d-g)))]))

(define (conde/d-runtime clauses g-thunk)
  (check-suspend-depth
   g-thunk
   (lambda (suspend-depth)
     (check-type suspend-depth number?)
     (lambda (st)
       (define (nondeterministic)
         (check-type (cons st (g-thunk)) inf/d?))
       (check-type st state?)
       (let ([st (state-with-scope st (new-scope))]) ;; for set-var-val at choice point entry
         (let loop ([clauses clauses]
                    [previously-found-clause #f])
           (if (null? clauses)
               (and previously-found-clause
                    (let ([guard-result (car previously-found-clause)]
                          [body (cdr previously-found-clause)])
                      ;; commit, evaluate body
                      ((body suspend-depth) guard-result)))
               (let* ([clause-evaluated (((car clauses) suspend-depth) st)]
                      [guard-stream (car clause-evaluated)]
                      [body-g (cdr clause-evaluated)])
                 (let ([guard-result (evaluate-guard guard-stream body-g)])
                   (cond
                     [(not guard-result) (loop (cdr clauses) previously-found-clause)]
                     [(eq? 'nondet guard-result) (nondeterministic)]
                     [else
                      (if previously-found-clause
                          (nondeterministic)
                          (loop (cdr clauses) guard-result))]))))))))))

(define (evaluate-guard stream body-g)
  (case-inf/d stream
    [() #f]
    [(c) (cons c body-g)]
    [(c f) 'nondet]))

;;; --- bind/d / fresh/d / depth-threaded goal primitives

(define (changed-state? st st^)
  (not
   (and (eq? (state-C st) (state-C st^))
        (eq? (subst-map (state-S st))
             (subst-map (state-S st^))))))

(define (bind/d suspend-depth stream g2)
  (printf "~a\n" suspend-depth)
  (case-inf/d stream
              [() #f]
              [(c) (g2 c)] ;; committed and finished, so just g left to do
              [(c1 f1) ;; committed but suspended...
               (let ([s2 (g2 (state-with-scope c1 (new-scope)))])
                 (case-inf/d s2
                             [() #f] ;; g2 fails, so whole thing fails
                             [(c2)
                              (if (changed-state? c1 c2)
                                  ((f1 (+ 1 suspend-depth)) c2)  ;; finished and made progress, go back to f1 from g1
                                  (cons c2 f1))] ;; finshed without meaningful change, so we are nondet
                             ;; when we return we need to do both f1 and f2
                             [(c2 f2)
                              (if (changed-state? c1 c2)
                                  (bind/d (+ 1 suspend-depth) ((f1 (+ 1 suspend-depth)) c2) (f2 (+ 1 suspend-depth))) ;; made progress, go back to f1 from g1 and come back later
                                  (cons c2
                                        (lambda (suspend-depth)
                                          (lambda (st)
                                            (bind/d suspend-depth ((f1 suspend-depth) st) (f2 suspend-depth))))))]))]))

(define (conj/d g1 g2)
  (lambda (unsound-fail-depth)
    (check-type unsound-fail-depth number?)
    (lambda (suspend-depth)
      (check-type suspend-depth number?)
      (lambda (st)
        (let ([stream (((g1 unsound-fail-depth) suspend-depth) st)])
          (check-type stream inf/d?)
          (bind/d suspend-depth stream ((g2 unsound-fail-depth) suspend-depth)))))))

(define succeed/d
  (lambda (unsound-fail-depth)
    (lambda (stream)
      (lambda (st) st))))

(define-syntax conj/d*
  (syntax-rules ()
    [(_) succeed/d]
    [(_ g0) g0]
    [(_ g0 g1 g ...) (conj/d* (conj/d g0 g1) g ...)]))

(define-syntax fresh/d
  (syntax-rules ()
    [(_ (x ...) g0 g ...)
     (lambda (unsound-fail-depth)
       (check-type unsound-fail-depth number?)
       (lambda (suspend-depth)
         (check-type suspend-depth number?)
         (lambda (st)
           (let ([scope (subst-scope (state-S st))])
             (let ([x (var scope)] ...)
               ((((conj/d* g0 g ...) unsound-fail-depth) suspend-depth) st))))))]))

;;; --- depth-threading wrappers for the primitive goal constructors used
;;; inside conde/d / fresh/d.  Each /d variant takes the same args as its base
;;; but returns a goal that accepts (unsound-fail-depth)(suspend-depth)(st)
;;; thunks.

(define (wrap-for-depth-limit gc)
  (lambda args
    (let ([g (apply gc args)])
      (lambda (unsound-fail-depth)
        (check-type unsound-fail-depth number?)
        (lambda (suspend-depth)
          (check-type suspend-depth number?)
          g)))))

;; A counted == variant used as the base for ==/d, so we can tell unifications
;; inside follower evaluation apart from main-search ones in the counters.
(define (==-counted u v)
  (lambda (st)
    (increment-counter! *==/d-counter*)
    ((==-base u v) st)))

(define ==/d (wrap-for-depth-limit ==-counted))
(define =/=/d (wrap-for-depth-limit =/=))
(define absento/d (wrap-for-depth-limit absento))
(define symbolo/d (wrap-for-depth-limit symbolo))
(define numbero/d (wrap-for-depth-limit numbero))
(define stringo/d (wrap-for-depth-limit stringo))

;;; --- main-conde hook
;;;
;;; Called by the patched `conde` in mk.scm on every branch entry.
;;; Responsibilities:
;;;   1. Bump state-D (main-search depth).  If it exceeds
;;;      *main-unsound-depth*, fail the branch outright.
;;;   2. Bump state-FC (follower-check counter).  If FC reaches
;;;      *check-follower-every*, reset FC to 0 and fire the follower
;;;      (via trigger-followers).  Otherwise return the state with the
;;;      bumped FC and no follower fire.

(define (main-conde-hook)
  (lambda (st)
    (let ([d^ (+ 1 (state-D st))])
      (if (> d^ (*main-unsound-depth*))
          (begin
            (increment-counter! *main-unsound-depth-cutoff-counter*)
            #f)
          (let ([st (state-with-D st d^)])
            (let ([fc^ (+ 1 (state-FC st))])
              (if (>= fc^ (*check-follower-every*))
                  ((trigger-followers) (state-with-FC st 0))
                  (state-with-FC st fc^))))))))

;;; --- follower firing

;; If the current state has a stored follower, run it against the
;; state; otherwise pass the state through.  Called by main-conde-hook
;; (throttled) and directly from `run` at end-of-run.
(define (trigger-followers)
  (lambda (st)
    (let ([F (state-F st)])
      (if F
          (begin
            (when (*print-follower-term*)
              (let ([t (cdr F)]) (printf "~s\n" ((reify t) (state-with-scope st (new-scope))))))
            (run-and-set-follower F st))
          st))))

;; Run a follower (stored as a (g . t) pair), classify the stream, and
;; store the (possibly-updated) resume thunk back on the state.
(define (run-follower-once g t)
  (lambda (st)
    (let ([st (state-with-scope st (new-scope))])
      (let ([$ ((g 0) st)])
        (case-inf/d $
          [()
           (begin
             (increment-counter! *fail-counter*)
             #f)]
          [(c)
           (begin
             (increment-counter! *singleton-succeed-counter*)
             c)]
          [(c f^)
           (begin
             (increment-counter! *non-singleton-succeed-counter*)
             (cons c f^))])))))

(define (run-and-set-follower F st)
  (let ([g (car F)]
        [t (cdr F)]
        [before-walked (walk* (cdr F) (state-S st))])
    (let ([$ ((run-follower-once g t) st)])
      (check-type $ inf/d?)
      (case-inf/d $
        [() #f]
        [(c^)
         (begin
           (tally-productivity! before-walked t c^)
           (state-with-F c^ #f))]
        [(c^ f^)
         (begin
           (tally-productivity! before-walked t c^)
           (state-with-F c^ (cons f^ t)))]))))

(define (tally-productivity! before-walked t c^)
  (let ([after-walked (walk* t (state-S c^))])
    (if (equal? before-walked after-walked)
        (increment-counter! *externally-unproductive-trigger-counter*)
        (increment-counter! *externally-productive-trigger-counter*))))
