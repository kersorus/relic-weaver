# Runtime boot hotfix

This patch changes the launch path from `main.tscn` to a tiny `boot.tscn`.

Why: `main.tscn` contains no visible UI of its own; all visible UI is built from
`src/main.gd`. If that script fails to load or throws during `_ready()`, Android
shows Godot's default gray clear color forever, which hides the actual failure.

The new boot scene:

- is visible without the game script;
- loads `main.tscn` explicitly;
- keeps a diagnostic status panel on screen until `main.gd` reports `boot_ok`;
- prints `RELIC_WEAVER_BOOT_OK` on a successful startup.

GitHub Actions now executes the actual main scene for 12 frames in headless mode
and fails the workflow if that marker is not reached. This catches startup script
and resource errors before an APK is uploaded.
