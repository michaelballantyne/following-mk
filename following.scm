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
;;; *suspend-depth*: sound cutoff.  When exceeded, a blocked conde/d (g-disj)
;;; is left budget-blocked (g-blocked) in the residual instead of being
;;; expanded further -- the same recovery used if the work were genuinely
;;; incomplete.  Depth resets to 0 at each top-level follower trigger.

(define *suspend-depth* (make-parameter 20))

;;; --- main-search parameters (threaded through the outer state, not
;;; the follower's internal search)
;;;
;;; *main-unsound-depth*: UNSOUND cutoff on the main search.  Each
;;; patched `conde` in mk.scm increments the main-search depth counter
;;; `state-D`; when D exceeds this limit, the branch fails outright.
;;; A diagnostic knob for starving diverging branches on the MAIN search
;;; (not an optimization).  Default +inf.0 (disabled).
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
;; Follower conde/d entries: bumped once per conde/d (g-disj) evaluation in
;; settle-disj (once per non-budget-blocked disj settle).
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
;;;   *entries-by-label*  -- every conde/d (g-disj) settle-disj evaluation
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

;; `g` is a residual goal node (see residual.scm); state-F holds (goal . term).
(define (follower-aux t g)
  (lambda (st)
    (run-and-set-follower (cons g t) st)))

(define-syntax follower
  (syntax-rules ()
    [(_ te ge)
     (let ([t te]
           [g ge])
       (follower-aux t g))]))

;; A counted == variant used as the base for the residual == leaf (==/d in
;; residual.scm), so we can tell unifications inside follower evaluation apart
;; from main-search ones in the counters.
(define (==-counted u v)
  (lambda (st)
    (increment-counter! *==/d-counter*)
    ((==-base u v) st)))

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

;; state-F holds (residual-goal . term) -- a plain data Goal node (see
;; residual.scm), not a curried closure.  `settle` returns #f (refuted),
;; (cons TOP st) (fully-determinate success), or (cons residual st)
;; (suspended, residual a flat conj of blocked disjuncts).  Each trigger
;; re-settles from depth 0 (matching the old top-level re-fire semantics).
(define (run-and-set-follower F st)
  (let ([g (car F)]
        [t (cdr F)]
        [before-reified (reify-for-tally (cdr F) st)])
    ;; Mark unifications performed during the settle (and the reify probes
    ;; around it) as follower work, so mk.scm's unify counter attributes them
    ;; to *follower-unify-counter*. The follower search commits
    ;; deterministically and does not escape non-locally, so a plain
    ;; set!/restore is sufficient (no dynamic-wind needed).
    (set! *in-follower-eval?* #t)
    (let ([result
           (let ([r (settle g (state-with-scope st (new-scope)) 0)])
             (cond
               [(not r)
                (increment-counter! *fail-counter*)
                #f]
               [(g-top? (car r))
                (increment-counter! *singleton-succeed-counter*)
                (tally-productivity! before-reified t (cdr r))
                (state-with-F (cdr r) #f)]
               [else
                (increment-counter! *non-singleton-succeed-counter*)
                (tally-productivity! before-reified t (cdr r))
                ;; Flatness invariant, checked at the one place every live
                ;; residual passes through (the residual/follower boundary).
                (assert-flat-residual! (car r))
                (state-with-F (cdr r) (cons (car r) t))]))])
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
;;; The tally/d COMBINATOR itself (a g-tally residual node, plus settle-tally
;;; and the partition-blocked extension that keeps its blocked children hard)
;;; lives in residual.scm; see there for the refute/force/stall semantics and
;;; the documented blind spots.  What stays HERE is the engine-agnostic
;;; per-label bookkeeping settle-tally calls into: the *view-tally-alist* and
;;; its ref/reset/bump/store-changed helpers, and print-view-tallies.
;;;
;;; refute -- a settle of the wrapped goal FAILS (#f).
;;; force  -- a settle COMMITS a store change (subst-map OR constraint store
;;;           not eq? to entry).  A pure STALL returns the entry state
;;;           unchanged, so neither counter moves (three-way split:
;;;           refute / force / stall=neither).  The store-identity test is
;;;           cheap and unify-free.

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
