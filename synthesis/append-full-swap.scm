;; append synthesis in the "bad" example order: the full append example
;; first, then the empty-list base case.  The non-swap version
;; (synthesis/append-full.scm) terminates in ~0.25s for no follower
;; and ~0.88s for with follower (at --check-follower-every 100); this
;; swap variant currently times out in every configuration we've
;; tested, and is an open problem.  A working follower *should*
;; rescue this ordering by using both examples in parallel from the
;; start rather than following the main search's linear traversal.
;;
;; Run via `./run.sh synthesis/append-full-swap.scm`.

(define (append-prog q body)
  `(letrec ([append (lambda (l s) : ((list list) -> list)
                      ,q)])
     ,body))

(time
  (test "append-swap no follower"
    (run 1 (q)
      (absento '3 q)
      (absento '4 q)
      (absento '5 q)
      (absento '6 q)
      (absento '7 q)
      ;; ex2 first (swapped)
      (evalo (append-prog q '(append (cons 3 (cons 4 (cons 5 '()))) (cons 6 (cons 7 '()))))
             '(3 4 5 6 7))
      ;; ex1 second
      (evalo (append-prog q '(append '() (cons 5 (cons 6 '())))) '(5 6)))
    '(((match l
         ['() s]
         [(cons _.0 _.1) (cons _.0 (append _.1 s))])
       (=/= ((_.0 _.1)) ((_.0 append)) ((_.0 cons)) ((_.0 s)) ((_.1 append)) ((_.1 cons)) ((_.1 s)))
       (sym _.0 _.1)))))

(time
  (test "append-swap with follower"
    (run 1 (q)
      (absento '3 q)
      (absento '4 q)
      (absento '5 q)
      (absento '6 q)
      (absento '7 q)
      (follower
        q
        (fresh/d ()
          (evalo/d (append-prog q '(append (cons 3 (cons 4 (cons 5 '()))) (cons 6 (cons 7 '()))))
                   '(3 4 5 6 7))
          (evalo/d (append-prog q '(append '() (cons 5 (cons 6 '())))) '(5 6))))
      (evalo (append-prog q '(append (cons 3 (cons 4 (cons 5 '()))) (cons 6 (cons 7 '()))))
             '(3 4 5 6 7))
      (evalo (append-prog q '(append '() (cons 5 (cons 6 '())))) '(5 6)))
    '(((match l
         ['() s]
         [(cons _.0 _.1) (cons _.0 (append _.1 s))])
       (=/= ((_.0 _.1)) ((_.0 append)) ((_.0 cons)) ((_.0 s)) ((_.1 append)) ((_.1 cons)) ((_.1 s)))
       (sym _.0 _.1)))))
