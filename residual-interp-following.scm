;; A variant of the interpreter in restricted-interp-following.scm, ported to
;; the residual engine's determinacy-directed constructors (rconde/d, rfresh/d,
;; r==/d, r=/=/d, rsymbolo/d, rnumbero/d, rabsento/d, define-relation/d). Names
;; keep the -res suffix used when this was first validated inline in
;; tests/residual-interp.scm via differential testing against the closure
;; engine (18 tests, following-interpreter.scm and refutation.scm scenarios).
;;
;; Load order: this file needs residual.scm loaded first (for rconde/d,
;; define-relation/d, etc.) -- as with restricted-interp-following.scm and
;; following.scm, this file does not load residual.scm itself; callers must
;; sequence the loads (see load.scm, which loads residual.scm, and
;; test-all.scm / tests/residual-interp.scm for the load order in practice).
;;
;; Recursive relations here use define-relation/d rather than a plain define:
;; r-forms build the whole goal tree eagerly except at g-call boundaries, so a
;; plain define with self-reference would loop at construction time.

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
      ;; Unifies `out` (not env2) in the guard so that when `out`
      ;; is ground the clause can commit immediately. This reverses the
      ;; accumulation direction vs. ext-env*o; see interp-d-adaptations
      ;; design note. Semantically equivalent given the rabsento/d below.
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
      ;; The plain interp relies on recursive eval of rator to
      ;; fail when rator is a syntactic keyword. Here the recursive
      ;; eval is in the body, so we must disambiguate eagerly in the
      ;; guard. See interp-d-adaptations design note.
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
