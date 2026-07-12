# Limiter ablation: how much search does each follower view cut?

> **Note (post-reorg).** This file predates the experiments/ reorganization.
> The `tv4ex` arms it references are now `*-full-id-views.scm`, and the four
> view sources (R1/R2/TY/NV) that were chain-loaded from
> `experiments/termination-view{,2,3,4}.scm` now live in the repo-root
> `views.scm`. Later results — the untyped-interpreter factoring and the
> wave-1 tasks (member/last/swap/evens/rev-acc/interleave) — live in the
> `claude/` entries of the 2026-07-12 evening, not here.

As of **2026-07-12**, `--check-follower-every 1` (ce1), size-closed ID
protocol (the `run-id` pattern from `experiments/id-harness.scm` /
`experiments/rember-full-id-tv4.scm`), `--main-unsound-depth 1000`,
`--timeout 240` per run.  Machine: the 4-core/15GB container used for all
of 2026-07-12's measurements.

## Limiters

| tag | relation | what it refutes |
|-----|----------|-----------------|
| R1 | `base-case-patho/d` (rung 1) | bodies with no self-call-free control path (caseless spines) |
| R2 | `decreasing-recursiono/d` (rung 2) | self-calls with no fixed structurally-decreasing argument position |
| TY | `type-ofo/d` (rung 3) | ill-typed bodies under the task's declared types |
| NV | `non-vacuous-testso/d` (rung 4a) | `(if (= X X) ...)` with syntactically identical condition arguments |
| EX | `evalo/d` over the task's I/O examples | candidates whose committed structure already contradicts an example (cross-example validation inside the follower) |

All configs also run the task's examples as top-level `evalo` goals in the
main search (that is the task definition, not a limiter); EX refers only to
the *in-follower* copy of the examples.

## Reading the table (solo vs leave-one-out)

Per limiter, two measurements bracket its value:

- **solo** — ID search with ONLY that limiter in the follower.  Bounds the
  limiter's *standalone* power.
- **LOO** (leave-one-out) — the full stack (R1+R2+TY+NV+EX) minus that
  limiter.  The gap between LOO and full bounds the limiter's *unique
  marginal* contribution — what nobody else in the stack covers.

solo strong but LOO ≈ full means the limiter's pruning is real but heavily
*overlapped* by the rest of the stack (everything it deletes, others also
delete).  LOO much worse than full means the limiter is load-bearing:
it deletes a family nothing else catches.  Anchors: **none** (ID with no
follower) and **full** (all five).

A cell "infeasible >240s (died in bound N)" means the 240s timeout fired
while the run was inside size bound N; the "cum" numbers are the totals
over the *completed* levels only.  That is data, not failure: the config
cannot solve the task in 4 minutes on this machine.  Two distinct failure
modes show up and the notes column distinguishes them:

- **main-side blowup** — huge unify(main); the main enumerator drowns.
- **follower-side blowup** — tiny unify(main), huge unify(follower); the
  follower itself diverges (this is what happens when EX runs in a
  follower without the structural view that keeps its evaluator finite).

`unify(f)` = unify(follower).  `depth-cut` = total unsound main-depth
cutoffs fired (0 in every full-stack run: the sound answer needs none).
Every arm that found an answer found the *same canonical body* at the same
bound (rember 47, append 35, duplicate 39).

## rember  (bounds 15..51, answer at 47; 4 examples)

| config | unify(main) | conde(main) | answer? | wall | notes |
|--------|------------:|------------:|---------|-----:|-------|
| none    | 16,720,915* | 1,305,121* | no — infeasible >240s (died in bound 31) | >240s | main-side blowup; depth-cut 1268 |
| solo-R1 | 4,420,117*  | 354,420*   | no — infeasible >240s (died in bound 39) | >240s | got furthest of the failing solos |
| solo-R2 | **935,621** | 38,599     | yes, bound 47 | 11.6s | only solo that solves rember; unify(f) 9.0M |
| solo-TY | 26,259,624* | 2,233,838* | no — infeasible >240s (died in bound 35) | >240s | main-side blowup |
| solo-NV | 4,500,581*  | 348,416*   | no — infeasible >240s (died in bound 27) | >240s | main+follower blowup (unify(f) 37M) |
| solo-EX | —           | —          | no — infeasible >240s (died in bound 15, no level completed) | >240s | follower evalo/d diverges immediately without structural views |
| LOO-R1  | 289,044*    | 449*       | no — infeasible >240s (died in bound 27) | >240s | follower-side blowup: unify(f) 1.91 **billion** |
| LOO-R2  | 15,706*     | 409*       | no — infeasible >240s (died in bound 31) | >240s | follower-side blowup |
| LOO-TY  | **303,312** | 7,899      | yes, bound 47 | 11.4s | ≈ full (even slightly below); TY fully overlapped |
| LOO-NV  | 761,500     | 11,049     | yes, bound 47 | 134.1s | 2.4x unify vs full; unify(f) 962M — EX re-refutes the vacuous family one candidate at a time |
| LOO-EX  | 435,979     | 21,628     | yes, bound 47 | 8.4s | reused: claude/2026-07-12-203000 (= rember-full-id-tv4.scm) |
| full    | **312,236** | 7,899      | yes, bound 47 | 10.4s | re-run this session; reproduces claude/2026-07-12-204500 exactly |

\* cumulative over completed levels only (run killed at 240s).

## append  (bounds 11..39, answer at 35; 2 examples)

| config | unify(main) | conde(main) | answer? | wall | notes |
|--------|------------:|------------:|---------|-----:|-------|
| none    | 19,608,505* | 1,528,771* | no — infeasible >240s (died in bound 27) | >240s | main-side blowup; depth-cut 1584 |
| solo-R1 | 330,552     | 17,753     | yes, bound 35 | 6.2s | solo feasible; depth-cut 11 |
| solo-R2 | 1,936,131   | 32,978     | yes, bound 35 | 28.1s | feasible but 14x full; unify(f) 31.6M |
| solo-TY | 25,127,777* | 2,141,826* | no — infeasible >240s (died in bound 31) | >240s | main-side blowup |
| solo-NV | 4,329,381*  | 333,820*   | no — infeasible >240s (died in bound 23) | >240s | main+follower blowup |
| solo-EX | —           | —          | no — infeasible >240s (died in bound 11, no level completed) | >240s | follower evalo/d diverges immediately |
| LOO-R1  | —           | —          | no — infeasible >240s (died in bound 11, no level completed) | >240s | follower-side blowup, instant |
| LOO-R2  | 25,224*     | 721*       | no — infeasible >240s (died in bound 31) | >240s | follower-side blowup |
| LOO-TY  | **135,968** | 3,272      | yes, bound 35 | 4.0s | ≈ full; TY fully overlapped |
| LOO-NV  | 138,264     | 3,285      | yes, bound 35 | 3.9s | ≈ full; NV fully overlapped on append |
| LOO-EX  | 155,168     | 5,258      | yes, bound 35 | **1.6s** | 1.12x unify vs full but 2.5x FASTER wall (unify(f) drops 8.5M -> 1.8M) |
| full    | **138,493** | 3,272      | yes, bound 35 | 4.1s | depth-cut 0 |

## duplicate  (bounds 11..47, answer at 39; 3 examples, 1 parameter)

| config | unify(main) | conde(main) | answer? | wall | notes |
|--------|------------:|------------:|---------|-----:|-------|
| none    | 3,331,279* | 273,686* | no — infeasible >240s (died in bound 31) | >240s | main-side blowup; depth-cut 268 |
| solo-R1 | 305,787    | 22,014   | yes, bound 39 | 1.4s | depth-cut 16 |
| solo-R2 | **78,066** | 3,274    | yes, bound 39 | 0.4s | strongest solo on any task: 1.45x of full, alone |
| solo-TY | 7,719,163  | 645,522  | yes, bound 39 | 13.9s | feasible but 143x full; depth-cut 633 |
| solo-NV | 6,480,865* | 530,830* | no — infeasible >240s (died in bound 35) | >240s | main+follower blowup (unify(f) 63M) |
| solo-EX | —          | —        | no — infeasible >240s (died in bound 11, no level completed) | >240s | follower evalo/d diverges immediately |
| LOO-R1  | 63,010     | 1,921    | yes, bound 39 | 1.9s | feasible here (unlike rember/append): 1-param space keeps follower-EX small; unify(f) 5.2M |
| LOO-R2  | 9,563*     | 330*     | no — infeasible >240s (died in bound 31) | >240s | follower-side blowup |
| LOO-TY  | **52,497** | 1,753    | yes, bound 39 | 0.6s | ≈ full; TY fully overlapped |
| LOO-NV  | 56,276     | 1,817    | yes, bound 39 | 0.7s | ≈ full; NV fully overlapped on duplicate |
| LOO-EX  | 63,284     | 2,966    | yes, bound 39 | **0.5s** | 1.18x unify vs full, faster wall (unify(f) 1.3M -> 0.3M) |
| full    | **53,812** | 1,753    | yes, bound 39 | 0.8s | depth-cut 0 |

## Findings

R2 (decreasing recursion) is the load-bearing limiter on every task: it is
the only limiter whose solo run solves rember at all, its solo on duplicate
is within 1.5x of the full stack, and *every* LOO-R2 run is infeasible —
not because the main search blows up but because the follower does: without
the descent check, the in-follower `evalo/d` chases non-decreasing
recursions and the follower itself diverges (unify(main) stays tiny while
wall time burns).  R1 has the same character wherever the candidate space
is large enough (LOO-R1 infeasible on rember at 1.9B follower unifies, and
instantly on append; only 1-parameter duplicate survives its removal), so
the two termination rungs are not merely pruners — they are what keeps a
follower containing EX *finite*.  TY, by contrast, is fully overlapped:
LOO-TY matches or slightly beats full on all three tasks (303,312 vs
312,236 on rember), even though its solo runs are the worst measured, so
every ill-typed candidate is independently killed by R2/NV/EX and the type
view currently pays no rent in this stack.  NV is task-specific: on rember
its removal costs 2.4x unify(main) and 13x wall (the vacuous-`if` family is
~33% of rember's stream, and EX must re-refute it candidate-by-candidate,
962M follower unifies), while on append and duplicate LOO-NV is
indistinguishable from full because those answers' streams barely contain
the family.  EX is never standalone-viable (all solo-EX runs die inside the
first size bound) and its marginal value is split: it buys 1.40x
unify(main) on rember but only ~1.1-1.2x on append/duplicate, and on the
two easy tasks dropping it actually *improves* wall time 1.6-2.5x by
cutting follower work 4-8x — consistent with the notebook's finding that
examples earn their keep only once the structural views have concentrated
the stream (claude/2026-07-12-204500).  Finally, the anchors: no task is
feasible in 240s without a follower, every full-stack run fires zero
unsound depth cutoffs, and every feasible arm finds the identical canonical
answer at the identical bound, so all ratios above compare equal work.

## Regeneration

1. Generate the 36 driver files (12 configs x 3 tasks):

   ```
   python3 experiments/ablation-gen.py /tmp/ablation-drivers
   ```

   Each driver is the `rember-full-id-tv4.scm` pattern with the follower's
   `fresh/d` body restricted to the config's limiter subset (`none` omits
   the `follower` goal entirely; EX puts the task's examples inside the
   follower as `evalo/d` goals).  Bounds: rember `(15 19 23 27 31 35 39 43
   47 51)`, append `(11 15 19 23 27 31 35 39)`, duplicate `(11 15 19 23 27
   31 35 39 43 47)`; `main-unsound-depth` 1000 everywhere.

2. Run each (from the repo root; they are independent, parallelize freely —
   4 at a time fits comfortably in 15GB):

   ```
   ./run.sh --check-follower-every 1 --timeout 240 /tmp/ablation-drivers/TASK-CONFIG.scm
   ```

3. Read results off the `[LEVEL ...]`/`[TOTAL ...]` lines (the id-harness
   summary): `[TOTAL ... unify-main=U conde-main=C ... time-ms=T answer=A]`
   is the row; a run killed by the timeout has no `[TOTAL]` line — sum the
   completed `[LEVEL]` lines and record which bound it died in.
