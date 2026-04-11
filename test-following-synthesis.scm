;; Experimental synthesis benchmarks.  These are the tests that the conde/d
;; exploration is really aiming at and which aren't all terminating cleanly
;; yet.  Start with test-following.scm for sanity tests; come here to poke at
;; the open problems.
;;
;; Run via `./run.sh test-following-synthesis.scm` -- this file does not
;; load its own infrastructure, so `chez --script` on it directly will fail.

(time (test "synthesize append with follower swapped"
            (run 1 (q)
              (absento '3 q)
              (absento '4 q)
              (absento '5 q)
              (absento '6 q)
              (absento '7 q)

              (follower
               'u1
               q
               (fresh/d ()
                       ;; ex2
                       (evalo/d `(letrec ((append (lambda (l s) : ((list list) -> list)
                                                    ,q)))
                                   (append (cons 3 (cons 4 (cons 5 '()))) (cons 6 (cons 7 '())))) '(3 4 5 6 7))
                       ;; ex1
                       (evalo/d `(letrec ((append (lambda (l s) : ((list list) -> list)
                                                    ,q)))
                                   (append '() (cons 5 (cons 6 '())))) '(5 6))
                       ))

              ;; ex2
              (evalo `(letrec ((append (lambda (l s) : ((list list) -> list)
                                         ,q)))
                        (append (cons 3 (cons 4 (cons 5 '()))) (cons 6 (cons 7 '())))) '(3 4 5 6 7))
              (user-count)
              (lambda (st)
                (printf "~s\n" ((reify q) st))
                st)
              ;; ex1
              (evalo `(letrec ((append (lambda (l s) : ((list list) -> list)
                                         ,q)))
                        (append '() (cons 5 (cons 6 '())))) '(5 6)))

            '(((match l
                 ('() s)
                 ((cons _.0 _.1) (cons _.0 (append _.1 s))))
               (=/= ((_.0 _.1)) ((_.0 append)) ((_.0 cons)) ((_.0 s)) ((_.1 append)) ((_.1 cons)) ((_.1 s))) (sym _.0 _.1)))))


(time (test "synthesize append no follower"
            (run 1 (q)
              (absento '3 q)
              (absento '4 q)
              (absento '5 q)
              (absento '6 q)
              (absento '7 q)

              ;; ex1
              (evalo `(letrec ((append (lambda (l s) : ((list list) -> list)
                                         ,q)))
                        (append '() (cons 5 (cons 6 '())))) '(5 6))
              (user-count)
              (lambda (st)
                (printf "~s\n" ((reify q) st))
                st)
              ;; ex2
              (evalo `(letrec ((append (lambda (l s) : ((list list) -> list)
                                         ,q)))
                        (append (cons 3 (cons 4 (cons 5 '()))) (cons 6 (cons 7 '())))) '(3 4 5 6 7))
              )
            '(((match l
                 ('() s)
                 ((cons _.0 _.1) (cons _.0 (append _.1 s))))
               (=/= ((_.0 _.1)) ((_.0 append)) ((_.0 cons)) ((_.0 s)) ((_.1 append)) ((_.1 cons)) ((_.1 s))) (sym _.0 _.1)))))

(time (test "synthesize append with follower"
            (run 1 (q)
              (absento '3 q)
              (absento '4 q)
              (absento '5 q)
              (absento '6 q)
              (absento '7 q)

              (follower
               'u1
               q
               (fresh/d ()
                       ;; ex1
                       (evalo/d `(letrec ((append (lambda (l s) : ((list list) -> list)
                                                    ,q)))
                                   (append '() (cons 5 (cons 6 '())))) '(5 6))
                       ;; ex2
                       (evalo/d `(letrec ((append (lambda (l s) : ((list list) -> list)
                                                    ,q)))
                                   (append (cons 3 (cons 4 (cons 5 '()))) (cons 6 (cons 7 '())))) '(3 4 5 6 7))
                       ))

              ;; ex1
              (evalo `(letrec ((append (lambda (l s) : ((list list) -> list)
                                         ,q)))
                        (append '() (cons 5 (cons 6 '())))) '(5 6))
              (user-count)
              (lambda (st)
                (printf "~s\n" ((reify q) st))
                st)
              ;; ex2
              (evalo `(letrec ((append (lambda (l s) : ((list list) -> list)
                                         ,q)))
                        (append (cons 3 (cons 4 (cons 5 '()))) (cons 6 (cons 7 '())))) '(3 4 5 6 7)))

            '(((match l
                 ('() s)
                 ((cons _.0 _.1) (cons _.0 (append _.1 s))))
               (=/= ((_.0 _.1)) ((_.0 append)) ((_.0 cons)) ((_.0 s)) ((_.1 append)) ((_.1 cons)) ((_.1 s))) (sym _.0 _.1)))))

(time (test "synthesize append no follower swapped"
            (run 1 (q)
              (absento '3 q)
              (absento '4 q)
              (absento '5 q)
              (absento '6 q)
              (absento '7 q)
              ;; ex2
              (evalo `(letrec ((append (lambda (l s) : ((list list) -> list)
                                         ,q)))
                        (append (cons 3 (cons 4 (cons 5 '()))) (cons 6 (cons 7 '())))) '(3 4 5 6 7))
              (user-count)
              (lambda (st)
                (printf "~s\n" ((reify q) st))
                st)
              ;; ex1
              (evalo `(letrec ((append (lambda (l s) : ((list list) -> list)
                                         ,q)))
                        (append '() (cons 5 (cons 6 '())))) '(5 6))
              )
            '(((match l
                 ('() s)
                 ((cons _.0 _.1) (cons _.0 (append _.1 s))))
               (=/= ((_.0 _.1)) ((_.0 append)) ((_.0 cons)) ((_.0 s)) ((_.1 append)) ((_.1 cons)) ((_.1 s))) (sym _.0 _.1)))))


(time (test "synthesize rember with follower"
            (run 1 (q)
              (absento 3 q)
              (absento 4 q)
              (absento 5 q)
              (absento 6 q)
              (absento 7 q)

              (follower
               'u1
               q
               (fresh/d ()
                       ;; ex1
                       (evalo/d `(letrec ((rember (lambda (e l) : ((number list) -> list)
                                                    ,q)))
                                   (rember 5 '())) '())
                       ;; ex2
                       (evalo/d `(letrec ((rember (lambda (e l) : ((number list) -> list)
                                                    ,q)))
                                   (rember 6 (cons 6 '()))) '())
                       ;; ex3
                       (evalo/d `(letrec ((rember (lambda (e l) : ((number list) -> list)
                                                    ,q)))
                                   (rember 7 (cons 3 (cons 4 (cons 7 (cons 6 '())))))) '(3 4 6))
                       ;; ex4
                       (evalo/d `(letrec ((rember (lambda (e l) : ((number list) -> list)
                                                    ,q)))
                                   (rember 5 (cons 3 (cons 4 (cons 6 (cons 7 '())))))) '(3 4 6 7)))
               )

              ;; ex1
              (evalo `(letrec ((rember (lambda (e l) : ((number list) -> list)
                                         ,q)))
                        (rember 5 '())) '())
              (user-count)
              (lambda (st)
                (printf "~s\n" ((reify q) st))
                st)
              ;; ex2
              (evalo `(letrec ((rember (lambda (e l) : ((number list) -> list)
                                         ,q)))
                        (rember 6 (cons 6 '()))) '())

              ;; ex3
              (evalo `(letrec ((rember (lambda (e l) : ((number list) -> list)
                                         ,q)))
                        (rember 7 (cons 3 (cons 4 (cons 7 (cons 6 '())))))) '(3 4 6))

              ;; ex4
              (evalo `(letrec ((rember (lambda (e l) : ((number list) -> list)
                                         ,q)))
                        (rember 5 (cons 3 (cons 4 (cons 6 (cons 7 '())))))) '(3 4 6 7))

              )
            '(((match l
                 ('() l)
                 ((cons _.0 _.1) (if (= _.0 e) _.1 (cons _.0 (rember e _.1)))))
               (=/=
                ((_.0 _.1))
                ((_.0 cons))
                ((_.0 e))
                ((_.0 if))
                ((_.0 rember))
                ((_.1 cons))
       ((_.1 e))
       ((_.1 if))
       ((_.1 rember)))
     (sym _.0 _.1)))))

(time (test "synthesize rember no follower"
            (run 1 (q)
              (absento 3 q)
              (absento 4 q)
              (absento 5 q)
              (absento 6 q)
              (absento 7 q)

              ;; ex1
              (evalo `(letrec ((rember (lambda (e l) : ((number list) -> list)
                                         ,q)))
                        (rember 5 '())) '())
              (user-count)
              (lambda (st)
                (printf "~s\n" ((reify q) st))
                st)
              ;; ex2
              (evalo `(letrec ((rember (lambda (e l) : ((number list) -> list)
                                         ,q)))
                        (rember 6 (cons 6 '()))) '())

              ;; ex3
              (evalo `(letrec ((rember (lambda (e l) : ((number list) -> list)
                                         ,q)))
                        (rember 7 (cons 3 (cons 4 (cons 7 (cons 6 '())))))) '(3 4 6))

              ;; ex4
              (evalo `(letrec ((rember (lambda (e l) : ((number list) -> list)
                                         ,q)))
                        (rember 5 (cons 3 (cons 4 (cons 6 (cons 7 '())))))) '(3 4 6 7))

              )
            '(((match l
                 ('() l)
                 ((cons _.0 _.1) (if (= _.0 e) _.1 (cons _.0 (rember e _.1)))))
               (=/=
                ((_.0 _.1))
                ((_.0 cons))
                ((_.0 e))
                ((_.0 if))
                ((_.0 rember))
                ((_.1 cons))
       ((_.1 e))
       ((_.1 if))
       ((_.1 rember)))
     (sym _.0 _.1)))))


(time (test "synthesize rember with follower swap ex1 <-> ex2"
            (run 1 (q)
              (absento 3 q)
              (absento 4 q)
              (absento 5 q)
              (absento 6 q)
              (absento 7 q)

              (follower
               'u1
               q
               (fresh/d ()
                       ;; ex2
                       (evalo/d `(letrec ((rember (lambda (e l) : ((number list) -> list)
                                                    ,q)))
                                   (rember 6 (cons 6 '()))) '())
                       ;; ex1
                       (evalo/d `(letrec ((rember (lambda (e l) : ((number list) -> list)
                                                    ,q)))
                                   (rember 5 '())) '())
                       ;; ex3
                       (evalo/d `(letrec ((rember (lambda (e l) : ((number list) -> list)
                                                    ,q)))
                                   (rember 7 (cons 3 (cons 4 (cons 7 (cons 6 '())))))) '(3 4 6))
                       ;; ex4
                       (evalo/d `(letrec ((rember (lambda (e l) : ((number list) -> list)
                                                    ,q)))
                                   (rember 5 (cons 3 (cons 4 (cons 6 (cons 7 '())))))) '(3 4 6 7)))
               )

              ;; ex2
              (evalo `(letrec ((rember (lambda (e l) : ((number list) -> list)
                                         ,q)))
                        (rember 6 (cons 6 '()))) '())

              ;; ex1
              (evalo `(letrec ((rember (lambda (e l) : ((number list) -> list)
                                         ,q)))
                        (rember 5 '())) '())

              ;; ex3
              (evalo `(letrec ((rember (lambda (e l) : ((number list) -> list)
                                         ,q)))
                        (rember 7 (cons 3 (cons 4 (cons 7 (cons 6 '())))))) '(3 4 6))

              ;; ex4
              (evalo `(letrec ((rember (lambda (e l) : ((number list) -> list)
                                         ,q)))
                        (rember 5 (cons 3 (cons 4 (cons 6 (cons 7 '())))))) '(3 4 6 7))

              )
            '(((match l
                 ('() l)
                 ((cons _.0 _.1) (if (= _.0 e) _.1 (cons _.0 (rember e _.1)))))
               (=/=
                ((_.0 _.1))
                ((_.0 cons))
                ((_.0 e))
                ((_.0 if))
                ((_.0 rember))
                ((_.1 cons))
       ((_.1 e))
       ((_.1 if))
       ((_.1 rember)))
     (sym _.0 _.1)))))


(time (test "synthesize rember no follower swap ex1 <-> ex2"
            (run 1 (q)
              (absento 3 q)
              (absento 4 q)
              (absento 5 q)
              (absento 6 q)
              (absento 7 q)

              ;; ex2
              (evalo `(letrec ((rember (lambda (e l) : ((number list) -> list)
                                         ,q)))
                        (rember 6 (cons 6 '()))) '())

              ;; ex1
              (evalo `(letrec ((rember (lambda (e l) : ((number list) -> list)
                                         ,q)))
                        (rember 5 '())) '())


              ;; ex3
              (evalo `(letrec ((rember (lambda (e l) : ((number list) -> list)
                                         ,q)))
                        (rember 7 (cons 3 (cons 4 (cons 7 (cons 6 '())))))) '(3 4 6))

              ;; ex4
              (evalo `(letrec ((rember (lambda (e l) : ((number list) -> list)
                                         ,q)))
                        (rember 5 (cons 3 (cons 4 (cons 6 (cons 7 '())))))) '(3 4 6 7))

              )
            '(((match l
                 ('() l)
                 ((cons _.0 _.1) (if (= _.0 e) _.1 (cons _.0 (rember e _.1)))))
               (=/=
                ((_.0 _.1))
                ((_.0 cons))
                ((_.0 e))
                ((_.0 if))
                ((_.0 rember))
                ((_.1 cons))
       ((_.1 e))
       ((_.1 if))
       ((_.1 rember)))
     (sym _.0 _.1)))))
