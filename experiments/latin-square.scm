;; latin-square.scm --- a finite-domain (Latin square) benchmark where
;; Andorra-style unit propagation is KNOWN to dominate, used as an
;; existence proof that the follower mechanism can produce large search
;; reductions on a constraint-satisfaction problem (separate from the
;; synthesis benchmarks).
;;
;; A Latin square is an NxN grid filled with 1..N so that every row and
;; every column contains each value exactly once.  With some cells given,
;; the rest must be inferred.  When a row/column's other cells exclude
;; N-1 of the N values from a cell, the remaining value is FORCED.  Plain
;; miniKanren (arm A) discovers such forced cells only by generate-and-test
;; enumeration; a determinacy-directed follower (arm B) commits them
;; immediately -- this is unit propagation.
;;
;; Run via:  ./run.sh --timeout 600 experiments/latin-square.scm
;;
;; Two instances (verified unique by a throwaway exhaustive solver):
;;   * 4x4, propagation-solvable (naked singles cascade to a full solution)
;;   * 5x5, requires genuine guessing (naked singles stall after 2 cells)
;;
;; Two arms:
;;   A (baseline): pairwise =/= (posted BEFORE the generators) + a value
;;                 generator conde per non-given cell.
;;   B (follower): identical leader PLUS a (follower board net/d) whose /d
;;                 network does per-cell "pick a value + exclude it from all
;;                 peers", stalling while under-determined and committing
;;                 forced cells.

;;; =====================================================================
;;; Instances.  Givens as (index . value), index = row*N + col (row-major).
;;; Solutions as flat row-major lists, for checking answers.
;;; =====================================================================

;; 4x4 propagation-solvable.  4 givens, 12 empty cells, UNIQUE.
;;   . . 3 4        1 2 3 4
;;   . . 4 .   -->  2 3 4 1
;;   . . . .        3 4 1 2
;;   . 1 . .        4 1 2 3
(define givens-4 '((2 . 3) (3 . 4) (6 . 4) (13 . 1)))
(define solution-4 '(1 2 3 4 2 3 4 1 3 4 1 2 4 1 2 3))

;; 5x5 requires guessing.  9 givens, 16 empty cells, UNIQUE, NOT
;; naked-single solvable (propagation stalls after 2 cells).
;;   . 2 . . .        1 2 3 4 5
;;   2 . . 5 1        2 3 4 5 1
;;   . . . 1 .   -->  3 4 5 1 2
;;   . . 1 . 3        4 5 1 2 3
;;   . 1 . . 4        5 1 2 3 4
(define givens-5 '((1 . 2) (5 . 2) (8 . 5) (9 . 1) (13 . 1)
                   (17 . 1) (19 . 3) (21 . 1) (24 . 4)))
(define solution-5 '(1 2 3 4 5 2 3 4 5 1 3 4 5 1 2 4 5 1 2 3 5 1 2 3 4))

;; 6x6 propagation-solvable, but with 24 empty cells and the givens
;; clustered in the lower/middle rows.  UNIQUE, naked-single solvable.
;; Row-major generation starts on the nearly-empty top rows, so the
;; baseline is forced into deep backtracking there -- this is the
;; instance that separates the arms by >10x.
;;   . . 3 . . .        1 2 3 4 5 6
;;   . . 4 . . .        2 3 4 5 6 1
;;   . 4 . . . .   -->  3 4 5 6 1 2
;;   . 5 . 1 2 .        4 5 6 1 2 3
;;   . . 1 2 3 4        5 6 1 2 3 4
;;   . . 2 3 . .        6 1 2 3 4 5
(define givens-6-prop '((2 . 3) (8 . 4) (13 . 4) (19 . 5) (21 . 1) (22 . 2)
                        (26 . 1) (27 . 2) (28 . 3) (29 . 4) (32 . 2) (33 . 3)))
(define solution-6 '(1 2 3 4 5 6 2 3 4 5 6 1 3 4 5 6 1 2
                     4 5 6 1 2 3 5 6 1 2 3 4 6 1 2 3 4 5))

;;; =====================================================================
;;; Board geometry helpers (operate on a runtime list of the board's vars).
;;; =====================================================================

(define (cell-idx N r c) (+ (* r N) c))

(define (row-cells board N r)
  (map (lambda (c) (list-ref board (cell-idx N r c))) (iota N)))

(define (col-cells board N c)
  (map (lambda (r) (list-ref board (cell-idx N r c))) (iota N)))

;; All cells sharing a row or column with (r,c), excluding the cell itself.
(define (peer-cells board N r c)
  (let ([self (list-ref board (cell-idx N r c))])
    (filter (lambda (x) (not (eq? x self)))
            (append (row-cells board N r) (col-cells board N c)))))

;; Unordered pairs of a list.
(define (all-pairs lst)
  (cond
    [(null? lst) '()]
    [else (append (map (lambda (y) (cons (car lst) y)) (cdr lst))
                  (all-pairs (cdr lst)))]))

;;; =====================================================================
;;; Runtime goal combinators over ordinary (main-search) goals.
;;; =====================================================================

(define (conj2 g1 g2)
  (lambda (st) (bind (g1 st) g2)))

(define (conj* gs)
  (cond
    [(null? gs) succeed]
    [(null? (cdr gs)) (car gs)]
    [else (conj2 (car gs) (conj* (cdr gs)))]))

;;; =====================================================================
;;; Arm A pieces: leader (givens + pairwise =/= + generators).
;;; =====================================================================

(define (givens-goal board givens)
  (conj* (map (lambda (gv) (== (list-ref board (car gv)) (cdr gv))) givens)))

;; Pairwise =/= for every same-row and same-column pair.
(define (diseq-goal board N)
  (let ([pairs
         (append
          (apply append (map (lambda (r) (all-pairs (row-cells board N r))) (iota N)))
          (apply append (map (lambda (c) (all-pairs (col-cells board N c))) (iota N))))])
    (conj* (map (lambda (p) (=/= (car p) (cdr p))) pairs))))

;; Value generator for one cell: (conde [(== c 1)] ... [(== c N)]).
;; Uses the real conde macro (so the main-conde-hook fires the follower).
(define (gen-cell N c)
  (case N
    [(4) (conde [(== c 1)] [(== c 2)] [(== c 3)] [(== c 4)])]
    [(5) (conde [(== c 1)] [(== c 2)] [(== c 3)] [(== c 4)] [(== c 5)])]
    [(6) (conde [(== c 1)] [(== c 2)] [(== c 3)] [(== c 4)] [(== c 5)] [(== c 6)])]
    [else (error 'gen-cell "unsupported N" N)]))

;; A generator for each NON-given cell (given cells are ==-bound already).
(define (generators-goal board N givens)
  (let ([given-idxs (map car givens)])
    (conj*
     (map (lambda (idx) (gen-cell N (list-ref board idx)))
          (filter (lambda (idx) (not (memv idx given-idxs)))
                  (iota (* N N)))))))

;; The full leader: givens, then =/= (BEFORE generators), then generators.
(define (leader-goal board N givens)
  (conj* (list (givens-goal board givens)
               (diseq-goal board N)
               (generators-goal board N givens))))

;;; =====================================================================
;;; Arm B pieces: the /d constraint network for the follower.
;;; =====================================================================

;; conj/d-list: conjoin a runtime list of /d goals (mirrors conj/d* but
;; for a list).  conj/d-run is defined in following.scm.
(define (conj/d-list gs)
  (lambda (unsound-fail-depth)
    (lambda (suspend-depth)
      (lambda (st)
        (conj/d-run suspend-depth
                    (map (lambda (g) ((g unsound-fail-depth) suspend-depth)) gs)
                    st '() '())))))

;; all-diff/d v peers: post (=/=/d p v) for each peer p.
(define (all-diff/d v peers)
  (conj/d-list (map (lambda (p) (=/=/d p v)) peers)))

;; cello/d: pick a value for cell c and exclude it from all its peers.
;; Both put in the GUARD, empty body.  With c and peers under-determined
;; several guards singleton-succeed -> the conde/d stalls (soft-suspends).
;; As peers get pinned, guards fail one by one; when exactly one survives,
;; the conde/d commits the ==/d (the forced value) and its all-diff/d
;; disequalities out to the main search.  This IS unit propagation.
(define (cello/d N c peers)
  (case N
    [(4)
     (conde/d
       ([] [(==/d c 1) (all-diff/d 1 peers)] [])
       ([] [(==/d c 2) (all-diff/d 2 peers)] [])
       ([] [(==/d c 3) (all-diff/d 3 peers)] [])
       ([] [(==/d c 4) (all-diff/d 4 peers)] []))]
    [(5)
     (conde/d
       ([] [(==/d c 1) (all-diff/d 1 peers)] [])
       ([] [(==/d c 2) (all-diff/d 2 peers)] [])
       ([] [(==/d c 3) (all-diff/d 3 peers)] [])
       ([] [(==/d c 4) (all-diff/d 4 peers)] [])
       ([] [(==/d c 5) (all-diff/d 5 peers)] []))]
    [(6)
     (conde/d
       ([] [(==/d c 1) (all-diff/d 1 peers)] [])
       ([] [(==/d c 2) (all-diff/d 2 peers)] [])
       ([] [(==/d c 3) (all-diff/d 3 peers)] [])
       ([] [(==/d c 4) (all-diff/d 4 peers)] [])
       ([] [(==/d c 5) (all-diff/d 5 peers)] [])
       ([] [(==/d c 6) (all-diff/d 6 peers)] []))]
    [else (error 'cello/d "unsupported N" N)]))

;; The whole-board /d network: cello/d for every cell, conjoined.
(define (board-net/d board N)
  (conj/d-list
   (map (lambda (idx)
          (let* ([r (quotient idx N)]
                 [c (remainder idx N)]
                 [cell (list-ref board idx)]
                 [peers (peer-cells board N r c)])
            (cello/d N cell peers)))
        (iota (* N N)))))

;;; =====================================================================
;;; Two arms as goals that walk the query var to recover the board list.
;;; =====================================================================

(define (arm-A qv N givens)
  (lambda (st)
    (let ([board (walk* qv (state-S st))])
      ((leader-goal board N givens) st))))

(define (arm-B qv N givens)
  (lambda (st)
    (let ([board (walk* qv (state-S st))])
      ((conj* (list
               (givens-goal board givens)
               (follower board (board-net/d board N))
               (diseq-goal board N)
               (generators-goal board N givens)))
       st))))

;;; =====================================================================
;;; Runners.  `run` (overridden in following.scm) resets & prints counters.
;;; =====================================================================

;; Relational board builder: bind `out` to a proper list of (N*N) fresh
;; logic vars.  arm-A / arm-B then walk* the query var to recover the
;; concrete var list -- so no need to name N^2 vars by hand.
(define (make-cells n out)
  (if (= n 0)
      (== out '())
      (fresh (x rest)
        (== out (cons x rest))
        (make-cells (- n 1) rest))))

;; `run` is a macro but n and the goal expressions may be runtime values,
;; so this wrapper works for any N.
(define (run-instance nn N givens arm)
  (run nn (q)
    (make-cells (* N N) q)
    (arm q N givens)))

(define (check got want)
  (let ([ok (and (pair? got) (equal? (car got) want))])
    (printf "  answer correct? ~a  (~a)\n" ok
            (if ok "matches unique solution" (format "got ~s" got)))))

;;; =====================================================================
;;; Drive everything, printing a header + counters + timing for each.
;;; =====================================================================

(define (banner s)
  (printf "\n========================================================\n")
  (printf "~a\n" s)
  (printf "========================================================\n"))

;; do-a2?: whether to run arm A's run-2 uniqueness check.  For large
;; instances arm A must exhaust the whole space to prove uniqueness,
;; which can be far more expensive than finding the first answer, so we
;; skip it there (uniqueness is already established by the throwaway
;; exhaustive solver, and arm B's run-2 confirms it cheaply).
(define (bench name N givens sol do-a2?)
  (banner (format "~a  --  ARM A (baseline mk), run 1" name))
  (time (check (run-instance 1 N givens arm-A) sol))
  (banner (format "~a  --  ARM B (follower), run 1" name))
  (time (check (run-instance 1 N givens arm-B) sol))
  (when do-a2?
    (banner (format "~a  --  ARM A, run 2 (uniqueness)" name))
    (printf "  n-answers = ~a (expect 1)\n" (length (run-instance 2 N givens arm-A))))
  (banner (format "~a  --  ARM B, run 2 (uniqueness)" name))
  (printf "  n-answers = ~a (expect 1)\n" (length (run-instance 2 N givens arm-B))))

(bench "4x4 propagation-solvable" 4 givens-4 solution-4 #t)
(bench "5x5 requires-guessing" 5 givens-5 solution-5 #t)
(bench "6x6 propagation-solvable" 6 givens-6-prop solution-6 #f)
