# Benchmark wave 1: six new tasks — stack transfers 5/6, two human canonicals beaten, R2 is load-bearing

Michael's directive: expand the benchmark range before other complex
work. Six tasks built this session (task design + gates delegated;
spec fixes, measurements, and verification in the main loop):
member? (boolean-as-number), last, swap-pairs, evens, rev-acc,
interleave. All follow the tv4ex pattern (full stack R1+R2+TY+NV+EX,
ce1, size-closed ID, 240s cap) plus mechanically-generated
no-follower baselines. Gates: `experiments/new-tasks-gates.scm`,
80 checks green.

## Results (cumulative to answer; * = completed levels only)

| task | outcome | bound | unify(main) | conde(main) | unify(f) | wall |
|---|---|---:|---:|---:|---:|---:|
| member? | canonical | 43 | 97,494 | 3,782 | 4.40M | 3.8s |
| last | canonical, dead branch as free var | 51 | 107,296 | 2,833 | 4.63M | 5.5s |
| swap-pairs | **smaller than canonical** (63 vs 74) | 63 | 454,748 | 11,585 | 22.2M | 27.0s |
| evens (5 ex) | **smaller than canonical** (55 vs 69) | 55 | 251,354 | 5,825 | 14.4M | 12.7s |
| rev-acc | canonical | 35 | 130,115 | 3,169 | 69.8M | 37.9s |
| interleave (stack−R2) | **infeasible** — died in bound 31 | — | 19,278* | 665* | 0.56M* | >240s |

No-follower baselines: **all six timeout at 240s, none reaches its
answer bound.** member died in 31 (completed 27, cum 11.27M unify),
last died in 31 (completed 27, 1.23M), rev-acc died in 27 (completed
23, 18.49M), interleave died in 27 (completed 23, 19.12M); swap and
evens (first bounds 43/39) died inside their FIRST level — no level
completed at all. Matched-completed-level ratios, full-stack vs
baseline: member ~1,050×, last ~175×, rev-acc ~2,380×. depth-cut = 0
in every completed full-stack level; nonzero throughout the baselines.

## Findings

1. **The stack transfers.** The same five views, zero per-task tuning,
   solve five of six new tasks in 4–38s against a baseline that solves
   none in 240s. This directly strengthens the CDCL-evaluation verdict
   (hand-learned lemmas amortize across tasks): wave 1 produced *no*
   task that needed a new task-specific view — with one important
   exception, and it's about expressiveness, not lemma discovery (#4).

2. **Two human canonicals were not minimal.** swap-pairs came back at
   63 (vs the hand-written 74) and evens, after the spec fix, at 55
   (vs 69). Both use the same trick family: in a base case, return `l`
   (or the matched tail `d`) *itself* instead of rebuilding an equal
   value — sound because inside each recursive invocation `l` is that
   invocation's argument. Both verified correct by hand on
   nil/singleton/odd/even inputs (and their derivations). Size-closed
   ID's minimality guarantee is earning: it finds programs the human
   didn't think to write, and "expected answer" in a task header is a
   hypothesis, not ground truth.

3. **Minimality is a spec-debugging instrument.** The original evens
   suite (4 examples, max input length 3) admitted a *non-recursive*
   degenerate — `(match l ['() l] [(cons a d) (cons a (match d ['() d]
   [(cons b dd) dd]))])`, i.e. head + drop-second — which the search
   dutifully returned at bound 51. A length-4 example fixed it (answer
   moved to the true minimal at 55). The failure mode was invisible in
   the gates (the canonical passes them) and surfaced *only* because
   ID returns minimal satisfying programs first. Feeds the
   symbolic-examples item: one parametric example over an
   arbitrary-length input would have killed the whole degenerate
   family up front.

4. **R2 is load-bearing for feasibility, not just pruning.**
   interleave's canonical recursion swaps arguments
   (`(interleave l2 d)`), so the fixed-position
   `decreasing-recursiono/d` soundly refutes it and had to be dropped
   from that task's stack — and the remaining stack is *infeasible*
   (died inside bound 31; completed levels show main-side pruning
   still ~1000×, so by the LOO-R2 precedent the level-31 blowup is
   presumably follower-side, but the killed level's counters are lost
   — unattributed, honestly). Consequence: the termination view needs
   a more general measure — total-size/multiset decrease across
   arguments, or lexicographic orders over argument permutations (the
   standard TRS/sized-type measures) — expressed as the same kind of
   /d view. New backlog item; this is wave 1's one genuinely new
   view-shaped need.

5. **last materialized the coverage argument.** Its answer reified the
   spec-dead nil branch as an unconstrained fresh variable (`_.0` with
   only the absento constraints) — the system literally *returns the
   hole* where the spec says nothing. Evidence for the coverage-view
   design (survey note #3) and a nice output property in its own
   right: the answer exhibits which program parts the examples never
   constrained.

6. **rev-acc is follower-heavy in a new way:** 537× unify(f) per
   unify(main) (69.8M/130k) vs rember's 45×. Two-parameter application
   plus an accumulator that *grows* along the recursion makes the
   follower's env plumbing dominate; the env-plumbing backlog item
   (95.7% of suspend cutoffs, April profile) now has a live benchmark
   attached.

## Not done this wave (deliberately)

- No surviving-stream sampling on the new tasks yet (the standing
  practice that generated rungs 1–4); queued behind the untyped+TY
  re-run so we sample the stream of the architecture we're keeping.
- No untyped+TY arms for the new tasks (the factoring landed
  mid-wave); the adopt-untyped backlog item covers porting these.
- Bidirectionality-essential tasks (backward/partial-output specs)
  remain the next wave — nothing in this wave exercises the
  substrate's differentiator yet.
