(load "load.scm")
(load "restricted-interp.scm")
(load "restricted-interp-following.scm")       ; now the (only) residual impl
(load "restricted-interp-untyped.scm")
(load "restricted-interp-untyped-following.scm") ; now the (only) residual impl

(load "tests/determinacy-goal-forms.scm")
(load "tests/guard-robustness.scm")            ; + pruning case, + tally/g-tally case
(load "tests/following-interpreter.scm")
(load "tests/refutation.scm")
(load "tests/leading-following.scm")
(load "tests/untyped-interp.scm")              ; loads views.scm (now residual impl)
(load "tests/view-tallies.scm")
(load "tests/engine-shape.scm")                ; salvaged direct-settle tests

(test-summary)
(when test-failed (exit 1))
