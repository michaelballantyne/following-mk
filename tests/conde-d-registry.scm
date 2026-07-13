;; tests/conde-d-registry.scm --- gates for the first-order-rep step-1 registry
;; (following.scm).  Each conde/d call site registers its per-clause env-vector
;; arities in *conde/d-registry*, keyed by the site label, the first time the
;; form evaluates.  Registration is behaviour-neutral (an idempotent, unify-free
;; insert) -- these gates lock its FUNCTIONAL contract so step 2 (reifying
;; conj/d-run) cannot silently drop it.  See
;; claude/2026-07-13-043032-first-order-rep-step1-done.md.
;;
;; DEPENDS on views.scm already being loaded (conde/d sites registered at load).

(define (registry-has-arities? arities)
  (let-values ([(keys vals) (hashtable-entries *conde/d-registry*)])
    (let loop ([i 0])
      (cond
        [(= i (vector-length vals)) #f]
        [(equal? (vector-ref vals i) arities) #t]
        [else (loop (+ i 1))]))))

;; A distinctive-shape conde/d: clause 1 binds 3 fresh vars, clause 2 binds 0,
;; so its registered env-arities are (3 0) -- not produced by any views.scm site.
(define (registry-probe/d q)
  (fresh/d ()
    (conde/d
      ((a b c) ((==/d q 1)) ((==/d q 1)))
      (()      ((==/d q 2)) ((==/d q 2))))))

;; 1. Loading views.scm registered its conde/d sites.
(test "registry: conde/d sites registered at load (non-empty)"
  (> (hashtable-size *conde/d-registry*) 0)
  #t)

;; 2. Evaluating a conde/d records its per-clause env-vector arities.
(test "registry: evaluating a conde/d records per-clause env-arities (3 0)"
  (begin
    (run 1 (q) (== q 1) (follower q (registry-probe/d q)))
    (registry-has-arities? '(3 0)))
  #t)

;; 3. Idempotent: re-evaluating the same site does not error or duplicate.
(test "registry: re-evaluating the same site is idempotent (size stable)"
  (let ([n0 (begin (run 1 (q) (== q 1) (follower q (registry-probe/d q)))
                   (hashtable-size *conde/d-registry*))])
    (run 1 (q) (== q 1) (follower q (registry-probe/d q)))
    (= n0 (hashtable-size *conde/d-registry*)))
  #t)
