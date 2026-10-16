import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// lib/{main,custom,listitems,dialog_test}.dart are the 7.x
/// backwards-compatibility fixture (CLAUDE.md: "example/ must keep compiling
/// unchanged"). The ids are the git blob ids of those files in the 7.8.0
/// release commit cecbf2b (`git rev-parse cecbf2b:example/lib/<file>`).
/// They are hard-coded because CI checks out a single commit, so no history
/// is read here. Never update them to make a compile error go away: fix the
/// library instead. lib/readme_samples.dart is new in 8.0 and is guarded by
/// readme_test.dart instead.
const Map<String, String> _frozen = <String, String>{
  'lib/main.dart': '1d0859a7f00672cdccf315a6fe69868cdce73734',
  'lib/custom.dart': '27fc4d6658f420a3a56638c1a47c7cc4313d7b13',
  'lib/listitems.dart': 'ef72f8ba76b98dafc02b80dbcf8def4580ae9d9e',
  'lib/dialog_test.dart': '16d2629ae923a3305e0b6ad0bcc99d67fafd2e8b',
};

/// `null` when git can hash files here, otherwise why the tests are skipped.
String? _gitUnavailable() {
  try {
    final ProcessResult r =
        Process.runSync('git', <String>['hash-object', 'pubspec.yaml']);
    return r.exitCode == 0 ? null : 'git hash-object failed: ${r.stderr}';
  } on ProcessException catch (e) {
    return 'git is not available: ${e.message}';
  }
}

void main() {
  final String? skip = _gitUnavailable();
  for (final MapEntry<String, String> e in _frozen.entries) {
    test('${e.key} is byte-identical to 7.8.0', skip: skip, () {
      final ProcessResult r =
          Process.runSync('git', <String>['hash-object', e.key]);
      expect(r.exitCode, 0, reason: '${r.stderr}');
      expect((r.stdout as String).trim(), e.value,
          reason: '${e.key} is the 7.x compat fixture and must not change; '
              'restore it with `git checkout cecbf2b -- example/${e.key}`');
    });
  }
}
