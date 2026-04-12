;; Basic tests for the evalo/d following interpreter, including its ground evaluation,
;; refutation, and resumption behaviors.

(test "duplicate lambda params rejected"
  (run* (q)
    (evalo '(letrec ([f (lambda (x x) : ((number number) -> number)
                          x)])
              (f 1 2))
           q))
  '())

(test "duplicate lambda params rejected /d"
  (run* (q)
    (follower
      '()
      (evalo/d '(letrec ([f (lambda (x x) : ((number number) -> number)
                              x)])
                  (f 1 2))
               q)))
  '())

;; --- ground program evaluation through evalo/d

(test "conde/d interp should eval ground program 1"
  (run 1 (q)
    (follower
      '()
      (evalo/d '1 q)))
  '(1))

(test "conde/d interp should eval ground program 2"
  (run 1 (q)
    (follower
      '()
      (evalo/d '(cons 1 '()) q)))
  '((1)))

(test "conde/d interp should eval ground program identity"
  (run 1 (q)
    (follower
      '()
      (evalo/d '(letrec ([double (lambda (l) : ((list) -> list)
                                   l)])
                  (double (cons 1 (cons 2 (cons 3 '())))))
               q)))
  '((1 2 3)))

(test "conde/d interp should eval ground program cons-if-eq"
  (run 1 (q)
    (follower
      '()
      (evalo/d '(letrec ([cons-if-= (lambda (v1 v2 l) : ((number number list) -> list)
                                      (if (= v1 v2)
                                          (cons v1 l)
                                          l))])
                  (cons-if-= 1 1 (cons 1 (cons 2 (cons 3 '())))))
               q)))
  '((1 1 2 3)))

(parameterize ([*suspend-depth* 1000])
  (test "conde/d interp should eval ground program rember 1"
    (run 1 (q)
      (follower
        '()
        (evalo/d '(letrec ([rember (lambda (e l) : ((number list) -> list)
                                     (match l
                                       ['() l]
                                       [(cons _.0 _.1)
                                        (if (= _.0 e)
                                            _.1
                                            (cons _.0 (rember e _.1)))]))])
                    (rember 5 (cons 3 (cons 4 (cons 6 (cons 7 '()))))))
                 q)))
    '((3 4 6 7))))

(parameterize ([*suspend-depth* 1000])
  (test "conde/d interp should eval ground program rember 2"
    (run 1 (q)
      (follower
        '()
        (evalo/d '(letrec ([rember (lambda (e l) : ((number list) -> list)
                                     (match l
                                       ['() l]
                                       [(cons _.0 _.1)
                                        (if (= _.0 e)
                                            _.1
                                            (cons _.0 (rember e _.1)))]))])
                    (rember 7 (cons 3 (cons 4 (cons 7 (cons 6 '()))))))
                 q)))
    '((3 4 6))))


;; --- partially instantiated programs: notice that the follower only
;; forces as much structure as is determinate rather than complete the evaluation.

(test "conde/d interp partial 2"
  (run 1 (q)
    (fresh (p)
      (follower
        (list p)
        (evalo/d `(cons 1 (cons ,p '())) q))))
  '((1 _.0)))


;; --- partial programs: follower suspends, main search fills in, follower resumes
;; to finish the evaluation and complete the answer.

(test "conde/d interp partial 1 resume"
  (run 1 (q)
    (fresh (p)
      (follower
        (list p)
        (evalo/d `(cons 1 ,p) q))
      (== p ''())))
  '((1)))


(test "conde/d interp partial 2 resume"
  (run 1 (q)
    (fresh (p)
      (follower
        (list p)
        (evalo/d `(cons 1 (cons ,p '())) q))
      (== p 2)))
  '((1 2)))

(test "conde/d interp partial refute"
  (run* (e v)
    (fresh (e1 v1)
      (== e `(cons ,e1 (cons 5 '())))
      (== v `(,v1 6))
      (follower
        '()
        (evalo/d e v))
      (evalo e v)))
  '())

(test "conde/d interp partial 3 resume"
  (run 1 (q)
    (fresh (p)
      (follower
        (list p)
        (evalo/d `(letrec ([double (lambda (l) : ((list) -> list)
                                     ,p)])
                    (double (cons 1 (cons 2 (cons 3 '())))))
                 q))
      (== p 'l)))
  '((1 2 3)))

(test "conde/d interp resume cons-if-eq 1"
  (run 1 (q)
    (fresh (p1 p2 p3)
      (follower
        (list p1)
        (evalo/d `(letrec ([cons-if-= (lambda (v1 v2 l) : ((number number list) -> list)
                                        ,p1)])
                    (cons-if-= 1 1 (cons 1 (cons 2 (cons 3 '())))))
                 q))
      (== p1 `(if ,p2 ,p3 l))
      (conde
        (succeed))
      (== p3 '(cons v1 l))
      (conde
        (succeed))
      (== p2 '(= v1 v2))

      (evalo `(letrec ([cons-if-= (lambda (v1 v2 l) : ((number number list) -> list)
                                    ,p1)])
                (cons-if-= 1 1 (cons 1 (cons 2 (cons 3 '())))))
             q)))
  '((1 1 2 3)))

(parameterize ([*suspend-depth* 1000])
  (test "conde/d interp resume rember 1"
    (run 1 (q)
      (fresh (p)
        (follower
          (list p)
          (evalo/d `(letrec ([rember (lambda (e l) : ((number list) -> list)
                                       ,p)])
                      (rember 5 (cons 3 (cons 4 (cons 6 (cons 7 '()))))))
                   q))
        (== p
            '(match l
               ['() l]
               [(cons _.0 _.1)
                (if (= _.0 e)
                    _.1
                    (cons _.0 (rember e _.1)))]))))
    '((3 4 6 7))))