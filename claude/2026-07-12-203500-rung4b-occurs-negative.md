# Rung 4b (occurs/relevance view): correct, and does not pay rent

`occurso/d` (`experiments/termination-view5.scm`, driver
`rember-full-id-tv5.scm`): pure textual-occurrence walk requiring the
parameter symbol to appear in the body; stalls on holes; a
num-constrained hole refutes free (cannot unify with a symbol or a
pair) — the designed behavior, all five gates pass.

Measured against the full installed stack (tv4ex, same-session
baseline reproduced exactly): unify(main) 312,236 → 307,333 (−1.6%),
follower cost +22%. **Negative result, recorded as such.** The
pre-4a spot check's "20–25% e-irrelevant" measured the RAW stream;
by the time rungs 1–4a and the examples have run, that family is
already almost entirely dead, and a whole-term walk per ce1 tick
buys ~nothing at real cost.

Methodological rule this hardens (same lesson as the TY ablation
row): **a spot-check family size is an upper bound on a new view's
value; the true marginal value is against the installed stack, and
only the ablation protocol measures it.** Future rung proposals
should estimate overlap with installed views before building — or
just build cheap and ablate, as here (the whole cycle cost under an
hour).

Files committed for the record and for the untyped-interpreter
scenario, where relevance may matter more (same reasoning as the TY
flip hypothesis); not part of the default stack. Current best config
remains tv4ex: 312,236 unify(main).
