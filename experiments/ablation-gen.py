#!/usr/bin/env python3
"""Generate ablation driver .scm files, one per (task, config).

Limiters: R1 base-case-patho/d, R2 decreasing-recursiono/d, TY type-ofo/d,
NV non-vacuous-testso/d, EX evalo/d over the task's I/O examples (in the
follower, in ADDITION to the always-present top-level evalo examples).

Configs per task: none, solo-R1..solo-EX (5), loo-R1..loo-EX (5), full.

Usage: python3 experiments/ablation-gen.py [OUTDIR]
(default OUTDIR: /tmp/ablation-drivers).  Run each generated file with
  ./run.sh --check-follower-every 1 --timeout 240 OUTDIR/TASK-CONFIG.scm
from the repo root.  See experiments/ablation.md.
"""
import os, sys

OUTDIR = sys.argv[1] if len(sys.argv) > 1 else "/tmp/ablation-drivers"
os.makedirs(OUTDIR, exist_ok=True)
LIMITERS = ["R1", "R2", "TY", "NV", "EX"]

TASKS = {
    "rember": {
        "fname": "rember",
        "params": "(e l)",
        "bounds": "(15 19 23 27 31 35 39 43 47 51)",
        "absentos": [3, 4, 5, 6, 7],
        "prog": """(define (rember-prog q body)
  `(letrec ([rember (lambda (e l) : ((number list) -> list)
                      ,q)])
     ,body))""",
        "tyenv": "'((rember . ((number list) -> list)) (e . number) (l . list))",
        "r1_call": "(base-case-patho/d 'rember q)",
        "r2_call": "(decreasing-recursiono/d 'rember '(e l) q)",
        "ty_call": "(type-ofo/d rember-tyenv q 'list)",
        "nv_call": "(non-vacuous-testso/d q)",
        "examples": [
            ("(rember-prog q '(rember 5 '()))", "'()"),
            ("(rember-prog q '(rember 6 (cons 6 '())))", "'()"),
            ("(rember-prog q '(rember 7 (cons 3 (cons 4 (cons 7 (cons 6 '()))))))", "'(3 4 6)"),
            ("(rember-prog q '(rember 5 (cons 3 (cons 4 (cons 6 (cons 7 '()))))))", "'(3 4 6 7)"),
        ],
        "load": 'views.scm',
    },
    "append": {
        "fname": "append",
        "params": "(l s)",
        "bounds": "(11 15 19 23 27 31 35 39)",
        "absentos": [3, 4, 5, 6, 7],
        "prog": """(define (append-prog q body)
  `(letrec ([append (lambda (l s) : ((list list) -> list)
                      ,q)])
     ,body))""",
        "tyenv": "'((append . ((list list) -> list)) (l . list) (s . list))",
        "r1_call": "(base-case-patho/d 'append q)",
        "r2_call": "(decreasing-recursiono/d 'append '(l s) q)",
        "ty_call": "(type-ofo/d append-tyenv q 'list)",
        "nv_call": "(non-vacuous-testso/d q)",
        "examples": [
            ("(append-prog q '(append '() (cons 5 (cons 6 '()))))", "'(5 6)"),
            ("(append-prog q '(append (cons 3 (cons 4 (cons 5 '()))) (cons 6 (cons 7 '()))))", "'(3 4 5 6 7)"),
        ],
        "load": 'views.scm',
    },
    "duplicate": {
        "fname": "duplicate",
        "params": "(l)",
        "bounds": "(11 15 19 23 27 31 35 39 43 47)",
        "absentos": [3, 4, 5],
        "prog": """(define (duplicate-prog q body)
  `(letrec ([duplicate (lambda (l) : ((list) -> list)
                          ,q)])
     ,body))""",
        "tyenv": "'((duplicate . ((list) -> list)) (l . list))",
        "r1_call": "(base-case-patho/d 'duplicate q)",
        "r2_call": "(decreasing-recursiono/d 'duplicate '(l) q)",
        "ty_call": "(type-ofo/d duplicate-tyenv q 'list)",
        "nv_call": "(non-vacuous-testso/d q)",
        "examples": [
            ("(duplicate-prog q '(duplicate '()))", "'()"),
            ("(duplicate-prog q '(duplicate (cons 5 '())))", "'(5 5)"),
            ("(duplicate-prog q '(duplicate (cons 3 (cons 4 '()))))", "'(3 3 4 4)"),
        ],
        "load": 'views.scm',
    },
}


def ex_goal_lines(task, top_level):
    lines = []
    for call, result in task["examples"]:
        if top_level:
            lines.append(f"      (evalo {call} {result})")
        else:
            lines.append(f"          (evalo/d {call} {result})")
    return "\n".join(lines)


def follower_goals(task, active):
    """active: subset of LIMITERS to include in the follower.  Returns the
    follower's inner goal list (a fresh/d body), or None if active is empty."""
    parts = []
    for lim in active:
        if lim == "R1":
            parts.append("          " + task["r1_call"])
        elif lim == "R2":
            parts.append("          " + task["r2_call"])
        elif lim == "TY":
            parts.append("          " + task["ty_call"])
        elif lim == "NV":
            parts.append("          " + task["nv_call"])
        elif lim == "EX":
            parts.append(ex_goal_lines(task, top_level=False))
    return "\n".join(parts)


def gen_file(task_name, config_name, active, note):
    task = TASKS[task_name]
    tyenv_defs = ""
    if "TY" in active:
        tyenv_defs = f'\n(define {task_name}-tyenv {task["tyenv"]})\n'

    if active:
        goals = follower_goals(task, active)
        follower_block = f"""      (follower
        q
        (fresh/d ()
{goals}))
"""
    else:
        follower_block = ""

    absentos = "\n".join(f"      (absento {a} q)" for a in task["absentos"])
    top_examples = ex_goal_lines(task, top_level=True)

    body = f""";; ablation/{task_name}-{config_name}.scm --- AUTO-GENERATED ablation driver.
;; {note}
;; Protocol: size-closed ID, --check-follower-every 1, main-unsound-depth 1000
;; (set by id-harness), --timeout 240.  See experiments/ablation.md.
;;
;;   ./run.sh --check-follower-every 1 --timeout 240 \\
;;     {os.path.join('ablation', task_name + '-' + config_name + '.scm')}
;; (run from repo root with this file's directory on the load path, or copy
;; into experiments/ -- see experiments/ablation.md regeneration instructions)

(load "experiments/id-harness.scm")
(load "{task['load']}") ; brings base-case-patho/d, decreasing-recursiono/d,
                                            ; type-ofo/d, non-vacuous-testso/d (rungs 1-4a)
{tyenv_defs}
{task['prog']}

(run-id "{task_name}/{config_name}" '{task['bounds']} 1000
  (lambda (bound)
    (run 1 (q)
      (watch-size q)
{absentos}
{follower_block}{top_examples})))
"""
    fname = os.path.join(OUTDIR, f"{task_name}-{config_name}.scm")
    with open(fname, "w") as f:
        f.write(body)
    return fname


def main():
    generated = []
    for task_name in TASKS:
        # none
        generated.append(gen_file(task_name, "none", [], "config: none (no follower; ID baseline)."))
        # solo
        for lim in LIMITERS:
            generated.append(gen_file(task_name, f"solo-{lim}", [lim],
                                       f"config: solo {lim} (only {lim} in the follower)."))
        # loo
        for lim in LIMITERS:
            active = [l for l in LIMITERS if l != lim]
            generated.append(gen_file(task_name, f"loo-{lim}", active,
                                       f"config: leave-one-out minus {lim} (full stack minus {lim})."))
        # full
        generated.append(gen_file(task_name, "full", LIMITERS, "config: full (all five limiters)."))
    print(f"generated {len(generated)} files")
    for g in generated:
        print(g)


if __name__ == "__main__":
    main()
