# simple_search_dropdown

Flutter package: `SearchDropDown` (single, built on `SearchAnchor`) and `MultipleSearchDropDown` (chips + an `OverlayPortal` list), each driven by a required controller.

## Layout
- `lib/simple_search_dropdown.dart` — the only public entry point (barrel). Anything not exported is private API.
- `lib/src/single/`, `lib/src/multiple/` — widgets + controllers. `lib/src/core/` — shared controller base, filter engine, strings, `SortType`. `lib/src/helpers/` — settings, tiles; `lib/src/dialogs/` — dialogs.
- `example/` — demo app on the current API; `example/lib/readme_samples.dart` holds the README code (checked by `example/test/readme_test.dart`).
- `test/` — widget/unit tests. Goldens are tagged `golden` (see `dart_test.yaml`).
- `tool/cloud_setup.sh` — installs the pinned Flutter in cloud sessions (SessionStart hook).

## Commands
- `flutter analyze` (root and `example/`) — must be 0 issues.
- `flutter test` (root and `example/`) — all green. `flutter test --update-goldens --tags golden` only for intentional visual changes.
- `dart format lib test example/lib example/test`
- `dart pub publish --dry-run` — never publish for real; releasing is the maintainer's call.

## Rules
- No feature loss: every behaviour has a test; change a test only when the old behaviour is a confirmed bug.
- `example/` uses the current API and has its own tests (`example/test`).
- Controllers own their item list; never mutate a caller's list.
- Breaking changes only in a major version, with a migration line in CHANGELOG.
- Public API gets `///` docs (one line is fine); default UI strings stay Portuguese.
- Keep defaults visually identical unless the change is intentional and goldens are updated.
