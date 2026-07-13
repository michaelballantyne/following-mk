# Generalizing the termination view: R2P works, R2T (naive disjunction) diverges

Task 1 of the session (generalize R2 beyond fixed-position decrease, so
interleave's argument-swapping recursion is admissible). Outcome: the
generalization itself (R2P) works and makes interleave feasible; the
attempt to package "R2 or R2P" as one uniform production view (R2T)
hit a **structural** divergence, recorded here as a negative with its
mechanism. Decision: per-task measure selection, not a uniform view.

## R2P — permuted-decreasing-recursiono/d (works)

At each self-call, an injective assignment of arguments to distinct
formal parameters such that each argument is equal-or-a-structural-
descendant of its assigned parameter, with ≥1 strict; assignment may
differ per call site. Sound because the injective assignment makes the
summed argument size strictly less than the summed parameter size at
every call (each source charged once, one strictly). Arity ≤2 covers
the suite; >2 is a documented error.

**R2P is INCOMPARABLE to R2, not a generalization** — the sharp finding
of the task:

| task | R2 (fixed-position) | R2P (injective multiset) |
|---|---|---|
| interleave `(interleave l2 d)` | REFUTES (swap, no fixed slot) | ACCEPTS (swap assignment) |
| rev-acc `(rev d (cons a acc))` | ACCEPTS (l decreases) | REFUTES (acc grows → sum flat) |
| rember/append/duplicate/… | ACCEPTS | ACCEPTS |

Neither subsumes the other. Measured (ce1, clean):
- **interleave becomes feasible**: R1+R2P+TY+NV+EX finds the canonical
  at bound 35, 108,475 unify(main), 2.1s — versus the R2-less stack
  which was infeasible (>240s). R2P is load-bearing for feasibility.
- rember R2→R2P: 251,834 vs 312,236 (0.81×, cheaper — extra
  non-injective pruning, e.g. `(f d d)` refuted where R2 accepts it).
- duplicate R2→R2P: 53,812 = 53,812 bit-identical (arity-1 ⇒ R2P
  reduces exactly to R2).

Gates (experiments/r2p-gates.scm): accepts all nine canonicals except
rev-acc (R2P-refuted by design), refutes the non-injective `(f d d)`
trap, stalls on holes. Suite green.

## R2T — terminating-recursiono/d (naive R2∨R2P): NON-VIABLE, diverges

Goal: one uniform view accepting whatever terminates by either measure,
so no per-task choice is needed. Built as `concluding-oro/d` (a
hand-written inf/d OR combinator that concludes on either success,
collapses to the survivor on one refutation, stalls otherwise). All
accept/refute **gates pass** (accepts all nine incl. rev-acc via R2 and
interleave via R2P; refutes only what both reject). But as a **follower**
it diverges.

**Measured divergence (clean, idle machine — not contention):**
- duplicate r2t: reaches bound 27 with unify(main) only ~4,064 but
  unify(follower) ~108,008 and climbing, then times out — while R2-only
  duplicate finishes in 0.7s / 53,812. interleave r2t: same, dies in
  bound 27+. **Signature = tiny unify-main + exploding unify-follower =
  the VIEW diverges, not the search.**
- rev-acc r2t does NOT diverge (130,166 ≈ its R2 number) — because R2P
  *refutes* rev-acc's candidates, so `concluding-oro/d` collapses to the
  clean R2-only path. The divergence is specifically in the both-live
  handling.

**Mechanism (subagent diagnosis, verified against the /d machinery, all
instrumentation reverted).** The sound `*suspend-depth*` cutoff works by
*parking the search frontier in a resume thunk*: R2 alone hard-suspends a
non-terminating candidate on fire 1 and refutes it on fire 2 by resuming
its **own** parked thunk with a fresh depth budget. `concluding-oro/d`'s
both-live paths return `(cons st or-g)` / `(hard-suspended st or-g)`,
where `or-g` re-runs **both** disjuncts *from scratch* each re-fire —
discarding the parked frontier. So when the surviving disjunct (R2P, in
the real incremental constraint context) needs more than one
suspend-window to refute a candidate, it never gets there; evalo/d then
evaluates the non-terminating candidate to the depth-20 ceiling
(measured 140k+ nested conde/d entries) and explodes.

**Why it can't be fixed inside the combinator (the structural blocker).**
The subagent implemented the obvious fix — thread each disjunct's *own*
resume thunk across fires instead of re-running from scratch (gates + 120
tests pass, bound-27 follower-unify dropped to match R2-only). It still
diverged, because each disjunct's parked frontier lives in its **own
committed scope** (different fresh vars), and the follower carries a
**single** state: resuming disjunct A's thunk from the shared state
(or B's state) mis-resumes — the frontier is stranded. Committing one
disjunct's scope so its resume works would **unsoundly assert that
disjunct**. So: an OR of two independently-suspending whole-body /d
checks is fundamentally incompatible with the single-state suspend-depth
mechanism. Clean negative.

Secondary lead (unconfirmed, worth chasing): a candidate that refutes
standalone in one window can hard-stall in the *incremental* search,
suggesting `conj/d-run` resumes evalo/d's worklist item before the
cheap termination refuter's on a re-fire — evalo/d explodes before the
refutation is reached. That points at resume-worklist **ordering** in
conj/d-run, orthogonal to the combinator.

## Decision

**Per-task measure selection**, not a uniform combined view:
- R2 (`decreasing-recursiono/d`) stays the default (all current tasks
  except interleave; cheaper, single walk).
- R2P (`permuted-decreasing-recursiono/d`) for argument-permuting
  recursion (interleave). interleave feasibility is delivered.
- R2T (`terminating-recursiono/d`) + `concluding-oro/d` are kept in
  views.scm marked NON-VIABLE, with the r2t arms as the reproduction.

This is sound and sufficient for the suite; the essential task-1 goal
(admit permuting recursion) is met by R2P. The uniform view was a
convenience that turned out to conflict with a load-bearing soundness
mechanism — a more interesting result than a free win.

## Backlog spawned

1. **Unified single-frontier termination view** — one walk that branches
   only at the per-self-call measure test (fixed-position vs permuted),
   keeping a single committed state, so there's one suspension frontier
   to deepen. The principled fix; may itself hit the single-state
   tension in a new form (needs design).
2. **conj/d-run resume-worklist ordering** — run cheap refuting views
   before evalo/d on re-fire. Touches the engine; connects to the
   broader "view scheduling" theme (and the CDCL-note's stall-ordering
   observations). Measure whether it alone rescues R2T.
