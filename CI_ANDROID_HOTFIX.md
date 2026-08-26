# Android CI hotfix

The Godot CI image prepares Android editor settings and the generated debug
keystore under `/root`. GitHub Actions can use another `$HOME` inside the
container, so those settings were invisible to Godot.

The fixed workflow:

- copies Godot settings/export templates from `/root` into the active `$HOME`;
- explicitly creates `editor_settings-4.3.tres` with JDK/Android SDK paths;
- supplies the debug keystore through Godot's documented environment variables;
- validates JDK, adb, export templates and the keystore before export;
- installs Android Platform/Build Tools 34 when the `godot-ci:4.3` image only
  contains 33.0.2.
