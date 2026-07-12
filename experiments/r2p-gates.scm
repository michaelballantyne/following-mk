;; r2p-gates.scm --- re-runnable gates for R2P (permuted-decreasing-recursiono/d)
;; and R2T (terminating-recursiono/d), the generalized / production termination
;; views.  Cheap checks only (no ID runs).
;;
;;   ./run.sh experiments/r2p-gates.scm
;;
;; R2P passes a body iff every self-call's args admit an INJECTIVE assignment to
;; distinct params with each arg <= its param and at least one strict (proper
;; descendant), with the assignment free to differ per call site.  See the R2P
;; section of views.scm for the soundness argument.
;;
;; R2T is the whole-body disjunction R2 OR R2P (never mixed per-site); it
;; refutes only when BOTH measures refute.  See the R2T section of views.scm.
;;
;; Gate families:
;;   (1) R2P ACCEPT: the nine canonical bodies... EXCEPT rev-acc (see finding).
;;       Plus the machine-found minimal variants for swap and evens.  interleave
;;       (argument-swap) is the headline acceptance R2 could not give.
;;   (2) R2P REFUTE: no-strict identity call, ascending call, non-injective
;;       (f d d).
;;   (3) R2P STALL: holey self-call argument, holey match arms, bare hole.
;;   (4) CURIOSITY: R2 vs R2P on the non-injective (interleave d d).
;;   (5) R2T: ALL NINE canonicals accepted (rev-acc via the R2 disjunct AND
;;       interleave via the R2P disjunct -- the whole point), the machine
;;       minimals, refutes only both-reject cases (each disjunct's individual
;;       rejection verified first), stalls on holes and on the asymmetric
;;       one-refutes/other-stalls cases.
;;
;; *** FINDING (see report): R2P is INCOMPARABLE to R2, not a generalization. ***
;; rev-acc's canonical recurses as (rev d (cons a acc)): the accumulator arg
;; (cons a acc) is STRICTLY LARGER than acc, so the total-size / multiset measure
;; that R2P uses cannot decrease (l shrinks by 1, acc grows by 1 -> sum flat).
;; R2P therefore REFUTES rev-acc, which R2 ACCEPTS via its fixed-position (l)
;; measure.  Conversely R2P ACCEPTS interleave, which R2 refutes.  Neither view
;; dominates; the production termination view is the disjunction -- implemented
;; as R2T (terminating-recursiono/d), gated in family (5) below.

(load "experiments/id-harness.scm")
(load "views.scm") ; R1..R2P + R2T + TY + NV

;; ---------------------------------------------------------------------------
;; canonical bodies + params (from the *-full-id-views.scm arm headers and
;; experiments/new-tasks-gates.scm).
;; ---------------------------------------------------------------------------
(define rember-canon
  '(match l ['() l] [(cons a d) (if (= a e) d (cons a (rember e d)))]))
(define append-canon
  '(match l ['() s] [(cons a d) (cons a (append d s))]))
(define duplicate-canon
  '(match l ['() l] [(cons a d) (cons a (cons a (duplicate d)))]))
(define member-canon
  '(match l ['() 0] [(cons a d) (if (= a e) 1 (member e d))]))
(define last-canon
  '(match l ['() 0] [(cons a d) (match d ['() a] [(cons b dd) (last d)])]))
(define swap-canon
  '(match l ['() '()]
     [(cons a d) (match d ['() (cons a '())] [(cons b dd) (cons b (cons a (swap dd)))])]))
;; machine-found minimal swap (size 63, documented in swap-full-id-views.scm):
;; both base cases return `l` itself instead of rebuilding an equal value.
(define swap-min
  '(match l ['() l]
     [(cons a d) (match d ['() l] [(cons b dd) (cons b (cons a (swap dd)))])]))
(define evens-canon
  '(match l ['() '()]
     [(cons a d) (match d ['() (cons a '())] [(cons b dd) (cons a (evens dd))])]))
;; documented in evens-full-id-views.scm: the NON-RECURSIVE degenerate the
;; 5th example killed (head + drop-second).  No self-call -> R2P accepts
;; trivially (a non-recursive body always terminates).
(define evens-degenerate
  '(match l ['() l] [(cons a d) (cons a (match d ['() d] [(cons b dd) dd]))]))
;; the recursive "return-l" minimal variant (analogous to swap-min; the likely
;; size-55 machine answer per wave-1 finding 2): both base cases return l.
(define evens-min
  '(match l ['() l] [(cons a d) (match d ['() l] [(cons b dd) (cons a (evens dd))])]))
(define rev-canon
  '(match l ['() acc] [(cons a d) (rev d (cons a acc))]))
(define interleave-canon
  '(match l1 ['() l2] [(cons a d) (cons a (interleave l2 d))]))

;; ===========================================================================
;; (1) ACCEPT gates.
;; ===========================================================================

(test "R2P rember accepted"
  (run 1 (q) (follower q (permuted-decreasing-recursiono/d 'rember '(e l) rember-canon))) '(_.0))
(test "R2P append accepted"
  (run 1 (q) (follower q (permuted-decreasing-recursiono/d 'append '(l s) append-canon))) '(_.0))
(test "R2P duplicate accepted"
  (run 1 (q) (follower q (permuted-decreasing-recursiono/d 'duplicate '(l) duplicate-canon))) '(_.0))
(test "R2P member accepted"
  (run 1 (q) (follower q (permuted-decreasing-recursiono/d 'member '(e l) member-canon))) '(_.0))
(test "R2P last accepted"
  (run 1 (q) (follower q (permuted-decreasing-recursiono/d 'last '(l) last-canon))) '(_.0))
(test "R2P swap (human canonical) accepted"
  (run 1 (q) (follower q (permuted-decreasing-recursiono/d 'swap '(l) swap-canon))) '(_.0))
(test "R2P swap (machine-minimal, size 63) accepted"
  (run 1 (q) (follower q (permuted-decreasing-recursiono/d 'swap '(l) swap-min))) '(_.0))
(test "R2P evens (human canonical) accepted"
  (run 1 (q) (follower q (permuted-decreasing-recursiono/d 'evens '(l) evens-canon))) '(_.0))
(test "R2P evens (documented non-recursive degenerate) accepted"
  (run 1 (q) (follower q (permuted-decreasing-recursiono/d 'evens '(l) evens-degenerate))) '(_.0))
(test "R2P evens (recursive return-l minimal variant) accepted"
  (run 1 (q) (follower q (permuted-decreasing-recursiono/d 'evens '(l) evens-min))) '(_.0))

;; THE HEADLINE: interleave's argument-swapping canonical -- refuted by R2, is
;; ACCEPTED by R2P (swap assignment l2<-l2 same, d<-l1 strict).
(test "R2P interleave (argument-swap) ACCEPTED [HEADLINE]"
  (run 1 (q) (follower q (permuted-decreasing-recursiono/d 'interleave '(l1 l2) interleave-canon))) '(_.0))

;; FINDING: rev-acc's canonical is REFUTED by R2P (accumulator grows -> no
;; injective all-<= assignment).  R2 ACCEPTS it.  Gated as REFUTE to document
;; the incomparability; this is NOT the intended-accept the task assumed.
(test "R2P rev-acc REFUTED (growing accumulator; R2P != superset of R2) [FINDING]"
  (run 1 (q) (follower q (permuted-decreasing-recursiono/d 'rev '(l acc) rev-canon))) '())
;; contrast: R2 accepts rev-acc (fixed-position on l).
(test "R2 rev-acc accepted (fixed-position, for contrast)"
  (run 1 (q) (follower q (decreasing-recursiono/d 'rev '(l acc) rev-canon))) '(_.0))

;; ===========================================================================
;; (2) REFUTE gates.
;; ===========================================================================

;; identity self-call with nothing strict: recurs on l itself.
(test "R2P (rember e l) refuted (no strict)"
  (run 1 (q) (follower q (permuted-decreasing-recursiono/d 'rember '(e l)
    '(match l ['() l] [(cons a d) (rember e l)])))) '())
;; ascending self-call: cons-expression arg at every position.
(test "R2P (rember e (cons a l)) refuted (ascending)"
  (run 1 (q) (follower q (permuted-decreasing-recursiono/d 'rember '(e l)
    '(match l ['() l] [(cons a d) (rember e (cons a l))])))) '())
;; NON-INJECTIVE: both args descend from l1 only.  slot 1 alone decreases (R2
;; accepts) but no injective assignment exists -> R2P refutes.
(test "R2P (interleave d d) refuted (non-injective)"
  (run 1 (q) (follower q (permuted-decreasing-recursiono/d 'interleave '(l1 l2)
    '(match l1 ['() l2] [(cons a d) (interleave d d)])))) '())

;; ===========================================================================
;; (3) STALL gates (does not refute or diverge; holes stay unbound).
;; ===========================================================================

(test "R2P self-call with holey arg stalls"
  (run 1 (h) (follower h (permuted-decreasing-recursiono/d 'rember '(e l)
    `(match l ['() l] [(cons a d) (rember e ,h)])))) '(_.0))
(test "R2P holey match arms stall, holes unbound"
  (run 1 (h1 h2) (follower (list h1 h2) (permuted-decreasing-recursiono/d 'rember '(e l)
    `(match l ['() ,h1] [(cons a d) ,h2])))) '((_.0 _.1)))
(test "R2P bare hole stalls"
  (run 1 (q) (follower q (permuted-decreasing-recursiono/d 'rember '(e l) q))) '(_.0))

;; ===========================================================================
;; (4) CURIOSITY: R2 vs R2P on the non-injective (interleave d d) (see report).
;; ===========================================================================
(test "CURIOSITY R2 accepts (interleave d d) [fixed-position ignores slot-2 collision]"
  (run 1 (q) (follower q (decreasing-recursiono/d 'interleave '(l1 l2)
    '(match l1 ['() l2] [(cons a d) (interleave d d)])))) '(_.0))

;; ===========================================================================
;; (5) R2T terminating-recursiono/d: the production disjunction R2 OR R2P.
;; ===========================================================================

;; --- ACCEPT: all NINE canonicals (the whole point of the disjunction) ---
(test "R2T rember accepted"
  (run 1 (q) (follower q (terminating-recursiono/d 'rember '(e l) rember-canon))) '(_.0))
(test "R2T append accepted"
  (run 1 (q) (follower q (terminating-recursiono/d 'append '(l s) append-canon))) '(_.0))
(test "R2T duplicate accepted"
  (run 1 (q) (follower q (terminating-recursiono/d 'duplicate '(l) duplicate-canon))) '(_.0))
(test "R2T member accepted"
  (run 1 (q) (follower q (terminating-recursiono/d 'member '(e l) member-canon))) '(_.0))
(test "R2T last accepted"
  (run 1 (q) (follower q (terminating-recursiono/d 'last '(l) last-canon))) '(_.0))
(test "R2T swap (human canonical) accepted"
  (run 1 (q) (follower q (terminating-recursiono/d 'swap '(l) swap-canon))) '(_.0))
(test "R2T swap (machine-minimal, size 63) accepted"
  (run 1 (q) (follower q (terminating-recursiono/d 'swap '(l) swap-min))) '(_.0))
(test "R2T evens (human canonical) accepted"
  (run 1 (q) (follower q (terminating-recursiono/d 'evens '(l) evens-canon))) '(_.0))
(test "R2T evens (recursive return-l minimal variant) accepted"
  (run 1 (q) (follower q (terminating-recursiono/d 'evens '(l) evens-min))) '(_.0))
;; the two incomparability halves, each accepted via its own disjunct:
(test "R2T rev-acc accepted (via R2 disjunct) [HEADLINE]"
  (run 1 (q) (follower q (terminating-recursiono/d 'rev '(l acc) rev-canon))) '(_.0))
(test "R2T interleave accepted (via R2P disjunct) [HEADLINE]"
  (run 1 (q) (follower q (terminating-recursiono/d 'interleave '(l1 l2) interleave-canon))) '(_.0))

;; --- REFUTE: only when BOTH measures reject.  Verify each disjunct's
;; individual rejection first, then the disjunction's. ---

;; (rember e l): no strict decrease anywhere.
(test "R2 rejects (rember e l) [disjunct check]"
  (run 1 (q) (follower q (decreasing-recursiono/d 'rember '(e l)
    '(match l ['() l] [(cons a d) (rember e l)])))) '())
(test "R2P rejects (rember e l) [disjunct check]"
  (run 1 (q) (follower q (permuted-decreasing-recursiono/d 'rember '(e l)
    '(match l ['() l] [(cons a d) (rember e l)])))) '())
(test "R2T (rember e l) refuted (both measures reject)"
  (run 1 (q) (follower q (terminating-recursiono/d 'rember '(e l)
    '(match l ['() l] [(cons a d) (rember e l)])))) '())

;; (rember e (cons a l)): ascending cons-expression argument.
(test "R2 rejects (rember e (cons a l)) [disjunct check]"
  (run 1 (q) (follower q (decreasing-recursiono/d 'rember '(e l)
    '(match l ['() l] [(cons a d) (rember e (cons a l))])))) '())
(test "R2P rejects (rember e (cons a l)) [disjunct check]"
  (run 1 (q) (follower q (permuted-decreasing-recursiono/d 'rember '(e l)
    '(match l ['() l] [(cons a d) (rember e (cons a l))])))) '())
(test "R2T (rember e (cons a l)) refuted (both reject)"
  (run 1 (q) (follower q (terminating-recursiono/d 'rember '(e l)
    '(match l ['() l] [(cons a d) (rember e (cons a l))])))) '())

;; NOTE: the third R2P refutation case, non-injective (interleave d d), is NOT
;; an R2T refutation -- R2 accepts it (slot 1 strictly decreases in every
;; call; the body genuinely terminates), so the disjunction ACCEPTS.  Gated as
;; ACCEPT deliberately: R2T refutes only when both measures reject.
(test "R2T (interleave d d) accepted (via R2 disjunct; R2P alone refutes)"
  (run 1 (q) (follower q (terminating-recursiono/d 'interleave '(l1 l2)
    '(match l1 ['() l2] [(cons a d) (interleave d d)])))) '(_.0))
;; mirror: R2's argument-swap refutation case is R2T-accepted via R2P.
(test "R2T (rember d e) accepted (via R2P disjunct; R2 alone refutes)"
  (run 1 (q) (follower q (terminating-recursiono/d 'rember '(e l)
    '(match l ['() l] [(cons a d) (rember d e)])))) '(_.0))

;; --- STALL: one disjunct refutes + the other stalls -> stall, NOT refute ---
(test "R2T R2-refutes/R2P-stalls -> stalls, hole unbound"
  (run 1 (h) (follower h (terminating-recursiono/d 'rember '(e l)
    `(match l ['() ,h] [(cons a d) (rember d e)])))) '(_.0))
(test "R2T R2P-refutes/R2-stalls -> stalls, hole unbound"
  (run 1 (h) (follower h (terminating-recursiono/d 'interleave '(l1 l2)
    `(match l1 ['() ,h] [(cons a d) (interleave d d)])))) '(_.0))

;; --- STALL on holes ---
(test "R2T self-call with holey arg stalls"
  (run 1 (h) (follower h (terminating-recursiono/d 'rember '(e l)
    `(match l ['() l] [(cons a d) (rember e ,h)])))) '(_.0))
(test "R2T holey match arms stall, holes unbound"
  (run 1 (h1 h2) (follower (list h1 h2) (terminating-recursiono/d 'rember '(e l)
    `(match l ['() ,h1] [(cons a d) ,h2])))) '((_.0 _.1)))
(test "R2T bare hole stalls"
  (run 1 (q) (follower q (terminating-recursiono/d 'rember '(e l) q))) '(_.0))

(test-summary)
