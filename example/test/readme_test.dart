import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every `#docregion` of lib/readme_samples.dart must appear verbatim in the
/// package README, so the documented code is always code that compiles.
void main() {
  test('README samples match lib/readme_samples.dart', () {
    final String samples = File('lib/readme_samples.dart').readAsStringSync();
    final String readme = File('../README.md').readAsStringSync();
    final Iterable<RegExpMatch> regions = RegExp(
      r'// #docregion (\w+)\n(.*?)// #enddocregion \1',
      dotAll: true,
    ).allMatches(samples);

    expect(regions, isNotEmpty);
    for (final RegExpMatch region in regions) {
      final String code = region.group(2)!.trim();
      expect(readme.contains(code), isTrue,
          reason: 'README is missing the "${region.group(1)}" sample');
    }
  });
}
