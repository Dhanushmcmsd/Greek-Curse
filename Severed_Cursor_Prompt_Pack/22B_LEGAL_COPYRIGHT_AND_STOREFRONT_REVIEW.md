# Stage 22B: Legal Copyright And Storefront Review

## 0. Standing rules
- Treat the revised GDD, revised Build Requirements, `docs/DECISIONS.md`, and `PROJECT_STATUS.md` as source of truth. The locked MVP and decisions override older full-game scope.
- Inspect before editing; preserve existing user work; avoid unrelated rewrites.
- Implement, run checks, fix failures, verify acceptance criteria, update the tracker, and write a handoff report.
- Do not claim a test/build/tool ran unless you actually executed it. Mark anything impossible to verify as UNVERIFIED with a reason.
- Keep `Severed_Cursor_Prompt_Pack/` read-only. Never silently weaken/delete tests to get green.
- Ask the owner only for consequential decisions or tasks that cannot be automated safely.

## 1. Role
Release compliance analyst (not a lawyer). You prepare evidence and checklists; you never claim legal certainty.

## 2. Context
Stage 22 COMPLETE. The game content is final for the MVP. `docs/ASSET_LEDGER.md` has been maintained since stage 02.

## 3. Objective
Produce the legal, licensing, content-rating, privacy and storefront-disclosure documentation and checks required before release, separating *verified current requirements* from *assumptions*, and prepare drafts for the owner to review and submit.

## 4. Prerequisites
1. Stage 22 COMPLETE.

## 5. Workspace inspection
1. `docs/ASSET_LEDGER.md`, `assets/**`, `tools/**` (scripts that generate assets), `data/ui/credits.json`, all dependencies (Godot version/licence, Blender, Python libs used, fonts).
2. GDD sections 15-16 and Production Addendum E; Build Requirements 'Quality gates and compliance'.

## 6. Implementation tasks
1. Ledger audit: write `tools/validate/check_ledger.py` verifying every asset file/class has: author/tool, creation method, source script/files, date, licence/terms, edits. Fix gaps. Every audio file, font, icon set, generated model class, script dependency and engine/tool is covered.
2. Third-party licence compilation: gather the licence texts for Godot (MIT plus bundled third-party components - use the licence information provided by the engine's own `--version`/Licenses facility or the official repository `COPYRIGHT.txt`/`LICENSE.txt` for the pinned version), any font under OFL (include the OFL text and font copyright line), Blender (record that it is GPL software, that script and exported outputs are the project's own, and flag for review), and any Python package actually distributed (none expected). Produce `THIRD_PARTY_LICENSES.md` shipped in the build. If web access is unavailable, fetch from local installs and mark online verification UNVERIFIED.
3. **Live research of current official rules (if you have web access):** for Steam and itch.io fetch and read the current official documentation on (a) AI-generated/AI-assisted content disclosure, (b) content/maturity ratings and adult/violent content requirements, (c) refund/pricing for free games, (d) any age-gating requirements. Record in `docs/release/PLATFORM_REQUIREMENTS.md` a table: requirement | source URL | date retrieved | verified / assumption / could-not-verify. Never state a policy you did not read. If you have no web access, produce the same table with every row marked `COULD NOT VERIFY - owner or later session must check <official URL>` and do not guess.
4. AI-assisted-content disclosure review: write `docs/release/AI_DISCLOSURE_REVIEW.md` listing exactly where AI assisted (code, tests, documentation, debugging, prompt-pack planning; **no** generative image/3D/audio/voice assets used in shipped content, **verify this claim against the ledger** and report any exception), what the generated-by-script assets are, and a draft answer set for each platform's disclosure form that the **owner must confirm** is truthful.
5. Copyright/ownership notes: `docs/release/COPYRIGHT_NOTES.md`: script-generated assets and AI-assisted code may have uncertain or limited copyright protection depending on jurisdiction (do not assert a conclusion); recommendation to obtain professional advice if enforcement, modding licences or commercial use matter; project licence choice options for code and for assets with pros/cons (owner decides; do not pick a licence without approval - leave `LICENSE` as a draft with placeholders and mark pending); modding terms deferred (no modding support in MVP).
6. Mythology/trademark sanity check: the game uses public-domain Greek mythology names (Zeus, Obol, etc.); list any names or elements that could collide with trademarks (e.g. check that the working title is not obviously conflicting - perform a basic web search if possible and flag for owner review; this is not a clearance).
7. Content warning and rating prep: `docs/release/CONTENT_WARNING.md` (text for store page and in-game consistent with age gate), list of content descriptors (extreme stylised violence, dismemberment, blood, gore slider, no sexual content, no real-money gambling/purchases, no online interaction, no user-generated content), and a worked draft of answers for the questionnaires that the owner must submit (IARC via platforms where applicable - verify in research task). Do not claim an official rating.
8. Privacy/data: grep-based verification (`tools/validate/check_no_network.py`) that the shipped code contains no network classes (`HTTPRequest`, `ENet*`, `WebSocket*`, `UDP*`, `TCP*`, `StreamPeer*` for network, `OS.shell_open`) and no analytics; write `docs/release/PRIVACY_NOTE.md` stating the local-only data (settings, saves, logs under the user data directory), no data collected or transmitted, and what must change if online features are added later (privacy policy, data minimisation, children's data issues, regional laws) without giving legal conclusions.
9. Store page drafts for itch.io and (optionally) Steam: `docs/release/STORE_PAGE_DRAFT_ITCH.md`, `STORE_PAGE_DRAFT_STEAM.md` (short/long description, feature list strictly limited to what is implemented and verified, system requirements assumptions tied to `docs/PERFORMANCE.md`, content warning, screenshot shot-list, tags, price Free, no-IAP statement). No claims about online play, 4-player, or 10 fighters.
10. Owner-only items list (identity, store accounts, tax/payout details if any, final disclosure answers, legal advice decision) written into `docs/release/OWNER_ONLY_ITEMS.md` and mirrored into `PROJECT_STATUS.md`.
11. Commit; hand off.

## 7. Technical constraints
1. You are not a lawyer: never claim legal certainty; mark assumptions as assumptions.
2. Do not create store accounts, submit forms, or enter personal/identity information.
3. Do not add paid services or monetisation.
4. Do not copy long passages of platform policies; summarise and link.

## 8. Files and outputs
1. `THIRD_PARTY_LICENSES.md`, `LICENSE` (draft, pending owner)
2. `docs/release/{PLATFORM_REQUIREMENTS,AI_DISCLOSURE_REVIEW,COPYRIGHT_NOTES,CONTENT_WARNING,PRIVACY_NOTE,OWNER_ONLY_ITEMS}.md`, store page drafts
3. `tools/validate/{check_ledger.py,check_no_network.py}` + tests
4. Ledger completed

## 9. Automated tests
1. Ledger checker fixtures (missing field fails, complete passes).
2. Network checker fixtures (forbidden token fails, clean passes) and a run on the real codebase.
3. Credits data regeneration matches ledger.

## 10. Execution and verification
1. `python3 tools/validate/check_ledger.py` and `check_no_network.py` pass on the real project.
2. Show the `PLATFORM_REQUIREMENTS.md` table with the verified/unverified markings and dates.
3. `tools/check_all.sh` exits 0.

## 11. Acceptance criteria
1. Every shipped asset and dependency has a ledger row and a licence compatible with free distribution (or the issue is flagged to the owner).
2. Platform requirements are recorded with source and date, or explicitly marked unverified.
3. AI disclosure draft is accurate against the ledger and flagged for owner confirmation.
4. No network code present; privacy note accurate.
5. Owner-only items clearly listed.

## 12. Failure handling
If any command, test, import, build, export, or acceptance criterion fails: stop the stage from being marked COMPLETE; capture the exact error and relevant logs; diagnose the smallest root cause; apply the smallest safe fix; add a regression test where applicable; rerun the failed check and relevant suite. If blocked by missing tools or permissions, document exact owner action and mark BLOCKED rather than guessing.

## 13. Handoff report
Write `docs/handoff/22B_LEGAL_COPYRIGHT_AND_STOREFRONT_REVIEW.md` including: stage result; changed files; actual commands run; test results; acceptance criteria PASS/FAIL/UNVERIFIED with evidence; known bugs/blockers; decisions made; owner action if any; and **Next prompt to execute** with the exact filename. Update `PROJECT_STATUS.md` truthfully.

## 14. Scope guard
1. No legal advice or certainty, no policy invention, no account/form submission, no licence selection without owner approval, no new features.
2. Do not implement deferred features: online/rollback/matchmaking/ranked, four-player brawl, co-op, spectator, additional roster/arenas/abilities/limbs beyond locked MVP, Death Match, Thunder Strike cinematic, Last Stand, Execution, Legacy, Hall of the Fallen, cosmetic unlocks, Chronicle share card, voice acting, one-handed layouts, modding, monetisation, or paid services. Keep the game free.

**Next prompt to execute:** determine from `PROMPT_INDEX.md` and `PROJECT_STATUS.md`; do not skip prerequisites.
