// API coverage gate: every public symbol the package exports must be used by
// at least one test (test/ or example/test/), so a new public class, named
// constructor parameter, method, getter, setter or field cannot ship
// untested. The parser is a small tokenizer + brace matcher over the
// barrel's exported files (no analyzer dependency), so it is deterministic
// and runs the same on every supported SDK.
//
// What counts as a use (in comment-stripped test sources):
// - class / top-level function / top-level variable: `\bName\b`;
// - named constructor parameter `p` of `C`: `p:` anywhere;
// - named constructor `C.n` or static member: `C.n`;
// - instance method / getter / field: `.m` (also `..m`);
// - setter: `.m =` (not `==`).
// `@override` members are skipped: they implement a framework contract
// (build, createState, dispose, ...), not the package's own API.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Symbols that legitimately have no direct reference in a test. Keep this
/// minimal; every entry needs a reason. A stale entry fails the gate.
const Map<String, String> _allowlist = {};

void main() {
  test('every exported public API symbol is referenced by a test', () {
    final symbols = _publicApi();
    expect(symbols, isNotEmpty);
    final tests = [
      for (final dir in ['test', 'example/test'])
        for (final f in Directory(dir).listSync(recursive: true))
          if (f is File && f.path.endsWith('.dart'))
            _stripComments(f.readAsStringSync()),
    ].join('\n');

    final missing = <String>[
      for (final s in symbols)
        if (!s.pattern.hasMatch(tests) && !_allowlist.containsKey(s.id)) s.id,
    ];
    final ids = {for (final s in symbols) s.id};
    final stale = <String>[
      for (final id in _allowlist.keys)
        if (!ids.contains(id) ||
            symbols.firstWhere((s) => s.id == id).pattern.hasMatch(tests))
          id,
    ];

    expect(
      missing,
      isEmpty,
      reason:
          'Exported API with no reference in test/ or example/test/. Add a '
          'test that uses it (or, with a reason, an _allowlist entry):\n'
          '${missing.join('\n')}',
    );
    expect(
      stale,
      isEmpty,
      reason:
          'Allowlist entries that are now tested or no longer exist:\n'
          '${stale.join('\n')}',
    );
  });

  test('the parser sees constructors, named params and members', () {
    final ids = {for (final s in _publicApi()) s.id};
    expect(
      ids,
      containsAll(<String>[
        'SearchDropDown',
        'SearchDropDown(controller:)',
        'SearchDropDownStrings.en',
        'SearchDropDownStrings.of',
        'SortType.selectedFirst',
        'SearchDropDownController.selectedItem=',
        'SearchDropDownController.enabled',
        'DialogSettings(customOkButtonSettings:)',
        'sendDialog',
        'darkGreen',
      ]),
    );
    expect(ids.where((id) => id.contains('_')), isEmpty);
    expect(ids, isNot(contains('SearchDropDown.build')));
  });
}

class _Symbol {
  _Symbol(this.id, String regex) : pattern = RegExp(regex);
  final String id;
  final RegExp pattern;
}

/// Public API of `lib/simple_search_dropdown.dart`: its exported files, plus
/// the private-file superclasses of exported classes (their public members
/// are reachable through the subclass, e.g. `DropDownControllerBase`).
List<_Symbol> _publicApi() {
  final barrel = File('lib/simple_search_dropdown.dart').readAsStringSync();
  final exported = [
    for (final m in RegExp(
      r"^export '\.?/?(.+?)'",
      multiLine: true,
    ).allMatches(barrel))
      'lib/${m[1]}',
  ];
  final decls = <String, _Decl>{};
  for (final f in Directory('lib/src').listSync(recursive: true)) {
    if (f is File && f.path.endsWith('.dart')) {
      for (final d in _topLevel(_stripComments(f.readAsStringSync()))) {
        decls[d.name] = d..file = f.path;
      }
    }
  }
  final out = <String, _Symbol>{};
  void add(String id, String regex) =>
      out.putIfAbsent(id, () => _Symbol(id, regex));

  void members(_Decl d, String owner) {
    for (final m in _members(d)) {
      if (m.isCtor) {
        if (m.name.isNotEmpty) {
          add('${d.name}.${m.name}', '\\b${d.name}(<[^>]*>)?\\.${m.name}\\b');
        }
        for (final p in m.namedParams) {
          if (!p.startsWith('_')) {
            add('$owner($p:)', '\\b$p\\s*:');
          }
        }
      } else if (m.isStatic) {
        add('$owner.${m.name}', '\\b${d.name}\\.${m.name}\\b');
      } else if (m.isSetter) {
        add('$owner.${m.name}=', '\\.${m.name}\\s*=(?!=)');
      } else {
        add('$owner.${m.name}', '\\.${m.name}\\b');
      }
    }
    final sup = d.supertypes
        .where(decls.containsKey)
        .map((n) => decls[n]!)
        .where((s) => s.body != null);
    for (final s in sup) {
      if (!exported.contains(s.file.replaceAll(r'\', '/'))) {
        members(s, owner);
      }
    }
  }

  for (final d in decls.values) {
    if (d.name.startsWith('_') ||
        !exported.contains(d.file.replaceAll(r'\', '/'))) {
      continue;
    }
    add(d.name, '\\b${d.name}\\b');
    if (d.body != null) {
      members(d, d.name);
    }
  }
  return out.values.toList()..sort((a, b) => a.id.compareTo(b.id));
}

class _Decl {
  _Decl(this.name, this.body, this.supertypes, {this.isEnum = false});
  final String name;
  final bool isEnum;
  final String? body; // class/enum/mixin body, null for functions/variables
  final List<String> supertypes;
  String file = '';
}

class _Member {
  _Member(
    this.name, {
    this.isCtor = false,
    this.isStatic = false,
    this.isSetter = false,
    this.isField = false,
    this.namedParams = const [],
  });
  final String name;
  final bool isCtor;
  final bool isStatic;
  final bool isSetter;
  final bool isField;
  final List<String> namedParams;
}

final _ident = RegExp(r'[A-Za-z_$][A-Za-z0-9_$]*');

/// Top-level declarations of a comment-free source.
List<_Decl> _topLevel(String src) {
  final out = <_Decl>[];
  for (final chunk in _chunks(src)) {
    final head = chunk.head.trim();
    if (head.startsWith('import ') ||
        head.startsWith('export ') ||
        head.startsWith('library') ||
        head.startsWith('part')) {
      continue;
    }
    final type = RegExp(
      r'\b(class|enum|mixin|extension(?: type)?)\s+([A-Za-z_$][\w$]*)',
    ).firstMatch(head);
    if (type != null && chunk.body != null) {
      var plain = head;
      while (plain.contains('<')) {
        final next = plain.replaceAll(RegExp('<[^<>]*>'), '');
        if (next == plain) {
          break;
        }
        plain = next;
      }
      final sup = RegExp(r'\b(?:extends|with|implements)\s+([^{]+)')
          .allMatches(plain)
          .expand((m) => _ident.allMatches(m[1]!).map((i) => i[0]!))
          .toList();
      out.add(_Decl(type[2]!, chunk.body, sup, isEnum: type[1] == 'enum'));
      continue;
    }
    final name = _declaredName(head);
    if (name != null) {
      out.add(_Decl(name, null, const []));
    }
  }
  return out;
}

/// The name a function, getter, variable or parameter declaration head
/// introduces: the identifier before its parameter list, else the last one
/// before `=`. Annotations, generics and `Function(...)` types are dropped
/// first so their identifiers and brackets do not count.
String? _declaredName(String head) {
  var h = head;
  final eq = _topIndex(h, '=');
  if (eq >= 0) {
    h = h.substring(0, eq);
  }
  h = _stripTypes(h);
  final paren = _topIndex(h, '(');
  if (paren >= 0) {
    h = h.substring(0, paren);
  }
  final ids = _ident.allMatches(h).map((m) => m[0]!).toList();
  return ids.isEmpty ? null : ids.last;
}

/// [head] without annotations, generics and `Function(...)` types.
String _stripTypes(String head) {
  var h = head.replaceAll(RegExp(r'@\w+(\([^)]*\))?\s*'), '');
  for (var prev = ''; prev != h;) {
    prev = h;
    h = h.replaceAll(RegExp('<[^<>]*>'), '');
  }
  for (
    var f = h.indexOf(RegExp(r'\bFunction\s*\('));
    f >= 0;
    f = h.indexOf(RegExp(r'\bFunction\s*\('))
  ) {
    h = h.substring(0, f) + h.substring(_close(h, h.indexOf('(', f)) + 1);
  }
  return h;
}

List<_Member> _members(_Decl d) {
  final out = <_Member>[];
  final ctorFields = <String>{};
  var body = d.body!;
  if (d.isEnum) {
    // Enum values come before the first `;` (or are the whole body).
    final semi = _topIndex(body, ';');
    final values = semi < 0 ? body : body.substring(0, semi);
    for (final v in _splitTop(values, ',')) {
      final n = _ident.firstMatch(v.trim());
      if (n != null) {
        out.add(_Member(n[0]!, isStatic: true));
      }
    }
    body = semi < 0 ? '' : body.substring(semi + 1);
  }
  for (final chunk in _chunks(body)) {
    final head = chunk.head.trim();
    if (head.isEmpty || head.contains('@override')) {
      continue;
    }
    final clean = head.replaceAll(RegExp(r'@\w+(\([^)]*\))?\s*'), '').trim();
    final isStatic = RegExp(r'^static\b').hasMatch(clean);
    final ctor = RegExp(
      '^(?:const\\s+|factory\\s+|external\\s+)*${RegExp.escape(d.name)}'
      r'(?:\.([A-Za-z_$][\w$]*))?\s*\(',
    ).firstMatch(clean);
    if (ctor != null) {
      final name = ctor[1] ?? '';
      if (name.startsWith('_')) {
        continue;
      }
      final open = ctor.end - 1;
      final params = clean.substring(open + 1, _close(clean, open));
      ctorFields.addAll(
        RegExp(
          r'\bthis\.([A-Za-z_$][\w$]*)',
        ).allMatches(params).map((m) => m[1]!),
      );
      out.add(_Member(name, isCtor: true, namedParams: _named(params)));
      continue;
    }
    if (RegExp(r'\boperator\b').hasMatch(clean)) {
      continue;
    }
    final accessor = RegExp(
      r'\b(get|set)\s+([A-Za-z_$][\w$]*)',
    ).firstMatch(clean);
    if (accessor != null &&
        _topIndex(clean.substring(0, accessor.start), '(') < 0) {
      final n = accessor[2]!;
      if (!n.startsWith('_')) {
        out.add(_Member(n, isStatic: isStatic, isSetter: accessor[1] == 'set'));
      }
      continue;
    }
    // Fields may declare several names: `final int a, b;`.
    final typeless = _stripTypes(clean);
    final paren = _topIndex(typeless, '(');
    final eq = _topIndex(typeless, '=');
    final isField = paren < 0 || (eq >= 0 && eq < paren);
    final names = isField
        ? _splitTop(clean, ',').map(_declaredName)
        : [_declaredName(clean)];
    for (final n in names.whereType<String>()) {
      if (!n.startsWith('_')) {
        out.add(_Member(n, isStatic: isStatic, isField: isField));
      }
    }
  }
  // A field set by a `this.x` constructor parameter is covered by that
  // parameter's own entry (or, if positional, by constructing the class).
  return [
    for (final m in out)
      if (!(m.isField && !m.isStatic && ctorFields.contains(m.name))) m,
  ];
}

/// Named parameter names inside a parameter list.
List<String> _named(String params) {
  final open = _topIndex(params, '{');
  if (open < 0) {
    return const [];
  }
  final inner = params.substring(open + 1, _close(params, open));
  return [
    for (final p in _splitTop(inner, ','))
      // `super.x` forwards a framework parameter (`key`), not package API.
      if (p.trim().isNotEmpty && !p.contains('super.'))
        _declaredName(p.trim())!,
  ];
}

class _Chunk {
  _Chunk(this.head, this.body);
  final String head;
  final String? body;
}

/// Splits a declaration list into declarations: each ends at a top-level
/// `;`, or at the `}` closing its top-level block (a body).
List<_Chunk> _chunks(String src) {
  final out = <_Chunk>[];
  var start = 0;
  var depth = 0; // ( [ <
  for (var i = 0; i < src.length; i++) {
    final c = src[i];
    if (c == '(' || c == '[') {
      depth++;
    }
    if (c == ')' || c == ']') {
      depth--;
    }
    if (depth > 0) {
      continue;
    }
    if (c == ';') {
      out.add(_Chunk(src.substring(start, i), null));
      start = i + 1;
    } else if (c == '{') {
      final end = _close(src, i);
      final head = src.substring(start, i);
      final isType = RegExp(r'\b(class|enum|mixin|extension)\b').hasMatch(head);
      // `=> {...}` / `= {...}` set or map literals end at the next `;`.
      if (!isType && RegExp(r'(=>|=)\s*$').hasMatch(head)) {
        i = end;
        continue;
      }
      out.add(_Chunk(head, src.substring(i + 1, end)));
      i = end;
      start = end + 1;
    }
  }
  if (src.substring(start).trim().isNotEmpty) {
    out.add(_Chunk(src.substring(start), null));
  }
  return out;
}

/// Index of the bracket matching the one at [open].
int _close(String s, int open) {
  var depth = 0;
  for (var i = open; i < s.length; i++) {
    final c = s[i];
    if (c == '(' || c == '[' || c == '{') {
      depth++;
    }
    if (c == ')' || c == ']' || c == '}') {
      depth--;
      if (depth == 0) {
        return i;
      }
    }
  }
  throw StateError('unbalanced brackets');
}

/// First index of [ch] outside any bracket pair, or -1.
int _topIndex(String s, String ch) {
  var depth = 0;
  for (var i = 0; i < s.length; i++) {
    final c = s[i];
    if (depth == 0 && c == ch) {
      return i;
    }
    if (c == '(' || c == '[' || c == '{') {
      depth++;
    }
    if (c == ')' || c == ']' || c == '}') {
      depth--;
    }
  }
  return -1;
}

/// Splits on [sep] outside brackets and generic `<...>`.
List<String> _splitTop(String s, String sep) {
  final out = <String>[];
  var depth = 0;
  var start = 0;
  for (var i = 0; i < s.length; i++) {
    final c = s[i];
    if (c == '(' || c == '[' || c == '{' || c == '<') {
      depth++;
    }
    if (c == ')' || c == ']' || c == '}') {
      depth--;
    }
    if (c == '>' && (i == 0 || s[i - 1] != '=')) {
      depth--;
    }
    if (depth == 0 && c == sep) {
      out.add(s.substring(start, i));
      start = i + 1;
    }
  }
  out.add(s.substring(start));
  return out;
}

/// Removes comments and replaces string literals with `''`, so brackets
/// and names inside them do not count. Interpolations are dropped too.
String _stripComments(String src) {
  final b = StringBuffer();
  var i = 0;
  while (i < src.length) {
    final c = src[i];
    if (src.startsWith('//', i)) {
      while (i < src.length && src[i] != '\n') {
        i++;
      }
    } else if (src.startsWith('/*', i)) {
      final end = src.indexOf('*/', i + 2);
      i = end < 0 ? src.length : end + 2;
    } else if (c == "'" || c == '"') {
      i = _skipString(src, i);
      b.write("''");
    } else {
      b.write(c);
      i++;
    }
  }
  return b.toString();
}

/// Index just past the string literal starting at [i] (handles raw,
/// triple-quoted and nested `${...}` interpolations).
int _skipString(String s, int i) {
  final raw = i > 0 && s[i - 1] == 'r';
  final q = s[i];
  final triple = s.startsWith(q * 3, i);
  final end = triple ? q * 3 : q;
  i += end.length;
  while (i < s.length) {
    if (!raw && s[i] == r'\') {
      i += 2;
    } else if (s.startsWith(end, i)) {
      return i + end.length;
    } else if (!raw && s.startsWith(r'${', i)) {
      var depth = 1;
      i += 2;
      while (i < s.length && depth > 0) {
        if (s[i] == "'" || s[i] == '"') {
          i = _skipString(s, i);
          continue;
        }
        if (s[i] == '{') {
          depth++;
        }
        if (s[i] == '}') {
          depth--;
        }
        i++;
      }
    } else {
      i++;
    }
  }
  return i;
}
