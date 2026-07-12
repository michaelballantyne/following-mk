# The explored population is ~98% unconditionally divergent at every level

Michael suggested sampling the candidate stream at scale, distributed
across ID levels. Done via the `*sample-term-every*` hook: 12,992
candidates captured from the no-follower bounded search (append bounds
11/15/19/23; rember 15/19/23/27), 3,249 downsampled uniformly, parsed
and classified by script (sonnet agent; 13 hand-verified
classifications, ground-count cross-check matched grep exactly).
"Unconditionally divergent" = every control path through the committed
structure applies the task's own function — refutable by the rung-1
termination check, unrefutable by examples.

## Composition (percent of sampled stream)

| task | bound | app-headed | has any match/if | uncond. divergent | ground |
|---|---:|---:|---:|---:|---:|
| append | 11 | 98.7% | 0.0% | **98.7%** | 66.8% |
| append | 15 | 99.7% | 0.0% | **99.7%** | 14.8% |
| append | 19 | 100% | 0.0% | **100%** | 3.6% |
| append | 23 | 100% | 0.0% | **100%** | 0.8% |
| rember | 15 | 98.5% | 0.5% | **98.5%** | 14.7% |
| rember | 19 | 97.9% | 6.0% | **97.9%** | 6.8% |
| rember | 23 | 98.2% | 6.4% | **98.2%** | 3.0% |
| rember | 27 | 97.0% | 6.3% | **98.3%** | 0.6% |

The earlier bound-11 eyeball (142/143 caseless) was not a low-bound
artifact: **the divergent fraction does not shrink with bound.** Case
analysis essentially never gets committed — append commits none in
1,564 samples at any bound; rember's ~6% of `if`s all use the vacuous
condition `(= e e)` with a hole fallback (the cheapest way to satisfy
the if-clause's guard), not genuine base-case splits. The single
match-headed candidate in 3,249 samples appears at rember bound 27.

Since sampling is per-surviving-conde-entry, the stream weights
candidates by the *work spent on them*. Reading: **~98% of all search
work, at every level, is spent unfolding candidates that a syntactic
no-base-case check refutes the moment they're committed.**

## Implications

1. **The rung-1 termination view is predicted to be transformative,
   not incremental**, on these tasks: it deletes the population that
   consumes ~everything. (Prototype in flight as of this entry.)
2. **Explains the seeded result**: seeding the match skeleton removes
   exactly this population, and indeed the seeded baseline terminates
   in 6.2s where whole-body rember-full times out.
3. **Why so little case structure?** The search's work concentrates in
   app-headed candidates because divergent unfoldings are
   self-reinforcing: each unfolding step of a caseless candidate
   spawns more evaluation work for it, and fair interleaving keeps
   feeding it slots until the (unsound) depth cutoff. The match/if
   clauses aren't rare in the *grammar*; they're rare in the *work
   distribution*.
4. My earlier prediction (verdict entry: divergence dominance is a
   below-skeleton-threshold phenomenon) was **wrong** in an
   interesting way: the threshold isn't about what *fits* under the
   bound, it's about what the work distribution *concentrates on*, and
   that concentration persists at every bound measured.

Raw data: session scratchpad (`candidates-multilevel-raw.log`,
`candidates-multilevel-sample.txt`, `classify.py`) — ephemeral;
regenerate with the hook (`*sample-term-every*`) + the capture pattern
described here if needed.
