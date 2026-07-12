# Examples earn their keep once the structural views clean the stream

Michael asked earlier: once termination checking is in, do examples
become useful pruners? Measured answer: yes, in proportion to how
clean the stream is. At rung-1 stage, adding evalo/d to the ID
follower bought ~10% (append). Post-rung-4a, where the spot check
showed the residual stream dominated (~55-65%) by candidates that
never re-cons the surviving head — refutable ONLY by examples —
adding evalo/d to the four views takes rember from 435,979 to
312,236 unify(main) (1.40x) and 21,628 to 7,899 conde(main) (2.7x).
Same canonical answer, depth-cut 0, ce1.

Mechanism: each structural view deletes a family examples would have
paid for one candidate at a time; what remains is exactly the
example-refutable population, so the example view's marginal value
RISES as rungs accumulate. The views aren't competing with examples;
they're concentrating them.

Current best rember work-to-answer: 312k unify(main) — 10.3x below
the fair-search baseline (3.23M), from unmeasurable this morning.

Post-4a spot check residue (72-candidate sample) for the next rungs:
~55-65% no-cons-around-self-call (now largely example-killed, per
this experiment), ~11% branch-value vacuity `(if (= x e) x e)`
(canonicity family, cousin of 4a), ~5% type-confusion that stalls
rather than refutes, small unfillable-hole and decoupled-recursion
families. Genuinely viable: ~5-8% of the sampled stream.
