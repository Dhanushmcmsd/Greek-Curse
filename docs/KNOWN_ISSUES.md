# Known issues

| ID | Status | Notes |
|---|---|---|
| B-003 | OPEN | Godot 4.7.2 export templates are not installed. Blocks stage 23, not the local headless suite. |
| B-004 | OPEN | `gdtoolkit` (`gdformat` / `gdlint`) is not installed. `pip show gdtoolkit` failed. Stage 02 does not install it. Script checks use Godot `--check-only` and `--import`. |
| B-005 | OPEN | `tools/run_tests.sh` and `tools/check_all.sh` have not been executed. This machine runs the PowerShell launchers. |
| — | NOTE | Godot 4.0 remains at `D:\Godot_v4.0-stable_win64.exe`. Launchers refuse that path. The pin is the 4.7.2 console executable. |
| — | UNVERIFIED | Windowed Godot, screenshots, and a Blender render have not been run. |
