(load "load.scm")
(load "restricted-interp.scm")
(load "restricted-interp-following.scm")
(load "restricted-interp-untyped.scm")
(load "restricted-interp-untyped-following.scm")
(load "residual-interp-untyped-following.scm") ; residual untyped /d interpreter (r-forms)

(load "tests/determinacy-goal-forms.scm")
(load "tests/guard-robustness.scm")
(load "tests/following-interpreter.scm")
(load "tests/refutation.scm")
(load "tests/leading-following.scm")
(load "tests/untyped-interp.scm")
(load "tests/view-tallies.scm") ; depends on views.scm (loaded by untyped-interp)
(load "tests/residual-engine.scm") ; residual engine vs closure engine (differential); also
                                   ; loads residual-views.scm (R1/R2/R2P/TY/NV r-form port)
(load "tests/residual-interp.scm") ; residual /d interpreter + refutation (differential);
                                   ; also loads residual-interp-following.scm
(load "tests/residual-decisions.scm") ; per-trigger decision-equivalence vs closure
(load "tests/residual-guards.scm") ; guard-robustness ported to residual + decision-equiv
(load "tests/residual-views.scm") ; R2/R2P/TY/NV differential tests; depends on
                                  ; residual-views.scm (loaded by residual-engine above)
(load "tests/residual-untyped-interp.scm") ; residual untyped /d interpreter, differential

(test-summary)
(when test-failed
  (exit 1))
