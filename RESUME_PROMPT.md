# RESUME_PROMPT.md

Paste the text below into a new Cursor Agent chat whenever work was interrupted, a session ended, or you are unsure where things stand.

---
You are continuing development of *Severed: Trials of Olympus* (Godot 4, Blender-Python generated art, deterministic fixed-tick combat simulation, local 1v1 MVP only).

1. Read `PROJECT_STATUS.md`, run `tools/status/status_check.py`, then read `docs/DECISIONS.md` and the newest numbered handoff in `docs/handoff/` (`INDEX.md` and `_TEMPLATE.md` are not stage results).
2. Fix any tracker inconsistencies truthfully. Do not mark anything complete without evidence.
3. Run `git status` and `git log --oneline -10`. Check for uncommitted partial work; do not discard it without inspecting it.
4. Run `tools/run_tests.sh` (or `.ps1`) if it exists and report the real result.
5. Resume the stage marked IN_PROGRESS, PARTIAL, or BLOCKED. If none is set, start the *Next Prompt Filename*. Open `Severed_Cursor_Prompt_Pack/<that file>` and follow it from its Workspace inspection section.
6. Never skip a stage or begin a stage whose prerequisites are not COMPLETE. Never claim success without running the check. Stop at any human checkpoint and tell me what to do from `Severed_Cursor_Prompt_Pack/MANUAL_CHECKPOINTS.md`.
7. Begin by summarising in 5 lines: current stage, last verified test result, uncommitted changes, what you will do next.
---
