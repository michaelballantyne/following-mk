# Rung 4a (non-vacuous conditions): the sample→refute loop closes its first cycle

`non-vacuous-testso/d` (`experiments/termination-view4.scm`, driver
`rember-full-id-tv4.scm`): at every `(if (= c1 c2) ...)` node, require
the two condition positions to be distinct *as program text*, via the
stall-friendly two-clause encoding (`==/d` on text → refute; `=/=/d` →
ok; holes keep both live → stall). A canonicity restriction: the
vacuous candidate is equivalent to its own then-branch, which
size-ordered search already enumerated smaller, so refusing it
preserves the minimal answer. For-all over if-nodes, plain
conjunction, no path/name machinery.

Gates all pass — including the acid test: the canonical rember answer
(whose `(= _.0 e)` condition must stall while `_.0` is fresh) is
found with **byte-identical reified constraints** to the three-view
arm; the `_.0 =/= e` the view wants was already implied by rungs
2/3's no-shadowing. The view adds nothing to the answer; it only
deletes doomed candidates.

## Measured (rember ID, ce1, four views vs three)

Total unify(main) **699,740 → 435,979 (1.61×)**; wall 14.9s → 8.4s;
per-level cuts 1.47–2.85×, largest exactly at bounds 35–43 where the
spot check measured the vacuous family at ~33% of the stream.
depth-cut 0 both arms. Notable dynamics: follower *fail* events went
DOWN (1,655 → 1,083) while pruning went up — earlier refutation at
smaller commitment prevents downstream candidates from ever being
generated, so all follower counters shrink together; pruning
cascades.

## The day's cumulative reduction curve on rember (work to answer)

| config | unify(main) |
|---|---:|
| ID, no views (morning) | unmeasurable (OOM/timeout) |
| ID + rung 1, ce20 | 57,610,123 |
| ID + rungs 1–2, ce20 | 2,615,131 |
| ID + rungs 1–3, ce1 | 699,740 |
| **ID + rungs 1–4a, ce1** | **435,979** |
| (fair-search baseline, reference) | 3,229,244 |

The enumerative regime now beats fair search by 7.4× on the hardest
task, with a sound search, minimal-answer guarantee, and zero unsound
cutoffs firing. Each rung was found by sampling the surviving stream
(Michael's suggestion), diagnosed by a subagent spot check, built as
a ~40-line composed /d view, and verified by prediction-first
measurement. Next family already identified: parameter-irrelevant
branches (rung 4b, needs a relevance-framing design pass) — the
post-4a re-sample is running as of this entry.
