;; termination-view3.scm --- rung 3 / third follower view: a /d TYPE checker
;; for the restricted language, composed into a follower alongside rungs 1 & 2.
;;
;; Rungs 1 (`base-case-patho/d`) and 2 (`decreasing-recursiono/d`) are purely
;; STRUCTURAL termination checks.  Rung 2 explicitly does NOT model types: it
;; ACCEPTS `(rember e a)` where `a` is the (numeric) list head passed at the
;; (list) recursion position, because `a` is a strict structural descendant of
;; `l`.  Such a body is ill-typed and evaluation-refutable, but examples only
;; refute it via unsound depth cutoffs.  This view refutes it syntactically the
;; instant the committed structure violates the declared types.
;;
;;   (type-ofo/d tyenv body type)
;;     succeeds  iff  `body` type-checks at `type` under `tyenv`
;;     fails     iff  the committed structure is ill-typed at `type`
;;     stalls         while the term is too holey to decide either way
;;
;; `tyenv` is a Scheme-level assoc list of (name . type) where name is an
;; mk-term (usually a ground symbol) and type is a ground type term.  Types:
;;   number | list | ((t1 ... tn) -> tr)   (arrows only via the letrec annot.)
;;
;; The three-way stall/commit/refute behaviour is inherited from conde/d, the
;; rung-1/2 technique: term-shape discrimination lives in the guards, so a hole
;; leaves several sibling clauses live -> stall; a committed shape leaves one.
;;
;; --- deliberate search-space restrictions (documented, like rungs 1 & 2) ---
;;
;;  * RECOGNIZED-CONSTRUCTS-ONLY.  The task allows being conservative on
;;    unrecognized constructs (letrec-in-body, non-recursive-fn applications,
;;    non-'() quote literals) by succeeding without constraining -- but a
;;    conde/d catch-all clause is always live and would make EVERYTHING stall.
;;    So instead we REQUIRE recognized constructs: an unrecognized body is
;;    REFUTED.  This is a search-space restriction (like no-shadowing), not a
;;    soundness statement about the language.  On these benchmarks the only
;;    binding in scope is the recursive fn, and the target answers contain no
;;    nested letrec or foreign application, so nothing real is discarded.
;;
;;  * No-shadowing: a match pattern var may not shadow any name already in
;;    `tyenv` (all tyenv names are type-classified).  Shadowing would corrupt
;;    the by-name type lookup.  A body that shadows is refuted.  (=/=/d guards,
;;    exactly as rungs 1 & 2.)
;;
;;  * Only the `(quote ())` quote literal is typed (-> list); any other quote
;;    form is refuted.  The language's interpreter only produces (quote ()).

(load "experiments/termination-view2.scm") ; brings fail/d-goal, no-shadow/d,
                                            ; termination-view-app-keywords, + tv1

(define type-view-app-keywords termination-view-app-keywords) ; '(quote cons letrec match if)

;; ------------------------------------------------------------------
;; look up `name`'s type in the Scheme-level `tyenv`.  Written as a nested
;; conde/d that discriminates by ==/d / =/=/d on the name: a HOLE name makes
;; both clauses live -> stall; a committed name leaves one live.  An exhausted
;; tyenv (name not found) -> refute (unbound reference is ill-typed).
;; ------------------------------------------------------------------
(define (tyenv-lookupo/d tyenv name type)
  (if (null? tyenv)
      fail/d-goal
      (let ([n (car (car tyenv))]
            [t (cdr (car tyenv))])
        (conde/d
          ([]
           [(==/d name n)]
           [(==/d type t)])
          ([]
           [(=/=/d name n)]
           [(tyenv-lookupo/d (cdr tyenv) name type)])))))

;; ------------------------------------------------------------------
;; type each operand of an application at its declared argument type.  The
;; rands come from the (holey) body; the argtypes come from the (ground) arrow
;; type looked up for the operator.  AND over the two lists walked together;
;; a length mismatch (arity error) -> refute; a holey rand tail -> stall.
;; ------------------------------------------------------------------
(define (types-listo/d tyenv rands argtypes)
  (conde/d
    ([]
     [(==/d '() rands) (==/d '() argtypes)]
     [])
    ([a d ta td]
     [(==/d `(,a . ,d) rands) (==/d `(,ta . ,td) argtypes)]
     [(type-ofo/d tyenv a ta) (types-listo/d tyenv d td)])))

;; ------------------------------------------------------------------
;; the public relation.
;; ------------------------------------------------------------------
(define (type-ofo/d tyenv body type)
  (conde/d
    ;; number literal : number
    ([]
     [(numbero/d body)]
     [(==/d type 'number)])
    ;; variable reference : whatever tyenv says
    ([]
     [(symbolo/d body)]
     [(tyenv-lookupo/d tyenv body type)])
    ;; '() : list
    ([]
     [(==/d '(quote ()) body)]
     [(==/d type 'list)])
    ;; (cons e1 e2) : list, with e1 : number and e2 : list
    ([e1 e2]
     [(==/d `(cons ,e1 ,e2) body)]
     [(==/d type 'list)
      (type-ofo/d tyenv e1 'number)
      (type-ofo/d tyenv e2 'list)])
    ;; (match e ['() e1] [(cons x y) e2]) : e : list; e1 : T; e2 : T with
    ;; x : number, y : list added to tyenv.  No-shadowing on x, y.
    ([e e1 x y e2]
     [(==/d `(match ,e ['() ,e1] [(cons ,x ,y) ,e2]) body)
      (symbolo/d x)
      (symbolo/d y)
      (no-shadow/d (list x y) (map car tyenv))]
     [(type-ofo/d tyenv e 'list)
      (type-ofo/d tyenv e1 type)
      (type-ofo/d (cons (cons x 'number) (cons (cons y 'list) tyenv)) e2 type)])
    ;; (if (= e1 e2) e3 e4) : e1,e2 : number; e3,e4 : T
    ([e1 e2 e3 e4]
     [(==/d `(if (= ,e1 ,e2) ,e3 ,e4) body)]
     [(type-ofo/d tyenv e1 'number)
      (type-ofo/d tyenv e2 'number)
      (type-ofo/d tyenv e3 type)
      (type-ofo/d tyenv e4 type)])
    ;; application (rator rand ...): rator's arrow type ((t1 ... tn) -> tr) is
    ;; looked up in tyenv; result type = tr, each rand at its declared ti.
    ([rator rands ftype argtypes tr]
     [(==/d `(,rator . ,rands) body)
      (symbolo/d rator)
      (absento/d rator type-view-app-keywords)]
     [(tyenv-lookupo/d tyenv rator ftype)
      (==/d `(,argtypes -> ,tr) ftype)
      (==/d type tr)
      (types-listo/d tyenv rands argtypes)])))

;;; ------------------------------------------------------------------
;;; Validation gates.  Run when this file is loaded (./run.sh loads it).
;;; ------------------------------------------------------------------

(define rember-tyenv '((rember . ((number list) -> list)) (e . number) (l . list)))
(define append-tyenv '((append . ((list list) -> list)) (l . list) (s . list)))

;; ACCEPT: canonical rember body type-checks at list.
(test "type-ofo/d: canonical rember accepted"
  (run 1 (q)
    (follower q
      (type-ofo/d rember-tyenv
        '(match l ['() l] [(cons a d) (if (= a e) d (cons a (rember e d)))])
        'list)))
  '(_.0))

;; ACCEPT: canonical append body type-checks at list.
(test "type-ofo/d: canonical append accepted"
  (run 1 (q)
    (follower q
      (type-ofo/d append-tyenv
        '(match l ['() s] [(cons a d) (cons a (append d s))])
        'list)))
  '(_.0))

;; REFUTE (ground): (rember e a) -- `a` is a number (list head) passed at the
;; list argument position.  Rung 2 accepts this; the type view refutes it.
(test "type-ofo/d: (rember e a) at list position refuted"
  (run 1 (q)
    (follower q
      (type-ofo/d rember-tyenv
        '(match l ['() l] [(cons a d) (rember e a)])
        'list)))
  '())

;; REFUTE (ground): (cons l l) as the whole body -- `l` (a list) at the number
;; position of cons.
(test "type-ofo/d: (cons l l) refuted"
  (run 1 (q)
    (follower q
      (type-ofo/d rember-tyenv '(cons l l) 'list)))
  '())

;; STALL: holey match arms -- cannot decide, must leave the holes unbound.
(test "type-ofo/d: holey match stalls, holes unbound"
  (run 1 (h1 h2)
    (follower (list h1 h2)
      (type-ofo/d rember-tyenv
        `(match l ['() ,h1] [(cons a d) ,h2])
        'list)))
  '((_.0 _.1)))

;; STALL: bare hole is undetermined.
(test "type-ofo/d: bare hole stalls"
  (run 1 (q)
    (follower q (type-ofo/d rember-tyenv q 'list)))
  '(_.0))
