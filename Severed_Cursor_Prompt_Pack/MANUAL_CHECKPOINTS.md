# MANUAL_CHECKPOINTS.md - the only things you must do personally

Everything else is automated by Cursor. Each item says what, why automation cannot do it, how long, and what to send back.

## Bug-report template (copy for any failed checkpoint item)
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
Paste the filled report into Cursor with: "Create a targeted fix prompt docs/handoff/fix_<checkpoint>_<n>.md from this report, then execute it, rerun the tests, and tell me when to retest."

## Pre-flight (one time, ~30-60 minutes)
| Task | Why you must do it | Time | Evidence to return |
|---|---|---|---|
| Install **Git**, **Python 3**, **Godot 4 (latest stable)**, **Blender (LTS 4.2 or newer)**, and **Cursor** (you already have Pro) from their official sites | Installers need your permission and system access | 20-40 min | Tell Cursor "installed"; it verifies versions itself |
| Create an empty project folder, open it in Cursor, copy the whole `Severed_Cursor_Prompt_Pack/` folder into its root | Cursor cannot see files on your machine until you do | 5 min | - |
| Copy the two source PDFs into the project folder (optional; text versions are already in the pack) | Same | 1 min | - |
| In Cursor settings allow the Agent to run terminal commands for this project (ask-before-run is fine for installs; allowlisting `git`, `godot`, `blender`, `python3`, and the repo scripts saves many clicks) | Security permission only you can grant | 5 min | - |
| **Approve or override D-003 (2.5D lane combat)** and D-009 (the five limbs) in `DECISIONS.md` | Consequential design choices | 5 min | Reply "approved" or the change you want |

## Checkpoint A - after prompt 05 (~10-15 min)
Launch the first playable (instructions in `docs/playtest/CHECKPOINT_A.md`).
1. The game starts without errors and shows two fighters, health bars, timer.
2. Move both fighters (P1: A/D, P2: arrow keys, or gamepads); turn to face each other automatically.
3. Perform light, heavy and kick attacks; see hits reduce health; press F1 to see hitboxes.
4. Finish a best-of-three match; press R to restart.
5. Judge (honestly): do controls respond immediately? Is it readable what is happening?
**Return:** PASS, or a bug report. **Why manual:** only you can judge responsiveness and feel.

## Checkpoint B - after prompt 13 (~20-30 min)
Open `scenes/debug/regrow_lab.tscn` and the main match scene (see `docs/playtest/CHECKPOINT_B.md`).
1. Fight until a limb turns Bruised, then Cracked (hanging), then Severed with a combo of 3+ hits; confirm the stump appears and the limb flies off.
2. Confirm a single hit never severs a healthy limb; confirm at most 2 limbs per match.
3. Test one arm missing, both arms, one leg (hop), both legs (crawl), three limbs (torso mode): can you still move and attack?
4. Regrow each of the 5 limbs on **Theron and Pyrrhus** (tallest and smallest): no clipping or floating, readable silhouette, benefit and twist behave as the tooltip says.
5. Judge the look of the four fighters: distinct, readable at game distance, acceptable style? List what you dislike (Cursor will adjust generators).
**Return:** PASS or bug report plus a 'looks' list. **Why manual:** visual quality and feel cannot be proven by tests.

## Checkpoint C - after prompt 20 (~45-60 min)
Play the full MVP loop (`docs/playtest/CHECKPOINT_C.md`).
1. First launch: age gate and content warning appear; menus work with keyboard **and** gamepad.
2. Play at least one match with each of the 4 fighters and in each of the 3 arenas (hazards on); hazards are telegraphed and avoidable.
3. Career: create a fighter, win a match, pick an unlock, lose a limb, visit Obol, trade, play on; quit and Continue - state is intact.
4. Fresh Body, Local Versus (two controllers or one keyboard) and Practice all work.
5. Settings: change gore level, blood colour, shake, flash reduction, subtitles, text size, remap a key; they apply and persist after restart.
6. Listen for ~10 minutes: is the generated audio acceptable as a placeholder? Is anything too loud or grating?
7. Is it fun for several matches? Which fighter/ability feels too strong or weak? (Qualitative notes are valuable.)
**Return:** PASS or bug/balance notes. **Why manual:** fun, balance feel and audio taste are subjective.

## Legal and store items (after prompt 22B; your time varies, ~1-2 hours spread out)
Cursor prepares drafts in `docs/release/`. Only you can: choose the project licence, confirm the AI-disclosure answers are truthful, create store accounts (itch.io, optionally Steam), enter identity/tax/payout details if any platform requires them, submit content-rating questionnaires, and decide whether to obtain professional legal advice about ownership of AI-assisted/generated content. **Return:** confirmation of decisions (licence choice, disclosure answers confirmed). **Why manual:** identity, legal responsibility and truthfulness attestations cannot be delegated.

## Checkpoint D - after prompt 23 (~45-60 min)
Test the **packaged** release candidate, not the editor (`docs/playtest/CHECKPOINT_D.md`).
1. Unzip the build into a fresh folder on a computer (ideally one without Godot/Blender installed) and double-click the executable. Note any security warning (unsigned builds may show one - tell Cursor exactly what you saw).
2. First-launch flow, settings persistence after restart, full Career loop including save/quit/continue, a Fresh Body match, a Versus match.
3. Delete or corrupt nothing deliberately except as instructed: follow the 'corrupt save' mini-test in the checklist.
4. Report **FPS and smoothness** (use the in-game FPS toggle) and your PC specs.
5. Read the README, content warning and known-issues file: accurate?
**Return:** PASS or bug report plus performance note and PC specs. **Why manual:** only a real machine can show real-world launch problems and performance.

## Final approval - after prompt 24 (~15 min)
Read `docs/release/FINAL_ACCEPTANCE_REPORT.md` and `OWNER_SIGNOFF.md`. Decide go/no-go. Publishing/uploading is done by you. **Return:** "approved for release" or a list of blockers.
