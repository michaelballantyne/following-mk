; Relational interpreter emulating ideas from "Type-and-example-directed program synthesis"
; by 	Peter-Michael Osera	and Steve Zdancewic (http://dl.acm.org/citation.cfm?id=2738007)
; From https://github.com/michaelballantyne/scheme-workshop-2015

(define empty-env/d '())

(define (not-in-envo/d x env)
  (conde/d
    ([]
     [(==/d empty-env/d env)]
     [])
    ([y b rest]
     [(==/d `((,y . ,b) . ,rest) env) (=/=/d y x)]
     [(not-in-envo/d x rest)])))

(define (lookupo/d x env t type)
  (fresh/d (y b rest)
    (==/d `((,y . ,b) . ,rest) env)
    (conde/d
      ([]
       [(==/d x y)]
       [(conde/d
          ([]
           [(==/d `(val ,type . ,t) b)]
           [])
          ([lam-expr]
           [(==/d `(rec ,type . ,lam-expr) b) (==/d `(closure ,lam-expr ,env) t)]
           []))])
      ([]
       [(=/=/d x y)]
       [(lookupo/d x rest t type)]))))

(define (list-of-symbolso/d los)
  (conde/d
    ([]
     [(==/d '() los)]
     [])
    ([a d]
     [(==/d `(,a . ,d) los) (symbolo/d a)]
     [(list-of-symbolso/d d)])))

(define (eval-listo/d expr env val type)
  (conde/d
    ([]
     [(==/d '() expr) (==/d '() val)]
     [])
    ([a d v-a v-d t-a t-d]
     [(==/d `(,a . ,d) expr) (==/d `(,v-a . ,v-d) val) (==/d `(,t-a . ,t-d) type)]
     [(eval-expo/d a env v-a 'I t-a) (eval-listo/d d env v-d t-d)])))

(define (ext-env*o/d x* a* t* env out)
  (conde/d
    ([]
     [(==/d '() x*) (==/d '() a*) (==/d env out)]
     [])
    ([x a dx* da* env2 t dt*]
     [(==/d `(,x . ,dx*) x*)
      (==/d `(,a . ,da*) a*)
      (==/d `(,t . ,dt*) t*)
      ;; NB: unifies `out` (not env2) in the guard so that when `out`
      ;; is ground the clause can commit immediately. This reverses the
      ;; accumulation direction vs. ext-env*o; see interp-d-adaptations
      ;; design note. Semantically equivalent given the absento/d below.
      (==/d `((,x . (val ,t . ,a)) . ,env2) out)
      (symbolo/d x)
      (symbolo/d t)
      (absento/d x dx*)]
     [(ext-env*o/d dx* da* dt* env env2)])))

(define (evalo/d expr val)
  (fresh/d (type)
    (eval-expo/d expr empty-env/d val 'I type)))

(define (eval-expo/d expr env val EI type)
  (conde/d
    ([]
     [(symbolo/d expr)]
     [(lookupo/d expr env val type)])
    ([]
     [(==/d EI 'I)
      (==/d type 'list)
      (==/d '(quote ()) expr)
      (==/d '() val)
      (not-in-envo/d 'quote env)]
     [])
    ([e1 e2 v1 v2]
     [(==/d EI 'I)
      (==/d type 'list)
      (==/d `(cons ,e1 ,e2) expr)
      (==/d `(,v1 . ,v2) val)
      (not-in-envo/d 'cons env)]
     [(eval-expo/d e1 env v1 'I 'number) (eval-expo/d e2 env v2 'I 'list)])
    ([rator x* rands body env^ a* at* res]
     [(==/d `(,rator . ,rands) expr)
      ;; NB: the plain interp relies on recursive eval of rator to
      ;; fail when rator is a syntactic keyword. Here the recursive
      ;; eval is in the body, so we must disambiguate eagerly in the
      ;; guard. See interp-d-adaptations design note.
      (symbolo/d rator)
      (absento/d rator '(quote cons letrec match if))]
     [(eval-expo/d rator
                   env
                   `(closure (lambda ,x*
                               ,body)
                             ,env^)
                   'E
                   `(,at* -> ,type))
      (eval-listo/d rands env a* at*)
      (ext-env*o/d x* a* at* env^ res)
      (eval-expo/d body res val 'I type)])
    ([p-name x body letrec-body ftype]
     [(==/d EI 'I)
      (==/d `(letrec ([,p-name (lambda ,x : ,ftype
                                 ,body)])
               ,letrec-body)
            expr)
      (not-in-envo/d 'letrec env)]
     [(list-of-symbolso/d x)
      (eval-expo/d letrec-body
                   `((,p-name . (rec ,ftype
                                     . (lambda ,x
                                         ,body)))
                     . ,env)
                   val
                   'I
                   type)])
    ([e1 e2 e3 v1 s1 s2]
     [(==/d EI 'I)
      (==/d `(match ,e1
               ['() ,e2]
               [(cons ,s1 ,s2) ,e3])
            expr)
      (symbolo/d s1)
      (symbolo/d s2)
      (not-in-envo/d 'match env)]
     [(eval-expo/d e1 env v1 'E 'list)
      (conde/d
        ([]
         [(==/d '() v1)]
         [(eval-expo/d e2 env val 'I type)])
        ([a d]
         [(==/d `(,a . ,d) v1) (=/=/d a 'closure)]
         [(eval-expo/d e3
                       `((,s1 . (val number . ,a)) (,s2 . (val list . ,d)) . ,env)
                       val
                       'I
                       type)]))])
    ([e1 e2 e3 e4 v1 v2]
     [(==/d EI 'I) (==/d `(if (= ,e1 ,e2) ,e3 ,e4) expr) (not-in-envo/d 'if env)]
     [(eval-expo/d e1 env v1 'E 'number)
      (eval-expo/d e2 env v2 'E 'number)
      (conde/d
        ([]
         [(==/d v1 v2)]
         [(eval-expo/d e3 env val 'I type)])
        ([]
         [(=/=/d v1 v2)]
         [(eval-expo/d e4 env val 'I type)]))])

    ([]
     [(==/d EI 'I) (==/d type 'number) (numbero/d expr) (==/d expr val)]
     [])))
