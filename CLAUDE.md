# simple_search_dropdown

Flutter package: `SearchDropDown` (single, built on `SearchAnchor`) and `MultipleSearchDropDown` (chips + own overlay).

## Layout
- `lib/simple_search_dropdown.dart` — the only public entry point (barrel). Anything not exported is private API.
- `lib/src/single/`, `lib/src/multiple/` — widgets + controllers. `lib/src/helpers/` — settings, tiles, dialogs.
- `example/` — demo app; `example/lib/main.dart` doubles as the backwards-compatibility fixture.
- `test/` — widget/unit tests. Goldens are tagged `golden` (see `dart_test.yaml`).
- `tool/cloud_setup.sh` — installs the pinned Flutter in cloud sessions (SessionStart hook).

## Commands
- `flutter analyze` (root and `example/`) — must be 0 issues.
- `flutter test` — all green. `flutter test --update-goldens --tags golden` only for intentional visual changes.
- `dart format lib test example/lib example/test`
- `dart pub publish --dry-run` — never publish for real; releasing is the maintainer's call.

## Rules
- No feature loss: every behaviour has a test; change a test only when the old behaviour is a confirmed bug.
- `example/` must keep compiling unchanged across a release (only deprecation warnings allowed).
- Never copy or reorder the caller's lists behind their back in legacy (`listItems:`) mode, except the single in-place sort inherited from 7.x.
- Breaking changes go through `@Deprecated('Use X. Will be removed in 9.0.0')` + a CHANGELOG migration line.
- Public API gets `///` docs (one line is fine); default UI strings stay Portuguese.
- Keep defaults visually identical unless the change is intentional and goldens are updated.
