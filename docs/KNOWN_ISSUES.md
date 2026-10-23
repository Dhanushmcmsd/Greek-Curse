# Known issues

| ID | Status | Notes |
|---|---|---|
| B-003 | CLOSED | Godot 4.7.2 export templates are in `%APPDATA%\Godot\export_templates\4.7.2.stable`. `version.txt` is `4.7.2.stable`. A throwaway project outside the repo exported. The game export is still stage 23. |
| B-004 | CLOSED | `gdtoolkit` 4.5.0 is installed. `gdlint src tests` and `gdformat --check src tests` exited 0 on 2026-10-24. |
| B-005 | CLOSED | Git Bash ran `tools/check_all.sh`, which ran `tools/run_tests.sh`. Exit 0. |
| — | NOTE | Godot 4.0 remains at `D:\Godot_v4.0-stable_win64.exe`. Launchers refuse that path. The pin is the 4.7.2 console executable. |
| — | UNVERIFIED | Windowed Godot, screenshots, and a Blender render have not been run. |
