# Verdict: size-bounded ID does not rescue follower pruning on synthesis

The central experiment of the 2026-07-12 session. Hypothesis (from
`claude/2026-04-12-search-order.md`, methodology in
`claude/2026-07-12-161259-search-order-constraint-relaxed.md`): under a
size-closed search, each follower refutation finishes a finite
subspace, so pruning should convert into large work savings that fair
interleaving squanders. **Falsified for this benchmark family — and
the post-mortem is more valuable than the verdict.**

Machinery: `*max-term-size*` bound checked per main-conde entry +
`experiments/` ID harness (committed earlier today). Metric:
`unify (main)` / `conde (main)` (fair-work-metric note). Levels made
finite by `*main-unsound-depth*` 1000 (unsound, identical both arms).

## Data

**rember-2** (validation task, answer size 7): both arms complete.
Cumulative to answer: 34,343 vs 18,325 unify-main = **1.9×** (fair
search on same task family: 5–6×). Invariant across suspend-depth
20/200 — the small task never hits the depth limit.

**append-full** (answer size 35): baseline exhausted bounds
11/15/19/23 (173k / 880k / 3.28M / 15.3M unify-main, ×4.3–4.7 per +4),
killed mid-27 at its 3500s timeout — **never near the answer size**.
Follower (check-every 20) completed only bound 11:

| suspend-depth | unify-main | vs baseline | follower unify | fails |
|---:|---:|---:|---:|---:|
| 5 | 118,548 | 1.46× | 646,713 | 1 |
| 20 | 116,373 | 1.49× | 4,094,703 | 3 |
| 200 | 117,813 | 1.47× | 48,896,703 | 3 |

75× more follower effort buys nothing: savings pinned at ~1.5×.
Every follower config then died by memory on bound 15 (below).

**rember-full** (answer size 47): baseline exhausted 15/19/23/27
(325k → 11.9M, ×3.1–3.5 per +4), killed mid-31 — never near 47.
Follower: **zero completed levels at any config** (ce1-sd20,
ce20-sd20, ce20-sd200 — all OOM ≥7GB).

## Post-mortem: three structural findings

**1. Low size bounds are divergence-dominated, and examples cannot
refute divergence.** A sonnet eyeball pass over 143 uniformly-sampled
candidates from the append bound-11 stream: **142/143 are caseless
recursive calls** — `(append X Y)` variants with no `match`/`if`,
because a match skeleton doesn't fit under 11 nodes. Such bodies
diverge on every input; they are refutable only by a termination
argument, which neither leader nor follower (both example-driven
evaluators) can make finitely. They die only by the *unsound* depth
cutoff. Confirmation: baseline bound-11 work scales **linearly with
the cutoff** — 78k / 173k / 445k unify-main at main-unsound-depth
300/1000/3000, same ~13 cutoff hits. Low levels are literally "a
dozen divergent spines unfolded to whatever depth we chose." The
grammar restrictions successfully removed *vacuous* junk (the eyeball
pass found none); what remains below the skeleton threshold is
*divergent* non-junk that no example-based mechanism can kill.

**2. Follower + size-closed exhaustion = memory explosion, independent
of suspend depth.** Six arms died at 7–10.6GB (three OOM, three mercy
kills), including suspend-depth **5** — so retention is NOT deep
resume chains. Hypothesis (backlog): the bounded search's
breadth-heavy, long-lived frontier keeps ~every live stream's state
alive, each carrying an F cell with per-trigger closure chains;
memory ∝ live states. The same follower config (ce20-sd20) on the
same task under *unbounded fair* search (ex3) runs in tens of MB.
First-order representation is now the leading fix candidate.

**3. Size-closed ID is a bad search order for interpreter synthesis
even without a follower.** Neither baseline got within 2 size-steps of
its answer in 3500s, while *fair* search solves ex3 (same shape as
rember-full) in 0.5s. Divergent spines force an arbitrary
depth-cutoff cost at every level, and the per-level space grows
newly-non-geometrically (level 31/27 wall times went superlinear).
The 2026-04-12 search-order note's diagnosis (fair interleaving is
size-disordered) was correct, but its remedy is worse than the
disease on this grammar.

## Where this leaves the research goal

Same-day contrast: the Latin-square existence proof
(`claude/2026-07-12-173259-latin-square-existence-proof.md`) shows
**168× / 53× / 14.5×-wall** wins where forced information is dense.
The mechanism is fine; the synthesis benchmarks offer it almost
nothing to force at whole-body granularity — the candidate population
below the skeleton threshold is unrefutable-in-principle, and above
it the config is memory-infeasible.

The next moves this implies (backlog updated):
1. **Give candidates refutable structure**: seed the match/if skeleton
   (sketch-style) or add a structural base-case requirement, so
   low-size populations are example-refutable. Re-test fair AND
   bounded search; this is the cheap, direct fix to the actual
   bottleneck found.
2. **Memory/first-order representation** — gates every
   bounded-search follower experiment.
3. **Termination-style second view**: caseless bodies are refutable
   *structurally* in an instant. A follower that carries a different
   analysis than the leader (the typechecker idea, generalized) could
   kill everything the eyeball pass found, where examples cannot.
4. Scale the FD benchmark (N=8+) to map how the win grows.
