(load "load.scm")
(load "restricted-interp.scm")
(load "restricted-interp-following.scm")
(load "restricted-interp-untyped.scm")
(load "restricted-interp-untyped-following.scm")

(load "tests/determinacy-goal-forms.scm")
(load "tests/guard-robustness.scm")
(load "tests/following-interpreter.scm")
(load "tests/refutation.scm")
(load "tests/leading-following.scm")
(load "tests/untyped-interp.scm")
(load "tests/view-tallies.scm") ; depends on views.scm (loaded by untyped-interp)
(load "tests/conde-d-registry.scm") ; step-1 first-order-rep registry gates

(test-summary)
(when test-failed
  (exit 1))
