# RESUME_PROMPT.md

Paste the text below into a new Cursor Agent chat whenever work was interrupted, a session ended, or you are unsure where things stand.

---
You are continuing development of *Severed: Trials of Olympus* (Godot 4, Blender-Python generated art, deterministic fixed-tick combat simulation, local 1v1 MVP only).

1. Read `PROJECT_STATUS.md` fully, then `docs/DECISIONS.md`, then the most recent file in `docs/handoff/`.
2. If `tools/status/status_check.py` exists, run it and fix any tracker inconsistencies truthfully (do not mark anything complete without evidence).
3. Run `git status` and `git log --oneline -10`. Check for uncommitted partial work; do not discard it without inspecting it.
4. Run `tools/run_tests.sh` (or `.ps1`) if it exists and report the real result.
5. Find the stage marked IN_PROGRESS, PARTIAL or BLOCKED; if none, take *Next Prompt Filename*. Open `Severed_Cursor_Prompt_Pack/<that file>` and follow it exactly from its Workspace inspection section, resuming rather than redoing finished tasks.
6. Never skip a stage or begin a stage whose prerequisites are not COMPLETE. Never claim success without running the check. Stop at any human checkpoint and tell me what to do from `Severed_Cursor_Prompt_Pack/MANUAL_CHECKPOINTS.md`.
7. Begin by summarising in 5 lines: current stage, last verified test result, uncommitted changes, what you will do next.
---
