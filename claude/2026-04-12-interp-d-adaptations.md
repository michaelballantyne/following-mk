# Interpreter adaptations for /d evaluation

Porting the relational interpreter from `restricted-interp.scm` to
`restricted-interp-following.scm` is mostly mechanical: `conde` becomes
`conde/d`, `fresh` becomes `fresh/d`, each primitive becomes its `/d`
variant, and each `conde/d` clause is split into `([fresh-vars] [guards]
[body])`. But the guard/body split introduces structural requirements
that the plain interpreter doesn't have, and these surface as genuine
differences between the two files.

## Application clause: eager disambiguation

In the plain interpreter, the application clause does
`(== (,rator . ,rands) expr)` and then recursively evaluates `rator`.
If `rator` happens to be a syntactic keyword like `match` or `letrec`,
the recursive `eval-expo` call fails (the keyword isn't bound in the
environment thanks to `not-in-envo` guards on the syntactic form
clauses), so there's no ambiguity at runtime.

In the `/d` interpreter, the recursive `eval-expo/d` of the rator is
in the *body*, not the guard. The guard must determine whether this
clause uniquely matches before entering the body. So the `/d` version
needs explicit disambiguation in the guard:

```scheme
(symbolo/d rator)
(absento/d rator '(quote cons letrec match if))
```

This is a general pattern: any disambiguation that the plain interpreter
achieves implicitly through recursive evaluation must be made explicit
in guards for the `/d` version.

## ext-env*o accumulation direction

The two versions of `ext-env*o` build the environment in opposite
directions:

- **Plain** (`ext-env*o`): threads the environment forward. Each
  binding is consed onto the front, and the extended environment is
  passed to the recursive call. The last parameter ends up outermost
  (found first by lookup).

- **`/d`** (`ext-env*o/d`): unifies the output in the guard. The
  current binding is matched against the head of `out`, and the
  recursive call builds the tail from the original `env`. The first
  parameter ends up outermost.

The `/d` direction is motivated by determinacy: when `out` is known
(common during follower evaluation, where the environment is often
ground), unifying it in the guard lets `conde/d` pattern-match on
the structure immediately.

With distinct parameter names the two directions are semantically
equivalent. To guarantee this, both versions now enforce uniqueness
via `(absento x dx*)` / `(absento/d x dx*)`, which checks that each
parameter name is absent from the rest of the parameter list. This
also benefits synthesis by ruling out useless duplicate-parameter
programs from the search space.

## General principle

The guard/body split in `conde/d` means the `/d` interpreter must
front-load enough work into guards to achieve determinacy. Anything
the plain interpreter resolves lazily through recursive evaluation
may need to be resolved eagerly via constraints in the guard. This
is the cost of determinacy-directed evaluation: the programmer must
think about what information is available at guard time and arrange
for disambiguation to happen there.
