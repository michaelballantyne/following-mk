;; append synthesis, whole-body hole.
;; Two examples in the "good" order: empty first, then a full append.
;; The expected answer is the recursive match-cons body.
;;
;; Run via `./run.sh synthesis/append-full.scm`.

(define (append-prog q body)
  `(letrec ([append (lambda (l s) : ((list list) -> list)
                      ,q)])
     ,body))

(time
  (test "append no follower"
    (run 1 (q)
      (absento '3 q)
      (absento '4 q)
      (absento '5 q)
      (absento '6 q)
      (absento '7 q)
      ;; ex1
      (evalo (append-prog q '(append '() (cons 5 (cons 6 '())))) '(5 6))
      ;; ex2
      (evalo (append-prog q '(append (cons 3 (cons 4 (cons 5 '()))) (cons 6 (cons 7 '()))))
             '(3 4 5 6 7)))
    '(((match l
         ['() s]
         [(cons _.0 _.1) (cons _.0 (append _.1 s))])
       (=/= ((_.0 _.1)) ((_.0 append)) ((_.0 cons)) ((_.0 s)) ((_.1 append)) ((_.1 cons)) ((_.1 s)))
       (sym _.0 _.1)))))

(time
  (test "append with follower"
    (run 1 (q)
      (absento '3 q)
      (absento '4 q)
      (absento '5 q)
      (absento '6 q)
      (absento '7 q)
      (follower
        q
        (fresh/d ()
          (evalo/d (append-prog q '(append '() (cons 5 (cons 6 '())))) '(5 6))
          (evalo/d (append-prog q '(append (cons 3 (cons 4 (cons 5 '()))) (cons 6 (cons 7 '()))))
                   '(3 4 5 6 7))))
      (evalo (append-prog q '(append '() (cons 5 (cons 6 '())))) '(5 6))
      (evalo (append-prog q '(append (cons 3 (cons 4 (cons 5 '()))) (cons 6 (cons 7 '()))))
             '(3 4 5 6 7)))
    '(((match l
         ['() s]
         [(cons _.0 _.1) (cons _.0 (append _.1 s))])
       (=/= ((_.0 _.1)) ((_.0 append)) ((_.0 cons)) ((_.0 s)) ((_.1 append)) ((_.1 cons)) ((_.1 s)))
       (sym _.0 _.1)))))
