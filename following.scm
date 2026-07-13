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

(define *suspend-depth* (make-parameter 20))

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

;;; --- size-bounded search parameters
;;;
;;; *max-term-size*: SOUND cutoff on the size of the watched term.  Each
;;; main-search conde entry computes a size lower bound of the watched
;;; term under the current substitution (see `term-size-lb`); if it
;;; exceeds this bound the branch fails.  Because the lower bound is
;;; monotone under substitution refinement (logic vars only ever gain
;;; structure), failing when lb > bound never discards an answer of size
;;; <= bound -- it is sound *with respect to the bounded search space*.
;;; Used to drive iterative deepening on program size.  Default +inf.0
;;; (disabled).
;;;
;;; *size-watched-term*: the term whose size is bounded, usually the
;;; query var.  #f disables the check.  Set (not parameterized) by the
;;; `watch-size` goal, and reset to #f by `reset-counters!` so a watched
;;; term never leaks into a later run.

(define *max-term-size* (make-parameter +inf.0))

(define *size-watched-term* (make-parameter #f))

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
                                (print-parameters!)
                                (print-counters!)
                                (exit 1))))

;;; --- counters (cheap instrumentation; print at end of run)

(define *unsound-fail-depth-cutoff-counter* 0)
(define *suspend-depth-cutoff-counter* 0)
(define *main-unsound-depth-cutoff-counter* 0)
;; Main-search branches cut because the watched term's size lower bound
;; exceeded *max-term-size* (bumped in main-conde-hook).
(define *size-cutoff-counter* 0)
(define *==-counter* 0)
(define *==/d-counter* 0)
;; Main-search conde expansions: bumped once per invocation of the closure
;; returned by main-conde-hook (once per main-search conde entry).
(define *main-conde-counter* 0)
;; Follower conde/d entries: bumped once per evaluation attempt in
;; conde/d-runtime (once per state that reaches the clause loop).
(define *conde/d-counter* 0)
(define *fail-counter* 0)
(define *singleton-succeed-counter* 0)
(define *non-singleton-succeed-counter* 0)
;; A follower trigger is "externally productive" if the *reified*
;; follower term differs before vs after the trigger -- i.e. the trigger
;; committed a new binding OR a new constraint (=/=, symbolo, absento,
;; ...) visible on a variable reachable from the term.  Internal
;; fresh-var bindings don't count.  (Reified, not just walked: see
;; claude/2026-07-12-184500-termination-view-results.md for the
;; constraint-only commits the walk-based tally missed.)
(define *externally-productive-trigger-counter* 0)
(define *externally-unproductive-trigger-counter* 0)
(define *user-counter* 0)

(define-syntax increment-counter!
  (syntax-rules ()
    [(_ c) (set! c (add1 c))]))

;;; --- per-conde/d-site depth tally (lightweight tracing)
;;;
;;; Each conde/d call site carries a source label (see the conde/d macro).
;;; Three tables keyed by that label let us attribute suspend-depth cutoffs
;;; to the specific /d relation that drives the deep unfolding:
;;;   *entries-by-label*  -- every conde/d-runtime evaluation attempt
;;;   *cutoffs-by-label*  -- every suspend-depth cutoff fired at that site
;;;   *maxdepth-by-label* -- max suspend-depth observed at entry to that site
;;; Nothing prints unless print-depth-tally! is called explicitly.

(define *entries-by-label* (make-hashtable string-hash string=?))
(define *cutoffs-by-label* (make-hashtable string-hash string=?))
(define *maxdepth-by-label* (make-hashtable string-hash string=?))

(define (hashtable-bump! ht key)
  (hashtable-update! ht key add1 0))

(define (hashtable-max! ht key v)
  (hashtable-update! ht key (lambda (old) (max old v)) 0))

(define (record-depth-entry! label suspend-depth)
  (hashtable-bump! *entries-by-label* label)
  (hashtable-max! *maxdepth-by-label* label suspend-depth))

(define (record-depth-cutoff! label)
  (hashtable-bump! *cutoffs-by-label* label))

(define (reset-depth-tally!)
  (hashtable-clear! *entries-by-label*)
  (hashtable-clear! *cutoffs-by-label*)
  (hashtable-clear! *maxdepth-by-label*))

;;; Print the per-site tally: every site that fired at least one suspend
;;; cutoff (sorted by cutoff count descending), plus the top ~10 sites by
;;; entry count.  Columns: label, entries, cutoffs, max-depth-at-entry.
(define (print-depth-tally!)
  (let* ([labels (vector->list (hashtable-keys *entries-by-label*))]
         [entries (lambda (l) (hashtable-ref *entries-by-label* l 0))]
         [cutoffs (lambda (l) (hashtable-ref *cutoffs-by-label* l 0))]
         [maxdepth (lambda (l) (hashtable-ref *maxdepth-by-label* l 0))]
         [with-cutoffs (list-sort (lambda (a b) (> (cutoffs a) (cutoffs b)))
                                  (filter (lambda (l) (> (cutoffs l) 0)) labels))]
         [by-entries (list-sort (lambda (a b) (> (entries a) (entries b))) labels)]
         [top-entries (let loop ([xs by-entries] [n 10])
                        (if (or (null? xs) (= n 0)) '() (cons (car xs) (loop (cdr xs) (- n 1)))))]
         ;; union: cutoff rows first, then any top-entry rows not already shown
         [rows (append with-cutoffs
                       (filter (lambda (l) (not (member l with-cutoffs))) top-entries))])
    (if (null? rows)
        (printf "  (depth tally empty)\n")
        (let* ([label-w (apply max (string-length "site") (map string-length rows))]
               [lcol (lambda (s w) (string-append s (make-string (max 0 (- w (string-length s))) #\space)))]
               [rcol (lambda (s w) (string-append (make-string (max 0 (- w (string-length s))) #\space) s))])
          (printf "  ~a  ~a  ~a  ~a\n"
                  (lcol "site" label-w) (rcol "entries" 7) (rcol "cutoffs" 7) (rcol "max-depth" 9))
          (for-each (lambda (l)
                      (printf "  ~a  ~a  ~a  ~a\n"
                              (lcol l label-w)
                              (rcol (number->string (entries l)) 7)
                              (rcol (number->string (cutoffs l)) 7)
                              (rcol (number->string (maxdepth l)) 9)))
                    rows)))))

(define (reset-counters!)
  (set! *unsound-fail-depth-cutoff-counter* 0)
  (set! *suspend-depth-cutoff-counter* 0)
  (set! *main-unsound-depth-cutoff-counter* 0)
  (set! *size-cutoff-counter* 0)
  (set! sample-term-counter 0)
  ;; Don't let a watched term set by an earlier run leak into a later one.
  (*size-watched-term* #f)
  (set! *==-counter* 0)
  (set! *==/d-counter* 0)
  (set! *main-conde-counter* 0)
  (set! *conde/d-counter* 0)
  ;; These three live in mk.scm; following.scm is loaded into the same
  ;; top-level environment (see load.scm), so we reset them directly.
  (set! *main-unify-counter* 0)
  (set! *follower-unify-counter* 0)
  (set! *in-follower-eval?* #f)
  (set! *fail-counter* 0)
  (set! *singleton-succeed-counter* 0)
  (set! *non-singleton-succeed-counter* 0)
  (set! *externally-productive-trigger-counter* 0)
  (set! *externally-unproductive-trigger-counter* 0)
  (set! *user-counter* 0)
  (reset-depth-tally!)
  (reset-view-tallies!))

(define counter-descriptors
  (list (cons "unify (main)"
              (lambda ()
                *main-unify-counter*))
        (cons "unify (follower)"
              (lambda ()
                *follower-unify-counter*))
        (cons "conde (main)"
              (lambda ()
                *main-conde-counter*))
        (cons "conde/d entries"
              (lambda ()
                *conde/d-counter*))
        (cons "== (main)"
              (lambda ()
                *==-counter*))
        (cons "== (/d)"
              (lambda ()
                *==/d-counter*))
        (cons "follower fail"
              (lambda ()
                *fail-counter*))
        (cons "follower singleton"
              (lambda ()
                *singleton-succeed-counter*))
        (cons "follower non-singleton"
              (lambda ()
                *non-singleton-succeed-counter*))
        (cons "trigger productive"
              (lambda ()
                *externally-productive-trigger-counter*))
        (cons "trigger unproductive"
              (lambda ()
                *externally-unproductive-trigger-counter*))
        (cons "cutoff: unsound fail"
              (lambda ()
                *unsound-fail-depth-cutoff-counter*))
        (cons "cutoff: suspend"
              (lambda ()
                *suspend-depth-cutoff-counter*))
        (cons "cutoff: main unsound"
              (lambda ()
                *main-unsound-depth-cutoff-counter*))
        (cons "cutoff: size"
              (lambda ()
                *size-cutoff-counter*))
        (cons "user"
              (lambda ()
                *user-counter*))))

(define (print-counters!)
  (let ([nonzero (remp (lambda (d)
                         (= ((cdr d)) 0))
                       counter-descriptors)])
    (if (null? nonzero)
        (printf "  (all counters zero)\n")
        (let ([label-w (apply max
                              (map (lambda (d)
                                     (string-length (car d)))
                                   nonzero))]
              [val-w (apply max
                            (map (lambda (d)
                                   (string-length (number->string ((cdr d)))))
                                 nonzero))])
          (for-each (lambda (d)
                      (let* ([label (car d)]
                             [val (number->string ((cdr d)))]
                             [pad-label (make-string (- label-w (string-length label)) #\space)]
                             [pad-val (make-string (- val-w (string-length val)) #\space)])
                        (printf "  ~a~a  ~a~a\n" label pad-label pad-val val)))
                    nonzero)))))

(define (print-parameters!)
  (let ([parts
         (remp
          not
          (list
           (let ([v (*suspend-depth*)]) (and (not (= v 20)) (format "suspend-depth=~a" v)))
           (let ([v (*check-follower-every*)]) (and (not (= v 1)) (format "check-every=~a" v)))
           (let ([v (*unsound-fail-depth*)]) (and (not (= v +inf.0)) (format "unsound-fail=~a" v)))
           (let ([v (*main-unsound-depth*)]) (and (not (= v +inf.0)) (format "main-unsound=~a" v)))
           (let ([v (*max-term-size*)]) (and (not (= v +inf.0)) (format "max-term-size=~a" v)))
           (and (*print-follower-term*) "print-follower")))])
    (unless (null? parts)
      (printf "  [~a]\n"
              (let loop ([ps parts])
                (if (null? (cdr ps))
                    (car ps)
                    (string-append (car ps) "  " (loop (cdr ps)))))))))

;;; Goal that increments *user-counter* for ad-hoc instrumentation.
(define (user-count)
  (lambda (st)
    (increment-counter! *user-counter*)
    st))

;;; --- size-bounded search machinery

;;; Goal that registers `t` as the term whose size is bounded by
;;; *max-term-size* in the main-conde hook.  Mutates the parameter (not
;;; a `parameterize`) so the setting persists across the whole run; the
;;; state passes through unchanged.  Experiments call it as the first
;;; goal of a run, e.g. (watch-size q).
(define (watch-size t)
  (lambda (st)
    (*size-watched-term* t)
    st))

;;; Size lower bound of a walked term: an unbound logic var contributes
;;; 0 (it may still refine to arbitrary structure), a non-pair atom 1,
;;; and a pair 1 + size(car) + size(cdr).  Monotone under substitution
;;; refinement, so `lb > bound => fail` never discards an answer of size
;;; <= bound.  Expects an already-walked term (see main-conde-hook).
(define (term-size-lb t)
  (cond
    [(var? t) 0]
    [(pair? t) (+ 1 (term-size-lb (car t)) (term-size-lb (cdr t)))]
    [else 1]))

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
         (print-parameters!)
         (print-counters!)
         (print-view-tallies)
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

(define (state? v)
  (and (list? v) (= (length v) 5)))

(define-record-type hard-suspended (fields state thunk))

(define (inf/d? v)
  (or (not v) (hard-suspended? v) (and (pair? v) (state? (car v)) (procedure? (cdr v))) (state? v)))

(define-syntax case-inf/d
  (syntax-rules ()
    [(_ e (() e0) ((c^) e1) ((c f) e2) ((ch fh) e3))
     (let ([stream e])
       (cond
         [(not stream) e0]
         [(hard-suspended? stream)
          (let ([ch (hard-suspended-state stream)]
                [fh (hard-suspended-thunk stream)])
            e3)]
         [(not (and (pair? stream) (procedure? (cdr stream)))) (let ([c^ stream]) e1)]
         [else
          (let ([c (car stream)]
                [f (cdr stream)])
            e2)]))]))

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
(define (check-suspend-depth label g-on-fallback-thunk g)
  (lambda (suspend-depth)
    (check-type suspend-depth number?)
    (lambda (st)
      (check-type st state?)
      (if (> suspend-depth (*suspend-depth*))
          (begin
            (increment-counter! *suspend-depth-cutoff-counter*)
            (record-depth-cutoff! label)
            (make-hard-suspended st (g-on-fallback-thunk)))
          ((g (+ suspend-depth 1)) st)))))

;;; --- conde/d: committing conde

(define-syntax (conde/d
                 stx)
  (syntax-case stx ()
    [(_ ((x ...) (g ...) (b ...)) ...)
     (let ()
       ;; Source label for this call site, computed at expansion time and
       ;; embedded as a literal string.  Prefer the syntax annotation
       ;; ("basename:line"); if absent, fall back to the leading operator
       ;; symbols of the first clause's guards.
       (define (basename p)
         (let loop ([i (- (string-length p) 1)])
           (cond
             [(< i 0) p]
             [(char=? (string-ref p i) #\/) (substring p (+ i 1) (string-length p))]
             [else (loop (- i 1))])))
       (define (fallback-label)
         (let* ([clauses (syntax->datum #'((g ...) ...))]
                [first-clause (if (null? clauses) '() (car clauses))]
                [ops (map (lambda (form) (if (pair? form) (car form) form)) first-clause)])
           (string-append "conde/d?["
                          (if (null? ops)
                              ""
                              (fold-left (lambda (acc s) (string-append acc "," (format "~a" s)))
                                         (format "~a" (car ops))
                                         (cdr ops)))
                          "]")))
       (define ann (syntax->annotation stx))
       (define label
         (if ann
             (let* ([src (annotation-source ann)]
                    [sfd (source-object-sfd src)]
                    [path (source-file-descriptor-path sfd)]
                    [bfp (source-object-bfp src)]
                    [loc (call-with-values (lambda () (locate-source sfd bfp #t)) list)])
               (if (>= (length loc) 2)
                   (string-append (basename path) ":" (number->string (cadr loc)))
                   (string-append (basename path) "@" (number->string bfp))))
             (fallback-label)))
       #`(check-unsound-fail-depth
          (lambda (unsound-fail-depth)
            (check-type unsound-fail-depth number?)
            (letrec ([conde/d-g
                      (conde/d-runtime
                       #,label
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
                                             ((((conj/d* b ...) unsound-fail-depth) suspend-depth)
                                              st)))))))) ...)
                     (lambda ()
                       conde/d-g))])
              conde/d-g))))]))

(define (conde/d-runtime label clauses g-thunk)
  (check-suspend-depth
   label
   g-thunk
   (lambda (suspend-depth)
     (check-type suspend-depth number?)
     (lambda (st)
       (define (nondeterministic)
         (check-type (cons st (g-thunk)) inf/d?))
       (increment-counter! *conde/d-counter*)
       (record-depth-entry! label suspend-depth)
       (check-type st state?)
       (let ([st (state-with-scope st (new-scope))]) ;; for set-var-val at choice point entry
         (let loop ([clauses clauses]
                    [previously-found-clause #f])
           (if (null? clauses)
               (and previously-found-clause
                    (let ([guard-stream (car previously-found-clause)]
                          [body (cdr previously-found-clause)])
                      ;; commit, evaluate body
                      (case-inf/d guard-stream
                        [() #f]
                        [(c) (conj/d-run suspend-depth (list (body suspend-depth)) c '() '())]
                        [(c f) (conj/d-run suspend-depth (list (body suspend-depth)) c (list f) '())]
                        [(ch fh)
                         (conj/d-run suspend-depth (list (body suspend-depth)) ch '() (list fh))])))
               (let* ([clause-evaluated (((car clauses) suspend-depth) st)]
                      [guard-stream (car clause-evaluated)]
                      [body-g (cdr clause-evaluated)])
                 (cond
                   [(not guard-stream) (loop (cdr clauses) previously-found-clause)]
                   [else
                    (if previously-found-clause
                        (nondeterministic)
                        (loop (cdr clauses) (cons guard-stream body-g)))])))))))))

;;; --- conjunction / depth-threaded goal primitives

;;; conj/d-run: worklist-based conjunction runner.
;;; Takes a suspend-depth, a list of goals [(st -> inf/d) ...], and
;;; a state. Processes each goal, collecting results into soft-suspended
;;; (can retry with new info) and hard-suspended (deferred to retrigger)
;;; worklists. Iterates on soft-suspended goals while progress is made.

(define (conj/d-run suspend-depth goals st soft hard)
  (let ([entry-C (state-C st)]
        [entry-M (subst-map (state-S st))])
    (let process ([goals goals]
                  [st st]
                  [soft soft]
                  [hard hard])
      (if (null? goals)
          ;; Round complete.
          (let ([changed? (or (not (eq? entry-C (state-C st)))
                              (not (eq? entry-M (subst-map (state-S st)))))])
            (cond
              [(and (null? soft) (null? hard)) st]
              [(and (not (null? soft)) changed?)
               ;; Progress was made — iterate on soft-suspended goals.
               (conj/d-run suspend-depth
                           (map (lambda (f)
                                  (f suspend-depth))
                                (reverse soft))
                           st
                           '()
                           hard)]
              [else
               ;; No more progress. Build result from remaining goals.
               (let ([resume (conj/d-resume (reverse soft) hard)])
                 (if (null? hard)
                     (cons st resume)
                     (make-hard-suspended st resume)))]))
          ;; Process next goal.
          (let ([result ((car goals) st)])
            (case-inf/d result
              [() #f]
              [(c) (process (cdr goals) c soft hard)]
              [(c f) (process (cdr goals) c (cons f soft) hard)]
              [(ch fh) (process (cdr goals) ch soft (cons fh hard))]))))))

(define (conj/d-resume soft hard)
  (let ([all (append soft hard)])
    (lambda (sd)
      (lambda (st)
        (conj/d-run sd
                    (map (lambda (f)
                           (f sd))
                         all)
                    st
                    '()
                    '())))))

(define succeed/d
  (lambda (unsound-fail-depth)
    (lambda (suspend-depth)
      (lambda (st)
        st))))

(define-syntax conj/d*
  (syntax-rules ()
    [(_) succeed/d]
    [(_ g0) g0]
    [(_ g0 g1 g* ...)
     (let ([gs (list g0 g1 g* ...)])
       (lambda (unsound-fail-depth)
         (lambda (suspend-depth)
           (lambda (st)
             (conj/d-run suspend-depth
                         (map (lambda (g)
                                ((g unsound-fail-depth) suspend-depth))
                              gs)
                         st
                         '()
                         '())))))]))

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
    (increment-counter! *main-conde-counter*)
    (let ([watched (*size-watched-term*)]
          [bound (*max-term-size*)])
      (if (and watched
               (not (= bound +inf.0))
               (> (term-size-lb (walk* watched (state-S st))) bound))
          (begin
            (increment-counter! *size-cutoff-counter*)
            #f)
          (begin
            (sample-watched-term! watched st)
            (main-conde-hook-rest st))))))

;;; When *sample-term-every* is a number N and a term is being watched,
;;; print the reified watched term on every Nth surviving main-conde
;;; entry, tagged with the current size bound. For sampling the candidate
;;; population the search explores at each ID level. Off (#f) by default.
(define *sample-term-every* (make-parameter #f))

(define sample-term-counter 0)

(define (sample-watched-term! watched st)
  (let ([se (*sample-term-every*)])
    (when (and se watched)
      (set! sample-term-counter (+ 1 sample-term-counter))
      (when (>= sample-term-counter se)
        (set! sample-term-counter 0)
        (printf "[CAND bound=~a] ~s\n"
                (*max-term-size*)
                (without-unify-counting
                 (lambda ()
                   ((reify watched) (state-with-scope st (new-scope))))))))))

(define (main-conde-hook-rest st)
  (let ([d^ (+ 1 (state-D st))])
    (if (> d^ (*main-unsound-depth*))
        (begin
          (increment-counter! *main-unsound-depth-cutoff-counter*)
          #f)
        (let ([st (state-with-D st d^)])
          (let ([fc^ (+ 1 (state-FC st))])
            (if (>= fc^ (*check-follower-every*))
                ((trigger-followers) (state-with-FC st 0))
                (state-with-FC st fc^)))))))

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
              (let ([t (cdr F)])
                (printf "~s\n"
                        (without-unify-counting
                         (lambda ()
                           ((reify t) (state-with-scope st (new-scope))))))))
            (run-and-set-follower F st))
          st))))

(define (run-and-set-follower F st)
  (let ([g (car F)]
        [t (cdr F)]
        [before-reified (reify-for-tally (cdr F) st)])
    ;; Mark unifications performed during the follower goal invocation (and
    ;; the case-inf/d dispatch over its result) as follower work, so mk.scm's
    ;; unify counter attributes them to *follower-unify-counter*. The follower
    ;; search commits deterministically and does not escape non-locally, so a
    ;; plain set!/restore is sufficient (no dynamic-wind needed).
    (set! *in-follower-eval?* #t)
    (let ([result
           (let ([$ ((g 0) (state-with-scope st (new-scope)))])
             (case-inf/d $
               [()
                (begin
                  (increment-counter! *fail-counter*)
                  #f)]
               [(c^)
                (begin
                  (increment-counter! *singleton-succeed-counter*)
                  (tally-productivity! before-reified t c^)
                  (state-with-F c^ #f))]
               [(c^ f^)
                (begin
                  (increment-counter! *non-singleton-succeed-counter*)
                  (tally-productivity! before-reified t c^)
                  (state-with-F c^ (cons f^ t)))]
               [(ch fh)
                (begin
                  (increment-counter! *non-singleton-succeed-counter*)
                  (tally-productivity! before-reified t ch)
                  (state-with-F ch (cons fh t)))]))])
      (set! *in-follower-eval?* #f)
      result)))

;; Run thunk without letting its internal unifications pollute the work
;; counters. mk.scm's reify is NOT unify-free -- constraint reification
;; runs subsumption checks that call unify -- so instrumentation-only
;; reification must be excluded from the metric it feeds. (Found when a
;; committed experiment total jumped 8x with identical conde counts.)
(define (without-unify-counting thunk)
  (let ([m *main-unify-counter*]
        [f *follower-unify-counter*])
    (let ([v (thunk)])
      (set! *main-unify-counter* m)
      (set! *follower-unify-counter* f)
      v)))

;; A trigger is "productive" if it changed the *reified* watched term --
;; reification projects the constraint store onto variables reachable
;; from the term, so constraint-only commits (symbolo, =/=, absento on
;; term vars) count as productive. The old walk*-only comparison scored
;; such commits "unproductive" even when they measurably perturbed the
;; main search (see claude/2026-07-12-184500-termination-view-results.md).
(define (reify-for-tally t st)
  (without-unify-counting
   (lambda ()
     ((reify t) (state-with-scope st (new-scope))))))

(define (tally-productivity! before-reified t c^)
  (let ([after-reified (reify-for-tally t c^)])
    (if (equal? before-reified after-reified)
        (increment-counter! *externally-unproductive-trigger-counter*)
        (increment-counter! *externally-productive-trigger-counter*))))

;;; --- per-view attribution tally (tally/d)
;;;
;;; (tally/d label goal) wraps a /d goal TRANSPARENTLY -- identical search
;;; behavior -- while attributing two per-label events to `label` (a symbol
;;; such as 'R1, 'TY, 'EX):
;;;
;;;   refute -- an evaluation step of the wrapped goal FAILS (returns #f),
;;;             which fails the follower conjunction on this branch.
;;;   force  -- an evaluation step COMMITS a store change: the result state's
;;;             substitution map OR constraint store is not eq? to the entry
;;;             state's, i.e. a binding or a constraint was added.
;;;
;;; "Evaluation step" covers BOTH the initial evaluation at follower
;;; installation AND every RE-FIRE of a stalled view at later trigger points:
;;; when a step suspends (soft `(st . thunk)` or hard-suspended), tally/d
;;; REBUILDS the suspension with its resume thunk re-wrapped under the same
;;; label, so the label rides inside the worklist items conj/d-run stashes
;;; (soft and hard) and inside the follower resume stored in state-F.  The
;;; label is captured in the wrapper closure at item-creation time -- no
;;; dynamic extent is relied on across the suspension boundary -- and each
;;; resumed step re-wraps ITS OWN suspensions, so the chain survives any
;;; number of stall/resume rounds and conj/d-resume repackagings.  (This
;;; matters: nearly all view activity -- the refutes and forces -- happens on
;;; resumption, not at installation; an initial-evaluation-only tally sees one
;;; 'force per example goal and nothing else.)  Goals not wrapped in tally/d
;;; put unlabeled thunks in the same worklists and count nothing.  Children
;;; spawned inside the wrapped goal (fresh/d, nested conde/d bodies) are part
;;; of its evaluation step; the only thing that escapes to the enclosing
;;; worklist is the suspension thunk, which carries the label.
;;;
;;; The force test is exactly conj/d-run's `changed?` fixpoint test: an
;;; identity comparison on (subst-map (state-S st)) and (state-C st).  It is
;;; CHEAP and UNIFY-FREE (only car/cdr accessors, no walk, no reify), so
;;; tally/d needs no `without-unify-counting` guard and adds near-zero
;;; unify(main)/unify(follower) -- contrast the reify-based productivity tally,
;;; whose reify IS a hidden unify consumer.  Verified: bound-15
;;; rember-full-id-views is byte-identical (unify-main / conde-main /
;;; unify-follower) with all five views tally-wrapped vs untallied.
;;;
;;; Event counted for each of the four inf/d outcomes of one step:
;;;   #f (fail)         -> refute++           (returned unchanged)
;;;   state (singleton) -> force++ iff store changed vs entry
;;;   (state . thunk)   -> force++ iff store changed vs entry;
;;;                        thunk re-wrapped under the label
;;;   hard-suspended    -> force++ iff store changed vs entry;
;;;                        thunk re-wrapped under the label
;;; A pure STALL step returns the ENTRY state unchanged -- conde/d's
;;; `nondeterministic` yields (cons st thunk) with the same st, and a
;;; suspend-depth cutoff yields (make-hard-suspended st ...) with the same st
;;; -- so its store is eq? to entry and NEITHER counter moves.  That is the
;;; intended three-way split: refute / force / (stall = neither).
;;;
;;; KNOWN BLIND SPOTS (consequences of the cheap store-identity choice):
;;;   1. INTERNAL FRESH-VAR BINDINGS COUNT AS FORCE.  The set-var-val!
;;;      optimization is disabled in mk.scm (subst-add always builds a fresh
;;;      subst-map), so a view that merely ACCEPTS already-committed structure
;;;      -- e.g. matching (==/d `(cons ,e1 ,e2) body) against a committed cons,
;;;      binding the view's own fresh pattern vars e1,e2 -- changes subst-map
;;;      identity and scores a "force" even though it did not narrow the outer
;;;      term q.  So `force` means "committed and extended the store somehow",
;;;      which over-counts relative to "forced a hole in q".  The reify-based
;;;      aggregate *externally-productive-trigger-counter* is the term-level
;;;      metric that excludes these; tally/d is the cheap per-view metric that
;;;      does not.
;;;   2. PER-STEP, NOT PER-DISTINCT-DECISION.  A view that stalls is
;;;      re-evaluated at later triggers and within conj/d-run's fixpoint
;;;      iterations; each evaluation step is counted afresh.  Counts are
;;;      step frequencies, not counts of distinct candidate outcomes.
;;;   3. SURVIVAL IS LOCAL.  A commit counted here may later be discarded by a
;;;      subsequent conjunct in the follower failing.  "in a commit that
;;;      survives" is therefore approximate: it survives the wrapped goal's
;;;      step, not necessarily the whole follower branch.

;; label -> (refute-count . force-count).  Mutable cons cells, bumped in place;
;; reset (rebound to '()) by reset-counters! so no run leaks into a later one.
;; Exposed so a harness can snapshot per level (as id-harness snapshots the
;; counter globals) before the next run's reset.
(define *view-tally-alist* '())

(define (view-tally-ref label)
  (let ([e (assq label *view-tally-alist*)])
    (if e (cdr e) (cons 0 0))))

(define (reset-view-tallies!)
  (set! *view-tally-alist* '()))

(define (view-tally-bump! label which)
  (let ([e (assq label *view-tally-alist*)])
    (if e
        (let ([cell (cdr e)])
          (if (eq? which 'refute)
              (set-car! cell (add1 (car cell)))
              (set-cdr! cell (add1 (cdr cell)))))
        (set! *view-tally-alist*
              (cons (cons label (if (eq? which 'refute) (cons 1 0) (cons 0 1)))
                    *view-tally-alist*)))))

(define (view-store-changed? st entry-M entry-C)
  (or (not (eq? entry-M (subst-map (state-S st))))
      (not (eq? entry-C (state-C st)))))

;; One counted evaluation step: run `g` (an (st) -> inf/d) on `st`, bump the
;; label's counters per the outcome, and re-wrap any suspension thunk so the
;; NEXT step (a re-fire from a conj/d-run worklist or the state-F resume) is
;; counted under the same label.
(define (tally-step label g st)
  (let ([entry-M (subst-map (state-S st))]
        [entry-C (state-C st)])
    (let ([result (g st)])
      (case-inf/d result
        [()
         (begin
           (view-tally-bump! label 'refute)
           #f)]
        [(c^)
         (begin
           (when (view-store-changed? c^ entry-M entry-C)
             (view-tally-bump! label 'force))
           c^)]
        [(c f)
         (begin
           (when (view-store-changed? c entry-M entry-C)
             (view-tally-bump! label 'force))
           (cons c (tally-wrap-resume label f)))]
        [(ch fh)
         (begin
           (when (view-store-changed? ch entry-M entry-C)
             (view-tally-bump! label 'force))
           (make-hard-suspended ch (tally-wrap-resume label fh)))]))))

;; Wrap a resume thunk ((suspend-depth) -> (st) -> inf/d, the shape of both
;; soft and hard worklist items) so its next step is a counted tally-step.
(define (tally-wrap-resume label f)
  (lambda (suspend-depth)
    (let ([g (f suspend-depth)])
      (lambda (st)
        (tally-step label g st)))))

(define (tally/d label goal)
  (lambda (unsound-fail-depth)
    (let ([g1 (goal unsound-fail-depth)])
      (lambda (suspend-depth)
        (let ([g2 (g1 suspend-depth)])
          (lambda (st)
            (tally-step label g2 st)))))))

;; Print the per-view tally (nothing when empty, so non-tallied runs are
;; unaffected).  Called from the `run` macro's report path, alongside
;; print-counters!.
(define (print-view-tallies)
  (unless (null? *view-tally-alist*)
    (let ([rows (list-sort (lambda (a b)
                             (string<? (format "~a" (car a)) (format "~a" (car b))))
                           *view-tally-alist*)])
      (printf "  view tallies (label: refute/force):\n")
      (for-each (lambda (e)
                  (printf "    ~a: ~a/~a\n" (car e) (cadr e) (cddr e)))
                rows))))
