# Search order, follower pruning, and program size

## The problem

The follower prunes branches that are inconsistent with examples.
This is logically correct. But mk's fair interleaving search has no
preference for program size, so pruning can make things worse:
removing a branch changes which other branch gets CPU time next, and
the surviving branch may produce a larger, more complex answer than
the unpruned search would have found.

Observed in `ex3.scm` (rember with 4 examples, whole-body hole):

| check-follower-every | ==-counter | answer depth | answer size | wall time |
|---|---|---|---|---|
| none (no follower) | 277k | 232 | small (if/cons) | 0.5s |
| 100 | 246k | 232 | same small | 3.8s |
| 20 | 59k | 257 | larger (nested match) | 3.6s |
| 1 | — | — | timeout | >60s |

At check-every=20, the follower prunes 79% of main-search work
(59k vs 277k ==) but finds a *different, larger* answer. At
check-every=1, it times out entirely — too much follower overhead
per conde.

## Why interleaving fights simplicity

mk's interleaving (via `mplus`) alternates between branches of every
`conde`. This is fair: every branch eventually gets explored. But it
means a 20-node overfitting program and a 10-node correct program
compete for the same scheduling slots. The search doesn't know that
smaller programs are preferable.

When the follower kills a branch, the interleaving redistributes
its time slots to surviving branches. This redistribution is
effectively random with respect to program size. It can promote a
complex branch that was previously losing the scheduling race.

## Main-search depth ≠ program size

The main-search depth counter (`state-D`) counts evaluation steps
(conde calls in evalo), not AST nodes of the synthesized program.
A small correct program that runs to completion on all examples
may be at depth 232 (many evaluation steps). A large garbage
program may sit at depth 30 (started evaluating, hasn't finished).
The depth metric is anti-correlated with what we want: small
correct programs are expensive to verify, large incomplete programs
are cheap to start.

## The nested-application / nested-letrec problem

Without structural constraints, the search explores programs with
deeply nested applications `(((f a) b) c ...)` and nested letrecs.
These are syntactically valid but absurd for the synthesis task.
Each nesting level is cheap (one conde in eval-expo) so they sit
at low depth, consuming interleaving slots indefinitely. The
follower can't refute them because evaluating a 20-level nested
application hits the suspend-depth limit before reaching a
contradiction.

Mitigations tried:
- `(absento 'letrec q)` — prevents nested letrecs in the body
- Restricting application rator to symbols — prevents nested
  applications (not yet implemented)
- EI annotations — already restrict some forms to introduction
  position

These help but are grammar-specific. They don't address the
fundamental search-order problem.

## Observed size distribution (ex3.scm, check-follower-every=20)

With `(absento 'letrec q)` and EI annotations, the search explores
legitimate program shapes — no deeply nested applications. The
follower terms (874 triggers) break down by AST node count:

| size | count | examples |
|---|---|---|
| 1-3 | 295 | `(rember e l)`, `(cons e _.0)`, `_.0` |
| 4-8 | 100 | `(cons (l . _.0) _.1)`, `(match l ...)` skeleton |
| 9-15 | 224 | match/if/cons with holes — **answer is here (~15)** |
| 16-22 | 178 | nested match/if, overfitting |
| 23-31 | 77 | deeply nested match chains |

The search is wildly out of size order. The max-seen size climbs
steadily (10 → 15 → 19 → 23 → 27 → 31) while the search
repeatedly drops back to size 3. The largest observed drop: **28**
(from max-seen 31 back to size 3, at term 276 of 874).

The interleaving mixes size-3 and size-31 candidates in the same
scheduling round. The answer (~15 nodes) competes with 77 terms
that are strictly larger. A size-bounded search would never generate
those 77 terms before exhausting the size-15 candidates.

Notably, the terms are all reasonable program structures (match, if,
cons, rember calls, variable references). The grammar restrictions
(`absento 'letrec`, EI annotations, symbol rators) eliminated the
pathological cases (nested applications, nested letrecs). What
remains is a well-formed but size-disordered search.

## What would help: size-ordered search

The right search strategy for synthesis is **iterative deepening on
program size**: first try all programs of size 1, then size 2, etc.
This ensures the simplest consistent program is found first,
regardless of evaluation depth or interleaving order.

Implementation options:
1. **Structural constraint**: a `(max-term-size q n)` goal that
   fails when q's walked term exceeds n nodes. Run with increasing
   n until an answer is found. Doesn't change mk's core.
2. **Cost-frontier search**: track the walked size of the query
   variable in the state, explore branches in size order via a
   priority queue instead of fair interleaving. Changes mk's core.
3. **Size watcher as a constraint**: like absento, attach a size
   monitor to q that fires on binding. Prune immediately when q
   grows past the current frontier. Most precise, most invasive.

Option 1 is the practical starting point. Combined with the
follower, it would give: size frontier controls *which* programs
are tried, follower controls *which* programs survive example
checking. Neither alone suffices; together they address both the
search-order and pruning problems.
