;; rember, hole 2: a slightly bigger hole than rember-1.  Instead of
;; one symbol, the hole replaces the entire recursive call
;; `(rember e d)` in the else-branch, so the synthesizer has to find
;; a 3-element application, not a single symbol.  Expected answer:
;; p = (rember e d).
;;
;; Five examples in the "good" order.  Ex1 and ex2 hit the base cases;
;; ex3 hits the else-branch once; ex4 removes at position 2 of a 3-elem
;; list; ex5 removes at position 2 of a 4-elem list, leaving a 3-elem
;; result.  The longer list in ex5 is what forces a real recursive
;; answer -- shorter lists admit a variety of "match once and return a
;; 1-elem list" tricks that the synthesizer finds instead.
;;
;; Run via `./run.sh synthesis/rember-2.scm`.

(time
  (test "rember hole-2 no follower"
    (run 1 (p)
      ;; ex1
      (evalo `(letrec ([rember (lambda (e l) : ((number list) -> list)
                                 (match l
                                   ['() l]
                                   [(cons a d)
                                    (if (= a e)
                                        d
                                        (cons a ,p))]))])
                (rember 5 '()))
             '())
      ;; ex2
      (evalo `(letrec ([rember (lambda (e l) : ((number list) -> list)
                                 (match l
                                   ['() l]
                                   [(cons a d)
                                    (if (= a e)
                                        d
                                        (cons a ,p))]))])
                (rember 6 (cons 6 '())))
             '())
      ;; ex3
      (evalo `(letrec ([rember (lambda (e l) : ((number list) -> list)
                                 (match l
                                   ['() l]
                                   [(cons a d)
                                    (if (= a e)
                                        d
                                        (cons a ,p))]))])
                (rember 7 (cons 3 '())))
             '(3))
      ;; ex4
      (evalo `(letrec ([rember (lambda (e l) : ((number list) -> list)
                                 (match l
                                   ['() l]
                                   [(cons a d)
                                    (if (= a e)
                                        d
                                        (cons a ,p))]))])
                (rember 4 (cons 3 (cons 6 (cons 4 '())))))
             '(3 6))
      ;; ex5
      (evalo `(letrec ([rember (lambda (e l) : ((number list) -> list)
                                 (match l
                                   ['() l]
                                   [(cons a d)
                                    (if (= a e)
                                        d
                                        (cons a ,p))]))])
                (rember 4 (cons 3 (cons 6 (cons 4 (cons 7 '()))))))
             '(3 6 7)))
    '((rember e d))))

(time
  (test "rember hole-2 with follower"
    (run 1 (p)
      (follower p
        (fresh/d ()
          ;; ex1
          (evalo/d `(letrec ([rember (lambda (e l) : ((number list) -> list)
                                       (match l
                                         ['() l]
                                         [(cons a d)
                                          (if (= a e)
                                              d
                                              (cons a ,p))]))])
                      (rember 5 '()))
                   '())
          ;; ex2
          (evalo/d `(letrec ([rember (lambda (e l) : ((number list) -> list)
                                       (match l
                                         ['() l]
                                         [(cons a d)
                                          (if (= a e)
                                              d
                                              (cons a ,p))]))])
                      (rember 6 (cons 6 '())))
                   '())
          ;; ex3
          (evalo/d `(letrec ([rember (lambda (e l) : ((number list) -> list)
                                       (match l
                                         ['() l]
                                         [(cons a d)
                                          (if (= a e)
                                              d
                                              (cons a ,p))]))])
                      (rember 7 (cons 3 '())))
                   '(3))
          ;; ex4 -- removal at position 2 of a 3-elem list
          (evalo/d `(letrec ([rember (lambda (e l) : ((number list) -> list)
                                       (match l
                                         ['() l]
                                         [(cons a d)
                                          (if (= a e)
                                              d
                                              (cons a ,p))]))])
                      (rember 4 (cons 3 (cons 6 (cons 4 '())))))
                   '(3 6))
          ;; ex5 -- 4-elem list, position 2 removal, 3-elem result
          (evalo/d `(letrec ([rember (lambda (e l) : ((number list) -> list)
                                       (match l
                                         ['() l]
                                         [(cons a d)
                                          (if (= a e)
                                              d
                                              (cons a ,p))]))])
                      (rember 4 (cons 3 (cons 6 (cons 4 (cons 7 '()))))))
                   '(3 6 7))))
      ;; ex1
      (evalo `(letrec ([rember (lambda (e l) : ((number list) -> list)
                                 (match l
                                   ['() l]
                                   [(cons a d)
                                    (if (= a e)
                                        d
                                        (cons a ,p))]))])
                (rember 5 '()))
             '())
      ;; ex2
      (evalo `(letrec ([rember (lambda (e l) : ((number list) -> list)
                                 (match l
                                   ['() l]
                                   [(cons a d)
                                    (if (= a e)
                                        d
                                        (cons a ,p))]))])
                (rember 6 (cons 6 '())))
             '())
      ;; ex3
      (evalo `(letrec ([rember (lambda (e l) : ((number list) -> list)
                                 (match l
                                   ['() l]
                                   [(cons a d)
                                    (if (= a e)
                                        d
                                        (cons a ,p))]))])
                (rember 7 (cons 3 '())))
             '(3))
      ;; ex4
      (evalo `(letrec ([rember (lambda (e l) : ((number list) -> list)
                                 (match l
                                   ['() l]
                                   [(cons a d)
                                    (if (= a e)
                                        d
                                        (cons a ,p))]))])
                (rember 4 (cons 3 (cons 6 (cons 4 '())))))
             '(3 6))
      ;; ex5
      (evalo `(letrec ([rember (lambda (e l) : ((number list) -> list)
                                 (match l
                                   ['() l]
                                   [(cons a d)
                                    (if (= a e)
                                        d
                                        (cons a ,p))]))])
                (rember 4 (cons 3 (cons 6 (cons 4 (cons 7 '()))))))
             '(3 6 7)))
    '((rember e d))))
