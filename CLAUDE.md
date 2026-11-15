# CLAUDE.md

This project uses Godot 4.7.2 (Compatibility renderer) with typed GDScript.
See `AGENTS.md` for full agent notes and `README.md` for setup and architecture.

## Quick rules
- Game rules live in `scripts/game/` and must stay free of nodes, input, and animation.
- Gravity is isolated in `scripts/game/gravity.gd`; do not change the rule silently.
- Run both test runners after any change:
  - `godot --headless --path . -s tests/run_tests.gd`
  - `godot --headless --path . res://tests/ui_tests.tscn`
- Tests must not touch the real `user://settings.cfg`; set `Settings.save_path`.
- Autoloads (`Settings`, `Haptics`, `Sfx`) are not visible to scripts run with `-s`.
- Never commit `build/`, keystores, passwords, or `export_credentials.cfg`.
- Never claim an APK/AAB exists unless the export actually succeeded.
- Do not convert to React, HTML, or Kotlin. Keep Godot as the game engine.