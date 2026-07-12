;; restricted-interp-untyped-following.scm --- /d (determinacy-directed)
;; version of restricted-interp-untyped.scm, for use inside a follower.
;;
;; Mirrors restricted-interp-following.scm clause-for-clause, but with the
;; `type` argument removed everywhere (see restricted-interp-untyped.scm for
;; the untyped semantics).  Everything not type-related is preserved exactly,
;; including the keyword-disambiguation guard
;;   (absento/d rator '(quote cons letrec match if))
;; in the application clause: the plain interp relies on recursive eval of
;; rator to fail on a syntactic keyword, but here that eval is in the body, so
;; keywords must be disambiguated eagerly in the guard.
;;
;; not-in-envo/d and list-of-symbolso/d are type-agnostic; they are reused
;; from restricted-interp-following.scm (loaded first).

(define empty-env-u/d '())

(define (lookupo-u/d x env t)
  (fresh/d (y b rest)
    (==/d `((,y . ,b) . ,rest) env)
    (conde/d
      ([]
       [(==/d x y)]
       [(conde/d
          ([]
           [(==/d `(val . ,t) b)]
           [])
          ([lam-expr]
           [(==/d `(rec . ,lam-expr) b) (==/d `(closure ,lam-expr ,env) t)]
           []))])
      ([]
       [(=/=/d x y)]
       [(lookupo-u/d x rest t)]))))

(define (eval-listo-u/d expr env val)
  (conde/d
    ([]
     [(==/d '() expr) (==/d '() val)]
     [])
    ([a d v-a v-d]
     [(==/d `(,a . ,d) expr) (==/d `(,v-a . ,v-d) val)]
     [(eval-expo-u/d a env v-a 'I) (eval-listo-u/d d env v-d)])))

(define (ext-env*o-u/d x* a* env out)
  (conde/d
    ([]
     [(==/d '() x*) (==/d '() a*) (==/d env out)]
     [])
    ([x a dx* da* env2]
     [(==/d `(,x . ,dx*) x*)
      (==/d `(,a . ,da*) a*)
      ;; Unifies `out` (not env2) in the guard so that when `out`
      ;; is ground the clause can commit immediately -- see the typed version.
      (==/d `((,x . (val . ,a)) . ,env2) out)
      (symbolo/d x)
      (absento/d x dx*)]
     [(ext-env*o-u/d dx* da* env env2)])))

(define (evalo-u/d expr val)
  (eval-expo-u/d expr empty-env-u/d val 'I))

(define (eval-expo-u/d expr env val EI)
  (conde/d
    ([]
     [(symbolo/d expr)]
     [(lookupo-u/d expr env val)])
    ([]
     [(==/d EI 'I)
      (==/d '(quote ()) expr)
      (==/d '() val)
      (not-in-envo/d 'quote env)]
     [])
    ([e1 e2 v1 v2]
     [(==/d EI 'I)
      (==/d `(cons ,e1 ,e2) expr)
      (==/d `(,v1 . ,v2) val)
      (not-in-envo/d 'cons env)]
     [(eval-expo-u/d e1 env v1 'I) (eval-expo-u/d e2 env v2 'I)])
    ([rator x* rands body env^ a* res]
     [(==/d `(,rator . ,rands) expr)
      ;; disambiguate keywords eagerly -- see the typed version's note.
      (symbolo/d rator)
      (absento/d rator '(quote cons letrec match if))]
     [(eval-expo-u/d rator
                     env
                     `(closure (lambda ,x*
                                 ,body)
                               ,env^)
                     'E)
      (eval-listo-u/d rands env a*)
      (ext-env*o-u/d x* a* env^ res)
      (eval-expo-u/d body res val 'I)])
    ([p-name x body letrec-body]
     [(==/d EI 'I)
      (==/d `(letrec ([,p-name (lambda ,x
                                 ,body)])
               ,letrec-body)
            expr)
      (not-in-envo/d 'letrec env)]
     [(list-of-symbolso/d x)
      (eval-expo-u/d letrec-body
                     `((,p-name . (rec . (lambda ,x
                                           ,body)))
                       . ,env)
                     val
                     'I)])
    ([e1 e2 e3 v1 s1 s2]
     [(==/d EI 'I)
      (==/d `(match ,e1
               ['() ,e2]
               [(cons ,s1 ,s2) ,e3])
            expr)
      (symbolo/d s1)
      (symbolo/d s2)
      (not-in-envo/d 'match env)]
     [(eval-expo-u/d e1 env v1 'E)
      (conde/d
        ([]
         [(==/d '() v1)]
         [(eval-expo-u/d e2 env val 'I)])
        ([a d]
         [(==/d `(,a . ,d) v1) (=/=/d a 'closure)]
         [(eval-expo-u/d e3
                         `((,s1 . (val . ,a)) (,s2 . (val . ,d)) . ,env)
                         val
                         'I)]))])
    ([e1 e2 e3 e4 v1 v2]
     [(==/d EI 'I) (==/d `(if (= ,e1 ,e2) ,e3 ,e4) expr) (not-in-envo/d 'if env)]
     [(eval-expo-u/d e1 env v1 'E)
      (eval-expo-u/d e2 env v2 'E)
      (numbero/d v1)
      (numbero/d v2)
      (conde/d
        ([]
         [(==/d v1 v2)]
         [(eval-expo-u/d e3 env val 'I)])
        ([]
         [(=/=/d v1 v2)]
         [(eval-expo-u/d e4 env val 'I)]))])

    ([]
     [(==/d EI 'I) (numbero/d expr) (==/d expr val)]
     [])))
