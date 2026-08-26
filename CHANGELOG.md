# Changelog

## CI hotfix (2026-08-26)

- Fixed Android GitHub Actions export: JDK and debug keystore are now visible to Godot inside the container.
- Added explicit Android SDK/JDK editor settings and debug-keystore environment variables.
- CI installs Android Platform/Build Tools 34 when missing from `godot-ci:4.3`.


## 0.3.0

- Added battle speed toggle ×1 / ×2.
- Added idle, attack, hit, dodge and death tween animations.
- Added floating damage/healing text and battle icon VFX.
- Added merge burst effect in the workshop.
- Replaced automatic post-battle item drop with a 1-of-3 reward choice.
- Added reward conversion to scrap when the board is full.
- Improved GitHub Actions with import cache, concurrency cancellation, checksums and artifact retention.
- Updated Android version to 0.3.0.

## 0.2.0

- Replaced placeholder sprites with generated pixel-art assets.
- Added Android/Linux/Windows GitHub Actions exports.
- Added tagged GitHub Releases.

## v0.3.1 runtime boot diagnostics
- Added a static boot scene so startup failures no longer look like an infinite gray screen.
- Main game reports `RELIC_WEAVER_BOOT_OK` after the home screen is constructed.
- GitHub Actions now runs the actual main scene as a headless runtime smoke test before exporting.
- Default clear color changed from Godot gray to the game's dark background.
