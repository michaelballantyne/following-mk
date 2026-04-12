(load "load.scm")
(load "restricted-interp.scm")
(load "restricted-interp-following.scm")

(load "tests/determinacy-goal-forms.scm")
(load "tests/following-interpreter.scm")
(load "tests/finite-refutation.scm")
(load "tests/leading-following.scm")

(test-summary)
(when test-failed
  (exit 1))
