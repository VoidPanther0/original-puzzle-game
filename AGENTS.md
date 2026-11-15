# Agent notes (Claude Code, OpenCode)

- Godot 4.7.2, typed GDScript, Compatibility renderer. No C#, no plugins.
- Game rules live in `scripts/game/` and must stay free of nodes, input and
  animation. Gravity is isolated in `scripts/game/gravity.gd`; do not change the
  rule silently (see README "Rules in detail").
- Run both test runners after any change (commands in README). They must pass.
- Tests must not touch the real `user://settings.cfg`; set `Settings.save_path`.
- Autoloads (`Settings`, `Haptics`, `Sfx`) are not visible to scripts run with
  `-s`; UI tests therefore run as a scene.
- Never commit `build/`, keystores, passwords or `export_credentials.cfg`.
- Never claim an APK/AAB exists unless the export actually succeeded.
