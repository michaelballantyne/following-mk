;; The /d relational interpreter (restricted-interp-following.scm) ported to
;; the residual engine's constructors, plus the following-interpreter.scm and
;; refutation.scm tests re-run through it.  Same expected answers as the
;; closure-engine originals => decision-equivalence on ground eval, partial
;; eval, suspend/resume, and refutation -- the full engine surface.

(define empty-env/d-res '())

(define-relation/d (not-in-envo/d-res x env)
  (rconde/d
    ([]
     [(r==/d empty-env/d-res env)]
     [])
    ([y b rest]
     [(r==/d `((,y . ,b) . ,rest) env) (r=/=/d y x)]
     [(not-in-envo/d-res x rest)])))

(define-relation/d (lookupo/d-res x env t type)
  (rfresh/d (y b rest)
    (r==/d `((,y . ,b) . ,rest) env)
    (rconde/d
      ([]
       [(r==/d x y)]
       [(rconde/d
          ([]
           [(r==/d `(val ,type . ,t) b)]
           [])
          ([lam-expr]
           [(r==/d `(rec ,type . ,lam-expr) b) (r==/d `(closure ,lam-expr ,env) t)]
           []))])
      ([]
       [(r=/=/d x y)]
       [(lookupo/d-res x rest t type)]))))

(define-relation/d (list-of-symbolso/d-res los)
  (rconde/d
    ([]
     [(r==/d '() los)]
     [])
    ([a d]
     [(r==/d `(,a . ,d) los) (rsymbolo/d a)]
     [(list-of-symbolso/d-res d)])))

(define-relation/d (eval-listo/d-res expr env val type)
  (rconde/d
    ([]
     [(r==/d '() expr) (r==/d '() val)]
     [])
    ([a d v-a v-d t-a t-d]
     [(r==/d `(,a . ,d) expr) (r==/d `(,v-a . ,v-d) val) (r==/d `(,t-a . ,t-d) type)]
     [(eval-expo/d-res a env v-a 'I t-a) (eval-listo/d-res d env v-d t-d)])))

(define-relation/d (ext-env*o/d-res x* a* t* env out)
  (rconde/d
    ([]
     [(r==/d '() x*) (r==/d '() a*) (r==/d env out)]
     [])
    ([x a dx* da* env2 t dt*]
     [(r==/d `(,x . ,dx*) x*)
      (r==/d `(,a . ,da*) a*)
      (r==/d `(,t . ,dt*) t*)
      (r==/d `((,x . (val ,t . ,a)) . ,env2) out)
      (rsymbolo/d x)
      (rsymbolo/d t)
      (rabsento/d x dx*)]
     [(ext-env*o/d-res dx* da* dt* env env2)])))

(define (evalo/d-res expr val)
  (rfresh/d (type)
    (eval-expo/d-res expr empty-env/d-res val 'I type)))

(define-relation/d (eval-expo/d-res expr env val EI type)
  (rconde/d
    ([]
     [(rsymbolo/d expr)]
     [(lookupo/d-res expr env val type)])
    ([]
     [(r==/d EI 'I)
      (r==/d type 'list)
      (r==/d '(quote ()) expr)
      (r==/d '() val)
      (not-in-envo/d-res 'quote env)]
     [])
    ([e1 e2 v1 v2]
     [(r==/d EI 'I)
      (r==/d type 'list)
      (r==/d `(cons ,e1 ,e2) expr)
      (r==/d `(,v1 . ,v2) val)
      (not-in-envo/d-res 'cons env)]
     [(eval-expo/d-res e1 env v1 'I 'number) (eval-expo/d-res e2 env v2 'I 'list)])
    ([rator x* rands body env^ a* at* res]
     [(r==/d `(,rator . ,rands) expr)
      (rsymbolo/d rator)
      (rabsento/d rator '(quote cons letrec match if))]
     [(eval-expo/d-res rator
                       env
                       `(closure (lambda ,x*
                                   ,body)
                                 ,env^)
                       'E
                       `(,at* -> ,type))
      (eval-listo/d-res rands env a* at*)
      (ext-env*o/d-res x* a* at* env^ res)
      (eval-expo/d-res body res val 'I type)])
    ([p-name x body letrec-body ftype]
     [(r==/d EI 'I)
      (r==/d `(letrec ([,p-name (lambda ,x : ,ftype
                                  ,body)])
                ,letrec-body)
             expr)
      (not-in-envo/d-res 'letrec env)]
     [(list-of-symbolso/d-res x)
      (eval-expo/d-res letrec-body
                       `((,p-name . (rec ,ftype
                                         . (lambda ,x
                                             ,body)))
                         . ,env)
                       val
                       'I
                       type)])
    ([e1 e2 e3 v1 s1 s2]
     [(r==/d EI 'I)
      (r==/d `(match ,e1
                ['() ,e2]
                [(cons ,s1 ,s2) ,e3])
             expr)
      (rsymbolo/d s1)
      (rsymbolo/d s2)
      (not-in-envo/d-res 'match env)]
     [(eval-expo/d-res e1 env v1 'E 'list)
      (rconde/d
        ([]
         [(r==/d '() v1)]
         [(eval-expo/d-res e2 env val 'I type)])
        ([a d]
         [(r==/d `(,a . ,d) v1) (r=/=/d a 'closure)]
         [(eval-expo/d-res e3
                           `((,s1 . (val number . ,a)) (,s2 . (val list . ,d)) . ,env)
                           val
                           'I
                           type)]))])
    ([e1 e2 e3 e4 v1 v2]
     [(r==/d EI 'I) (r==/d `(if (= ,e1 ,e2) ,e3 ,e4) expr) (not-in-envo/d-res 'if env)]
     [(eval-expo/d-res e1 env v1 'E 'number)
      (eval-expo/d-res e2 env v2 'E 'number)
      (rconde/d
        ([]
         [(r==/d v1 v2)]
         [(eval-expo/d-res e3 env val 'I type)])
        ([]
         [(r=/=/d v1 v2)]
         [(eval-expo/d-res e4 env val 'I type)]))])
    ([]
     [(r==/d EI 'I) (r==/d type 'number) (rnumbero/d expr) (r==/d expr val)]
     [])))

;; Convenience: wrap the residual evalo/d for use with (follower term ...).
(define (evalo/d-r expr val)
  (follower-residual-goal (evalo/d-res expr val)))

;;; ================================================================
;;; following-interpreter.scm, ported
;;; ================================================================

(test "R-interp: duplicate lambda params rejected /d"
  (run* (q)
    (follower
      '()
      (evalo/d-r '(letrec ([f (lambda (x x) : ((number number) -> number)
                                x)])
                    (f 1 2))
                 q)))
  '())

(test "R-interp: ground program 1"
  (run 1 (q) (follower '() (evalo/d-r '1 q)))
  '(1))

(test "R-interp: ground program 2"
  (run 1 (q) (follower '() (evalo/d-r '(cons 1 '()) q)))
  '((1)))

(test "R-interp: ground program identity"
  (run 1 (q)
    (follower '()
      (evalo/d-r '(letrec ([double (lambda (l) : ((list) -> list)
                                     l)])
                    (double (cons 1 (cons 2 (cons 3 '())))))
                 q)))
  '((1 2 3)))

(test "R-interp: ground program cons-if-eq"
  (run 1 (q)
    (follower '()
      (evalo/d-r '(letrec ([cons-if-= (lambda (v1 v2 l) : ((number number list) -> list)
                                        (if (= v1 v2)
                                            (cons v1 l)
                                            l))])
                    (cons-if-= 1 1 (cons 1 (cons 2 (cons 3 '())))))
                 q)))
  '((1 1 2 3)))

(parameterize ([*suspend-depth* 1000])
  (test "R-interp: ground program rember 1"
    (run 1 (q)
      (follower '()
        (evalo/d-r '(letrec ([rember (lambda (e l) : ((number list) -> list)
                                       (match l
                                         ['() l]
                                         [(cons _.0 _.1)
                                          (if (= _.0 e)
                                              _.1
                                              (cons _.0 (rember e _.1)))]))])
                      (rember 5 (cons 3 (cons 4 (cons 6 (cons 7 '()))))))
                   q)))
    '((3 4 6 7))))

(test "R-interp: partial 2 (force only determinate)"
  (run 1 (q)
    (fresh (p)
      (follower (list p) (evalo/d-r `(cons 1 (cons ,p '())) q))))
  '((1 _.0)))

(test "R-interp: partial 1 resume"
  (run 1 (q)
    (fresh (p)
      (follower (list p) (evalo/d-r `(cons 1 ,p) q))
      (== p ''())))
  '((1)))

(test "R-interp: partial 2 resume"
  (run 1 (q)
    (fresh (p)
      (follower (list p) (evalo/d-r `(cons 1 (cons ,p '())) q))
      (== p 2)))
  '((1 2)))

(test "R-interp: partial refute"
  (run* (e v)
    (fresh (e1 v1)
      (== e `(cons ,e1 (cons 5 '())))
      (== v `(,v1 6))
      (follower '() (evalo/d-r e v))
      (evalo e v)))
  '())

(test "R-interp: partial 3 resume"
  (run 1 (q)
    (fresh (p)
      (follower (list p)
        (evalo/d-r `(letrec ([double (lambda (l) : ((list) -> list)
                                       ,p)])
                      (double (cons 1 (cons 2 (cons 3 '())))))
                   q))
      (== p 'l)))
  '((1 2 3)))

(parameterize ([*suspend-depth* 1000])
  (test "R-interp: resume rember 1"
    (run 1 (q)
      (fresh (p)
        (follower (list p)
          (evalo/d-r `(letrec ([rember (lambda (e l) : ((number list) -> list)
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

;;; ================================================================
;;; refutation.scm, ported (follower over a fixed conde candidate set)
;;; ================================================================

(test "R-refute: cons shape can't produce '()"
  (run* (q)
    (follower q
      (evalo/d-r `(letrec ([f (lambda (l) : ((list) -> list)
                                ,q)])
                    (f '()))
                 '()))
    (conde
      ((fresh (e1 e2) (== q `(cons ,e1 ,e2))))
      ((== q 'l))))
  '(l))

(test "R-refute: unknown quoted constant can't vary with input"
  (run* (q)
    (follower q
      (follower-residual-goal
        (rfresh/d ()
          (evalo/d-res `(letrec ([f (lambda (l) : ((list) -> list)
                                      ,q)])
                          (f '()))
                       '())
          (evalo/d-res `(letrec ([f (lambda (l) : ((list) -> list)
                                      ,q)])
                          (f (cons 1 '())))
                       '(1)))))
    (conde
      ((fresh (v) (== q `',v)))
      ((== q 'l))))
  '(l))

(test "R-refute: type mismatch returns list not number"
  (run* (q)
    (fresh (v)
      (follower q
        (evalo/d-r `(letrec ([f (lambda (l) : ((list) -> number)
                                  ,q)])
                      (f '()))
                   v))
      (conde
        ((== q '(match l ['() '()] [(cons a d) d])))
        ((== q 5)))))
  '(5))

(test "R-refute: match branch types inconsistent"
  (run* (q)
    (fresh (v1 v2 return-type)
      (follower q
        (follower-residual-goal
          (rfresh/d ()
            (evalo/d-res `(letrec ([f (lambda (l) : ((list) -> ,return-type)
                                        ,q)])
                            (f '()))
                         v1)
            (evalo/d-res `(letrec ([f (lambda (l) : ((list) -> ,return-type)
                                        ,q)])
                            (f (cons 1 '())))
                         v2))))
      (conde
        ((== q '(match l ['() '()] [(cons a d) a])))
        ((== q 'l)))))
  '(l))

(test "R-refute: wrong base case"
  (run* (q)
    (follower q
      (follower-residual-goal
        (rfresh/d ()
          (evalo/d-res `(letrec ([f (lambda (l) : ((list) -> list)
                                      ,q)])
                          (f '()))
                       '())
          (evalo/d-res `(letrec ([f (lambda (l) : ((list) -> list)
                                      ,q)])
                          (f (cons 1 '())))
                       '(1)))))
    (conde
      ((== q '(match l ['() '(1)] [(cons a d) (cons a (f d))])))
      ((== q '(match l ['() l] [(cons a d) (cons a (f d))])))))
  '((match l ['() l] [(cons a d) (cons a (f d))])))

(test "R-refute: wrong rember else-branches"
  (run* (q)
    (follower q
      (follower-residual-goal
        (rfresh/d ()
          (evalo/d-res `(letrec ([rember (lambda (e l) : ((number list) -> list)
                                           (match l
                                             ['() l]
                                             [(cons a d)
                                              (if (= a e)
                                                  d
                                                  (cons a ,q))]))])
                          (rember 5 '()))
                       '())
          (evalo/d-res `(letrec ([rember (lambda (e l) : ((number list) -> list)
                                           (match l
                                             ['() l]
                                             [(cons a d)
                                              (if (= a e)
                                                  d
                                                  (cons a ,q))]))])
                          (rember 5 (cons 3 (cons 4 (cons 5 '())))))
                       '(3 4)))))
    (conde
      ((== q 'd))
      ((== q 'l))
      ((== q '(rember e d)))))
  '((rember e d)))
