;; interleave-full-id-views-dfs.scm --- size-closed ID synthesis of `interleave`
;; with the GENERALIZED termination view R2P (permuted-decreasing-recursiono/d)
;; in the stack: R1 + R2P + TY + NV + evalo/d, check-every 1. IDDFS variant of
;; experiments/interleave-full-id-views-r2p.scm: same everything, but the
;; per-level search is depth-first (dfs-search.scm's mplus) instead of fair
;; interleaving. This is the headline arm for the R2P work.
;;
;; interleave's canonical body SWAPS its self-call arguments:
;;   (match l1 ['() l2] [(cons a d) (cons a (interleave l2 d))])
;; The fixed-position R2 (decreasing-recursiono/d) soundly REFUTES this (no
;; single position decreases in every call), so the R2-full stack was
;; infeasible (interleave-full-id-views.scm dropped R2 and died in bound 31,
;; >240s; see claude/2026-07-12-214500 finding 4).  R2P accepts the canonical
;; via the SWAP assignment (l2<-l2 same, d<-l1 strict; injective, one strict),
;; so R2P can be present in the stack -- the question this arm answers is
;; whether restoring a termination view (now the permuted one) makes interleave
;; FEASIBLE, at what cost, and at which bound (canonical size 35).
;;
;; Examples identical to interleave-full-id-views.scm (4).  Canonical size 35
;; lands on the bound grid at 35.
;;
;;   ./run.sh --check-follower-every 1 --timeout 240 experiments/interleave-full-id-views-dfs.scm
(load "experiments/id-harness.scm")
(load "views.scm") ; R1 + R2 + R2P + TY + NV view definitions
(load "dfs-search.scm") ; per-level search: depth-first instead of fair interleaving

(define (interleave-prog q body)
  `(letrec ([interleave (lambda (l1 l2) : ((list list) -> list)
                          ,q)])
     ,body))

(define interleave-tyenv
  '((interleave . ((list list) -> list)) (l1 . list) (l2 . list)))

(run-id "interleave-full/views-r2p/dfs" '(11 15 19 23 27 31 35 39) 1000
  (lambda (bound)
    (run 1 (q)
      (watch-size q)
      (absento 5 q)
      (absento 6 q)
      (absento 7 q)
      (absento 8 q)
      (follower
        q
        (fresh/d ()
          (base-case-patho/d 'interleave q)
          (permuted-decreasing-recursiono/d 'interleave '(l1 l2) q)
          (type-ofo/d interleave-tyenv q 'list)
          (non-vacuous-testso/d q)
          (evalo/d (interleave-prog q '(interleave '() '())) '())
          (evalo/d (interleave-prog q '(interleave '() (cons 6 '()))) '(6))
          (evalo/d (interleave-prog q '(interleave (cons 5 '()) (cons 6 '()))) '(5 6))
          (evalo/d (interleave-prog q '(interleave (cons 5 (cons 7 '())) (cons 6 (cons 8 '())))) '(5 6 7 8))))
      (evalo (interleave-prog q '(interleave '() '())) '())
      (evalo (interleave-prog q '(interleave '() (cons 6 '()))) '(6))
      (evalo (interleave-prog q '(interleave (cons 5 '()) (cons 6 '()))) '(5 6))
      (evalo (interleave-prog q '(interleave (cons 5 (cons 7 '())) (cons 6 (cons 8 '())))) '(5 6 7 8)))))
