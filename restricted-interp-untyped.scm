;; restricted-interp-untyped.scm --- an UNTYPED variant of restricted-interp.scm.
;;
;; Dynamically-typed Lisp semantics: the `type` argument that threaded through
;; every clause of the typed interpreter is GONE.  All type information that
;; used to live in the interpreter now lives ONLY in the `type-ofo/d` follower
;; view (experiments/views.scm).  The point of the split is an
;; information-attribution experiment: with the generator untyped, a static
;; type error is refutable by an example ONLY if evaluation actually reaches
;; the stuck expression; a statically ill-typed but never-executed subterm is
;; invisible to example-checking and only `type-ofo/d` can kill it.
;;
;; Semantic differences from the typed interpreter (restricted-interp.scm):
;;   * env entries become (val . v) and (rec . lam) -- no type component.
;;   * letrec template parses (lambda x body) -- no `: ftype` annotation.
;;   * cons is TOTAL: any values for both arguments (was number x list).
;;   * match binds the two pattern vars to arbitrary values (was number/list);
;;     a scrutinee that is a number/closure simply matches no clause = stuck.
;;   * (= e1 e2) requires BOTH operands to evaluate to numbers (numbero);
;;     anything else is stuck.  This is the sole remaining dynamic type check.
;;   * number literals evaluate to themselves, with no type constraint.
;; Everything not type-related (the EI flag, arity via structural walk, the
;; keyword-disambiguation logic) is kept exactly as in the typed version.
;;
;; not-in-envo and list-of-symbolso are type-agnostic; they are reused from
;; restricted-interp.scm (loaded first in test-all.scm / run.sh).

(define empty-env-u '())

(define (lookupo-u x env t)
  (fresh (y b rest)
    (== `((,y . ,b) . ,rest) env)
    (conde
      ((== x y)
       (conde
         ((== `(val . ,t) b))
         ((fresh (lam-expr)
            (== `(rec . ,lam-expr) b)
            (== `(closure ,lam-expr ,env) t)))))
      ((=/= x y)
       (lookupo-u x rest t)))))

(define (eval-listo-u expr env val)
  (conde
    ((== '() expr)
     (== '() val))
    ((fresh (a d v-a v-d)
       (== `(,a . ,d) expr)
       (== `(,v-a . ,v-d) val)
       (eval-expo-u a env v-a 'I)
       (eval-listo-u d env v-d)))))

(define (ext-env*o-u x* a* env out)
  (conde
    ((== '() x*)
     (== '() a*)
     (== env out))
    ((fresh (x a dx* da* env2)
       (== `(,x . ,dx*) x*)
       (== `(,a . ,da*) a*)
       (== `((,x . (val . ,a)) . ,env) env2)
       (symbolo x)
       (absento x dx*)
       (ext-env*o-u dx* da* env2 out)))))

(define (evalo-u expr val)
  (eval-expo-u expr empty-env-u val 'I))

(define (eval-expo-u expr env val EI)
  (conde
    ; EI can be either E or I here
    ((symbolo expr)
     (lookupo-u expr env val))

    ((== EI 'I)
     (== '(quote ()) expr)
     (== '() val)
     (not-in-envo 'quote env))

    ((== EI 'I)
     (fresh (e1 e2 v1 v2)
       (== `(cons ,e1 ,e2) expr)
       (== `(,v1 . ,v2) val)
       (not-in-envo 'cons env)
       (eval-expo-u e1 env v1 'I)
       (eval-expo-u e2 env v2 'I)))

    ((fresh (rator x* rands body env^ a* res)
       (== `(,rator . ,rands) expr)
       (symbolo rator)
       ; EI can be either E or I here
       (eval-expo-u rator
                    env
                    `(closure (lambda ,x*
                                ,body)
                              ,env^)
                    'E)
       (eval-listo-u rands env a*)
       (ext-env*o-u x* a* env^ res)
       (eval-expo-u body res val 'I)))

    ((== EI 'I)
     (fresh (p-name x body letrec-body)
       (== `(letrec ([,p-name (lambda ,x
                                ,body)])
              ,letrec-body)
           expr)
       (list-of-symbolso x)
       (not-in-envo 'letrec env)
       (eval-expo-u letrec-body
                    `((,p-name . (rec . (lambda ,x
                                          ,body)))
                      . ,env)
                    val
                    'I)))

    ((== EI 'I)
     (fresh (e1 e2 e3 v1 s1 s2)
       (== `(match ,e1
              ['() ,e2]
              [(cons ,s1 ,s2) ,e3])
           expr)
       (symbolo s1)
       (symbolo s2)
       (not-in-envo 'match env)
       (eval-expo-u e1 env v1 'E)
       (conde
         ((== '() v1)
          (eval-expo-u e2 env val 'I))
         ((fresh (a d)
            (== `(,a . ,d) v1)
            (=/= a 'closure)
            (eval-expo-u e3
                         `((,s1 . (val . ,a)) (,s2 . (val . ,d)) . ,env)
                         val
                         'I))))))

    ((== EI 'I)
     (fresh (e1 e2 e3 e4 v1 v2)
       (== `(if (= ,e1 ,e2) ,e3 ,e4) expr)
       (not-in-envo 'if env)
       (eval-expo-u e1 env v1 'E)
       (eval-expo-u e2 env v2 'E)
       (numbero v1)
       (numbero v2)
       (conde
         ((== v1 v2)
          (eval-expo-u e3 env val 'I))
         ((=/= v1 v2)
          (eval-expo-u e4 env val 'I)))))

    ((== EI 'I)
     (numbero expr)
     (== expr val))))
