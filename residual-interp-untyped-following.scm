;; residual-interp-untyped-following.scm --- residual-engine port of
;; restricted-interp-untyped-following.scm, mirroring the way
;; residual-interp-following.scm ports restricted-interp-following.scm.
;;
;; Clause-for-clause port of restricted-interp-untyped-following.scm to the
;; residual engine's determinacy-directed constructors (rconde/d, rfresh/d,
;; r==/d, r=/=/d, rsymbolo/d, rnumbero/d, rabsento/d, define-relation/d), with
;; the `type` argument removed everywhere (see restricted-interp-untyped.scm
;; for the untyped semantics). Everything not type-related is preserved
;; exactly, including the keyword-disambiguation guard
;;   (rabsento/d rator '(quote cons letrec match if))
;; in the application clause -- see restricted-interp-untyped-following.scm's
;; header comment for why that guard has to be eager here.
;;
;; Names use the -res suffix, matching residual-interp-following.scm's
;; convention, with a -u- infix (as in the closure-engine originals) to
;; distinguish the untyped port from the typed one: evalo-u/d-res,
;; eval-expo-u/d-res, lookupo-u/d-res, eval-listo-u/d-res, ext-env*o-u/d-res,
;; empty-env-u/d-res.
;;
;; not-in-envo/d-res and list-of-symbolso/d-res are type-agnostic; they are
;; REUSED from residual-interp-following.scm (loaded first) -- same reuse
;; relationship as the closure-engine originals (see
;; restricted-interp-untyped-following.scm's header comment).
;;
;; Load order: this file needs residual.scm and residual-interp-following.scm
;; loaded first (for rconde/d, define-relation/d, not-in-envo/d-res,
;; list-of-symbolso/d-res). This file does not load them itself; callers must
;; sequence the loads (see load.scm's pattern and test-all.scm's load order).
;;
;; Recursive relations here use define-relation/d rather than a plain define:
;; r-forms build the whole goal tree eagerly except at g-call boundaries, so a
;; plain define with self-reference would loop at construction time.

(define empty-env-u/d-res '())

(define-relation/d (lookupo-u/d-res x env t)
  (rfresh/d (y b rest)
    (r==/d `((,y . ,b) . ,rest) env)
    (rconde/d
      ([]
       [(r==/d x y)]
       [(rconde/d
          ([]
           [(r==/d `(val . ,t) b)]
           [])
          ([lam-expr]
           [(r==/d `(rec . ,lam-expr) b) (r==/d `(closure ,lam-expr ,env) t)]
           []))])
      ([]
       [(r=/=/d x y)]
       [(lookupo-u/d-res x rest t)]))))

(define-relation/d (eval-listo-u/d-res expr env val)
  (rconde/d
    ([]
     [(r==/d '() expr) (r==/d '() val)]
     [])
    ([a d v-a v-d]
     [(r==/d `(,a . ,d) expr) (r==/d `(,v-a . ,v-d) val)]
     [(eval-expo-u/d-res a env v-a 'I) (eval-listo-u/d-res d env v-d)])))

(define-relation/d (ext-env*o-u/d-res x* a* env out)
  (rconde/d
    ([]
     [(r==/d '() x*) (r==/d '() a*) (r==/d env out)]
     [])
    ([x a dx* da* env2]
     [(r==/d `(,x . ,dx*) x*)
      (r==/d `(,a . ,da*) a*)
      ;; Unifies `out` (not env2) in the guard so that when `out`
      ;; is ground the clause can commit immediately -- see the typed version.
      (r==/d `((,x . (val . ,a)) . ,env2) out)
      (rsymbolo/d x)
      (rabsento/d x dx*)]
     [(ext-env*o-u/d-res dx* da* env env2)])))

(define (evalo-u/d-res expr val)
  (eval-expo-u/d-res expr empty-env-u/d-res val 'I))

(define-relation/d (eval-expo-u/d-res expr env val EI)
  (rconde/d
    ([]
     [(rsymbolo/d expr)]
     [(lookupo-u/d-res expr env val)])
    ([]
     [(r==/d EI 'I)
      (r==/d '(quote ()) expr)
      (r==/d '() val)
      (not-in-envo/d-res 'quote env)]
     [])
    ([e1 e2 v1 v2]
     [(r==/d EI 'I)
      (r==/d `(cons ,e1 ,e2) expr)
      (r==/d `(,v1 . ,v2) val)
      (not-in-envo/d-res 'cons env)]
     [(eval-expo-u/d-res e1 env v1 'I) (eval-expo-u/d-res e2 env v2 'I)])
    ([rator x* rands body env^ a* res]
     [(r==/d `(,rator . ,rands) expr)
      ;; disambiguate keywords eagerly -- see the typed version's note.
      (rsymbolo/d rator)
      (rabsento/d rator '(quote cons letrec match if))]
     [(eval-expo-u/d-res rator
                         env
                         `(closure (lambda ,x*
                                     ,body)
                                   ,env^)
                         'E)
      (eval-listo-u/d-res rands env a*)
      (ext-env*o-u/d-res x* a* env^ res)
      (eval-expo-u/d-res body res val 'I)])
    ([p-name x body letrec-body]
     [(r==/d EI 'I)
      (r==/d `(letrec ([,p-name (lambda ,x
                                  ,body)])
                ,letrec-body)
             expr)
      (not-in-envo/d-res 'letrec env)]
     [(list-of-symbolso/d-res x)
      (eval-expo-u/d-res letrec-body
                         `((,p-name . (rec . (lambda ,x
                                               ,body)))
                           . ,env)
                         val
                         'I)])
    ([e1 e2 e3 v1 s1 s2]
     [(r==/d EI 'I)
      (r==/d `(match ,e1
                ['() ,e2]
                [(cons ,s1 ,s2) ,e3])
             expr)
      (rsymbolo/d s1)
      (rsymbolo/d s2)
      (not-in-envo/d-res 'match env)]
     [(eval-expo-u/d-res e1 env v1 'E)
      (rconde/d
        ([]
         [(r==/d '() v1)]
         [(eval-expo-u/d-res e2 env val 'I)])
        ([a d]
         [(r==/d `(,a . ,d) v1) (r=/=/d a 'closure)]
         [(eval-expo-u/d-res e3
                             `((,s1 . (val . ,a)) (,s2 . (val . ,d)) . ,env)
                             val
                             'I)]))])
    ([e1 e2 e3 e4 v1 v2]
     [(r==/d EI 'I) (r==/d `(if (= ,e1 ,e2) ,e3 ,e4) expr) (not-in-envo/d-res 'if env)]
     [(eval-expo-u/d-res e1 env v1 'E)
      (eval-expo-u/d-res e2 env v2 'E)
      (rnumbero/d v1)
      (rnumbero/d v2)
      (rconde/d
        ([]
         [(r==/d v1 v2)]
         [(eval-expo-u/d-res e3 env val 'I)])
        ([]
         [(r=/=/d v1 v2)]
         [(eval-expo-u/d-res e4 env val 'I)]))])

    ([]
     [(r==/d EI 'I) (rnumbero/d expr) (r==/d expr val)]
     [])))

;; Convenience: wrap the residual evalo-u/d for use with (follower term ...).
(define (evalo-u/d-r expr val)
  (follower-residual-goal (evalo-u/d-res expr val)))
