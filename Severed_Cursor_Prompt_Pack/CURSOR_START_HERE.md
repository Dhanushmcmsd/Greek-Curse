# START HERE — Use this pack with Cursor Pro

## One-time setup
1. Extract `Severed_Cursor_Prompt_Pack.zip`.
2. Create or open the **root folder for your game project** in Cursor. Do not open only the prompt-pack subfolder as if it were the game itself.
3. Copy the entire `Severed_Cursor_Prompt_Pack/` folder into the game project root. Keep it there and treat it as read-only.
4. Ensure the revised GDD and revised Build Requirements are available in the pack's `reference/` folder (they are included as text extracts). Keep the original revised DOCX/PDF files too if convenient.
5. Open a new Cursor Agent chat in the game project.

## First prompt to give Cursor
Open `Severed_Cursor_Prompt_Pack/00_README_AND_EXECUTION_GUIDE.md` with Cursor's `@` file picker, then send:

> Read and execute `Severed_Cursor_Prompt_Pack/00_README_AND_EXECUTION_GUIDE.md` exactly. Treat the prompt pack as read-only. Inspect the workspace before changing anything. Do not start stage 01 or write game code until stage 00 acceptance criteria are met. Run only commands you can verify, update `PROJECT_STATUS.md` truthfully, and write the required handoff report. If a required tool is missing, report the exact owner action rather than installing anything without approval.

## Continue after each stage
- Follow `PROMPT_INDEX.md` in numeric order, one stage per Cursor Agent chat.
- Before each stage, check `PROJECT_STATUS.md` and the previous handoff report.
- Only move forward when the previous stage is marked COMPLETE with evidence.
- Stop at owner checkpoints listed in `MANUAL_CHECKPOINTS.md`.
- If interrupted, use `RESUME_PROMPT.md`.

## Important
This is a **prompt pack for building a scoped local 1v1 MVP**, not an already-built game. Cursor must create the project and run the checks. The pack cannot guarantee a finished game without implementation, testing, and owner playtests.
