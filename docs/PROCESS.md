# Process

## Stage loop

1. Read `PROJECT_STATUS.md`, `docs/DECISIONS.md`, and the prompt named under Next Prompt Filename.
2. Inspect the files that prompt lists before editing them.
3. Do that stage's work. Do not start the following stage in the same pass.
4. Run `tools/check_all.ps1` on Windows, or `tools/check_all.sh` where bash is the shell. Report the real exit code.
5. Write `docs/handoff/<prompt filename>.md` from `docs/handoff/_TEMPLATE.md`.
6. Update the tracker with `tools/status/update_status.py`: `set-stage`, `log`, `record-tests`, `next`, and `index`.
7. Run `python tools/status/status_check.py`. It must pass before the stage is called COMPLETE.
8. Commit the stage. Leave the next prompt for the next session.

## Resume after an interruption

Paste `RESUME_PROMPT.md` into a new chat. That prompt tells the session to read `PROJECT_STATUS.md`, run `tools/status/status_check.py`, read the last handoff, and resume the stage marked IN_PROGRESS, PARTIAL, or BLOCKED. If none of those is set, start the file named under Next Prompt Filename. Do not skip a stage whose required stage is not COMPLETE.

## When a checkpoint fails

The owner fills in the bug-report template in `Severed_Cursor_Prompt_Pack/MANUAL_CHECKPOINTS.md`:

```
Checkpoint: A/B/C/D   Item #:
What I did (steps):
What I expected:
What happened instead:
How often (always / sometimes / once):
Fighter(s) / arena / mode / difficulty:
Limb state or regrown limb involved (if any):
Screenshot or short clip: (attach) / Log file: (path shown in Credits or `user://logs`)
My computer: OS, CPU, GPU, RAM:
```

Cursor writes `docs/handoff/fix_<checkpoint>_<n>.md` from that report and from `docs/handoff/_TEMPLATE.md`, then executes only that fix. `<checkpoint>` is A, B, C, or D. `<n>` is the item number. After the fix, rerun the tests and ask the owner to retest. Do not start the next numbered prompt while a reported checkpoint item is still failing.

## Critical criteria

A stage is not marked COMPLETE, and Next Prompt Filename is not moved past it, while one of its critical acceptance criteria is unmet. A failing test, a missing handoff, or an open checkpoint item that the stage itself requires is a critical criterion. UNVERIFIED items stay written as UNVERIFIED.
