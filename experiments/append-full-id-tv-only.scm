;; append-full-id-follower-tv.scm --- ID follower arm WITH the
;; termination view conjoined (base-case-patho/d + evalo/d).
;;
;; Tests the mutual-reinforcement hypothesis from
;; claude/2026-07-12-184500-termination-view-results.md: every
;; follower config OOM'd on ID bound 15, and the view shrinks the
;; follower's live frontier ~4x by refuting divergent branches before
;; their state accumulates. Does bound 15 become feasible?
;;
;;   ./run.sh --check-follower-every 20 --timeout 1200 \
;;     experiments/append-full-id-follower-tv.scm

(load "experiments/id-harness.scm")
(load "experiments/termination-view.scm")

(define (append-prog q body)
  `(letrec ([append (lambda (l s) : ((list list) -> list)
                      ,q)])
     ,body))

(run-id "append-full/tv-only" '(11 15 19 23 27 31 35 39) 1000
  (lambda (bound)
    (run 1 (q)
      (watch-size q)
      (absento '3 q)
      (absento '4 q)
      (absento '5 q)
      (absento '6 q)
      (absento '7 q)
      (follower
        q
        (fresh/d ()
          (base-case-patho/d 'append q)))
      (evalo (append-prog q '(append '() (cons 5 (cons 6 '())))) '(5 6))
      (evalo (append-prog q '(append (cons 3 (cons 4 (cons 5 '()))) (cons 6 (cons 7 '()))))
             '(3 4 5 6 7)))))
