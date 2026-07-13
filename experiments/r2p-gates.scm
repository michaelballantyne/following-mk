;; r2p-gates.scm --- re-runnable gates for R2P (permuted-decreasing-recursiono/d),
;; the generalized termination view.  Cheap checks only (no ID runs).
;;
;;   ./run.sh experiments/r2p-gates.scm
;;
;; R2P passes a body iff every self-call's args admit an INJECTIVE assignment to
;; distinct params with each arg <= its param and at least one strict (proper
;; descendant), with the assignment free to differ per call site.  See the R2P
;; section of views.scm for the soundness argument.
;;
;; *** CUTOVER NOTE: family (5), R2T (terminating-recursiono/d) gates, REMOVED.
;; *** R2T's code was deleted from views.scm at cutover (backlog 3b) -- it was
;; written directly against the closure engine's inf/d representation, has no
;; residual analogue, and rescuing it is the open research question tracked as
;; backlog 3c.  See views.scm's R2T section (comments preserved there) and
;; claude/2026-07-13-040000-r2p-r2t-termination-generalization.md for the full
;; non-viable-negative analysis this file's family (5) used to gate.
;;
;; Gate families:
;;   (1) R2P ACCEPT: the nine canonical bodies... EXCEPT rev-acc (see finding).
;;       Plus the machine-found minimal variants for swap and evens.  interleave
;;       (argument-swap) is the headline acceptance R2 could not give.
;;   (2) R2P REFUTE: no-strict identity call, ascending call, non-injective
;;       (f d d).
;;   (3) R2P STALL: holey self-call argument, holey match arms, bare hole.
;;   (4) CURIOSITY: R2 vs R2P on the non-injective (interleave d d).
;;
;; *** FINDING (see report): R2P is INCOMPARABLE to R2, not a generalization. ***
;; rev-acc's canonical recurses as (rev d (cons a acc)): the accumulator arg
;; (cons a acc) is STRICTLY LARGER than acc, so the total-size / multiset measure
;; that R2P uses cannot decrease (l shrinks by 1, acc grows by 1 -> sum flat).
;; R2P therefore REFUTES rev-acc, which R2 ACCEPTS via its fixed-position (l)
;; measure.  Conversely R2P ACCEPTS interleave, which R2 refutes.  Neither view
;; dominates; the (former) production termination view was the disjunction --
;; R2T, no longer available; per-task measure selection (R2 default, R2P for
;; argument-permuting recursion) is the current decision, per BACKLOG.md.

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

(test-summary)
