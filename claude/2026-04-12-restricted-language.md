# Restricted language for synthesis

The relational interpreters in `restricted-interp.scm` (plain miniKanren)
and `restricted-interp-following.scm` (`/d` variant for use inside a
follower) implement a small typed functional language. The language is
intentionally restricted compared to full Scheme to keep the synthesis
search space manageable.

## Grammar

```
expr ::= x                                       ; variable reference
       | n                                        ; numeric literal
       | (quote ())                               ; empty list literal
       | (cons expr expr)                          ; list construction
       | (x expr ...)                              ; application (named function only)
       | (letrec ([f (lambda (x ...) : type        ; recursive binding
                    expr)])
           expr)
       | (match expr                               ; list pattern match
           ['() expr]
           [(cons x x) expr])
       | (if (= expr expr) expr expr)              ; numeric equality conditional

type ::= number | list | (type ... -> type)

x    ::= <symbol>
n    ::= <number>
f    ::= <symbol>
```

## Key restrictions

1. **No higher-order application.** The operator position of an
   application must be a symbol (a named function), never an arbitrary
   expression. This rules out `((f x) y)` style curried calls and
   anonymous-lambda application. The restriction is enforced by
   `(symbolo rator)` / `(symbolo/d rator)` in the application clause
   of `eval-expo` / `eval-expo/d`.

   The `/d` interpreter previously had a second `conde/d` sub-clause
   allowing a pair in operator position (`(==/d rator (cons a d))`);
   this is now commented out.

2. **Simple type system.** Types are `number`, `list`, or arrow types
   `(arg-types -> result-type)`. Lists always hold numbers (`cons`
   takes a `number` and a `list`). There are no polymorphic types.

3. **Single letrec binding.** Only one function can be defined per
   `letrec`. The binding includes a type annotation
   `(lambda (args) : type body)`.

4. **Match is list-only.** Pattern matching destructures lists into
   the nil and cons cases. Match variables are implicitly typed
   (`number` for the head, `list` for the tail).

5. **Equality is numeric.** `(if (= e1 e2) e3 e4)` compares numbers
   only (both sub-expressions are evaluated at type `number`).

6. **No lambdas outside letrec.** There is no standalone `lambda`
   expression form. Functions are introduced only via `letrec`.

7. **Introduce/Eliminate distinction.** `eval-expo` threads an `EI`
   flag (`'I` for introduce, `'E` for eliminate). Most forms require
   `'I`; variable lookup and the application clause accept either.
   This prevents the search from, e.g., constructing a list in
   elimination position.

## Search-space restrictions in synthesis tests

Beyond the language restrictions above, synthesis tests often use
`absento` constraints to further prune the search. For example,
`(absento 'letrec q)` prevents the synthesizer from introducing
nested `letrec` forms inside a function body. Without this, the
search wastes time exploring recursive helper definitions that are
not needed for the target program.

## Motivation: avoiding irrefutable expansions

The common thread behind these restrictions is that miniKanren's
search, when it cannot make progress by other means, tends to expand
the program in ways that are semantically vacuous: eta-expanding a
function, nesting an application inside another application, or
wrapping a body in an unnecessary `letrec`. These expansions can
never be refuted by the input/output examples because they don't
further constrain the program's behavior — they just add indirection.
The search then spirals through an infinite family of equivalent
programs without ever backtracking.

The language restrictions and `absento` constraints are designed to
force every choice the search makes to be *meaningful*: each syntactic
form the synthesizer introduces must do real work that the examples
can confirm or refute. Disallowing higher-order application prevents
nested-application bloat; restricting `letrec` to the top level (via
`absento`) prevents gratuitous helper definitions; the type system
and introduce/eliminate distinction further narrow what can appear
where.

## Expressiveness cost

These restrictions are not free — they genuinely limit the class of
programs the synthesizer can find:

- **No higher-order helpers.** With `absento 'letrec` preventing
  nested `letrec`, there is no way to define a local helper function.
  And without standalone `lambda`, there is no way to construct a
  closure to pass to a higher-order function. So programs that factor
  logic into helpers (e.g. synthesizing `map` and a transformation
  separately) are out of reach.

- **No curried functions.** Without application in operator position,
  curried calling conventions like `((f x) y)` are impossible. Every
  function must take all its arguments at once.

- **No first-class functions as values.** Since functions can only be
  introduced via `letrec` and called by name, programs that return
  functions, store them in data structures, or pass them as arguments
  cannot be synthesized.

- **Monomorphic lists.** Lists always hold numbers. Programs over
  nested lists, lists of pairs, or heterogeneous structures are not
  expressible.

These are acceptable for the current target programs (simple
list-processing recursions like `rember` and `append`), but they
would need to be relaxed for more ambitious synthesis tasks. The open
question is how to do so without reintroducing the irrefutable-
expansion problem described above.
