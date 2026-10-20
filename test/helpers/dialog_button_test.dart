// DialogButton renders every DialogButtonSettings field, copyWith keeps the
// fields it does not replace, and the default*ButtonSettings constants keep
// their 7.x values. The rendered tests read the box, the TextButton's
// Material, its padding and the painted label and icon.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

import '../support/harness.dart';

const DialogButtonSettings _custom = DialogButtonSettings(
  'Go',
  padding: EdgeInsets.fromLTRB(3, 4, 5, 6),
  textColor: Colors.purple,
  activeBorder: true,
  mediumFont: false,
  radius: 7,
  customHeight: 61,
  customWidth: 123,
  fontSize: 21,
  iconsize: 29,
  icon: Icons.star,
  backgroundColor: Colors.lime,
);

Future<int> _pump(WidgetTester tester, DialogButtonSettings s) async {
  int taps = 0;
  await tester.pumpWidget(
    host(DialogButton(function: () => taps++, buttonSettings: s)),
  );
  await tester.tap(find.byType(DialogButton));
  await tester.pump();
  return taps;
}

/// The decoration of the box around the button.
BoxDecoration _box(WidgetTester tester) =>
    tester
            .widget<DecoratedBox>(
              find
                  .descendant(
                    of: find.byType(DialogButton),
                    matching: find.byType(DecoratedBox),
                  )
                  .first,
            )
            .decoration
        as BoxDecoration;

/// The Material the TextButton paints with.
Material _material(WidgetTester tester) => tester.widget<Material>(
  find.descendant(of: find.byType(TextButton), matching: find.byType(Material)),
);

TextStyle _label(WidgetTester tester, String text) => tester
    .widget<RichText>(
      find.descendant(
        of: find.text(text),
        matching: find.byType(RichText),
        matchRoot: true,
      ),
    )
    .text
    .style!;

TextStyle _glyph(WidgetTester tester, IconData icon) => tester
    .widget<RichText>(
      find.descendant(of: find.byIcon(icon), matching: find.byType(RichText)),
    )
    .text
    .style!;

void main() {
  group('DialogButton renders DialogButtonSettings', () {
    testWidgets('tapping calls function once', (tester) async {
      expect(await _pump(tester, _custom), 1);
    });

    testWidgets('customWidth and customHeight size the button', (tester) async {
      await _pump(tester, _custom);
      expect(tester.getSize(find.byType(DialogButton)), const Size(123, 61));
    });

    testWidgets('activeBorder draws a border in textColor, radius rounds it', (
      tester,
    ) async {
      await _pump(tester, _custom);
      final BoxDecoration box = _box(tester);
      expect(box.border, Border.all(color: Colors.purple));
      expect(box.borderRadius, BorderRadius.circular(7));
    });

    testWidgets('without activeBorder there is no border', (tester) async {
      await _pump(tester, const DialogButtonSettings('Go'));
      expect(_box(tester).border, isNull);
    });

    testWidgets('backgroundColor and radius paint the button', (tester) async {
      await _pump(tester, _custom);
      final Material m = _material(tester);
      expect(m.color, Colors.lime);
      expect(
        m.shape,
        const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(7)),
        ),
      );
    });

    testWidgets('padding pads the content', (tester) async {
      await _pump(tester, _custom);
      expect(
        find.descendant(
          of: find.byType(TextButton),
          matching: find.byWidgetPredicate(
            (w) =>
                w is Padding &&
                w.padding == const EdgeInsets.fromLTRB(3, 4, 5, 6),
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('fontSize, textColor and mediumFont: false style the label', (
      tester,
    ) async {
      await _pump(tester, _custom);
      final TextStyle s = _label(tester, 'Go');
      expect(s.fontSize, 21);
      expect(s.color, Colors.purple);
      expect(s.fontWeight, FontWeight.normal);
    });

    testWidgets('mediumFont (default) uses w500', (tester) async {
      await _pump(tester, const DialogButtonSettings('Go'));
      expect(_label(tester, 'Go').fontWeight, FontWeight.w500);
    });

    testWidgets('icon is painted before the label in textColor at iconsize', (
      tester,
    ) async {
      await _pump(tester, _custom);
      final TextStyle g = _glyph(tester, Icons.star);
      expect(g.color, Colors.purple);
      expect(g.fontSize, 29);
      expect(
        tester.getCenter(find.byIcon(Icons.star)).dx,
        lessThan(tester.getCenter(find.text('Go')).dx),
      );
    });

    testWidgets('without icon only the label is shown', (tester) async {
      await _pump(tester, const DialogButtonSettings('Go'));
      expect(find.byType(Icon), findsNothing);
      expect(find.text('Go'), findsOneWidget);
    });

    testWidgets('the default size is 50 high and as wide as its content', (
      tester,
    ) async {
      await _pump(tester, const DialogButtonSettings('Go'));
      final Size size = tester.getSize(find.byType(DialogButton));
      expect(size.height, 50);
      expect(size.width, lessThan(160));
    });
  });

  group('DialogButtonSettings values', () {
    test('constructor defaults', () {
      const DialogButtonSettings s = DialogButtonSettings('x');
      expect(s.text, 'x');
      expect(
        s.padding,
        const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      );
      expect(s.textColor, Colors.white);
      expect(s.activeBorder, isFalse);
      expect(s.mediumFont, isTrue);
      expect(s.radius, 10);
      expect(s.customHeight, 50);
      expect(s.fontSize, 16);
      expect(s.iconsize, isNull);
      expect(s.customWidth, isNull);
      expect(s.backgroundColor, isNull);
      expect(s.icon, isNull);
    });

    test('copyWith(text:) replaces only the text', () {
      final DialogButtonSettings c = _custom.copyWith(text: 'Other');
      expect(c.text, 'Other');
      expect(c.padding, _custom.padding);
      expect(c.textColor, _custom.textColor);
      expect(c.activeBorder, _custom.activeBorder);
      expect(c.mediumFont, _custom.mediumFont);
      expect(c.radius, _custom.radius);
      expect(c.customHeight, _custom.customHeight);
      expect(c.fontSize, _custom.fontSize);
      expect(c.iconsize, _custom.iconsize);
      expect(c.customWidth, _custom.customWidth);
      expect(c.backgroundColor, _custom.backgroundColor);
      expect(c.icon, _custom.icon);
    });

    test('copyWith() keeps the text', () {
      expect(_custom.copyWith().text, 'Go');
    });

    test('defaultDeleteButtonSettings', () {
      const DialogButtonSettings s = defaultDeleteButtonSettings;
      expect(s.text, 'Apagar');
      expect(s.backgroundColor, const Color.fromARGB(255, 198, 0, 0));
      expect(s.customWidth, 160);
      expect(s.textColor, Colors.white);
      expect(s.activeBorder, isFalse);
    });

    test('defaultCancelButtonSettings', () {
      const DialogButtonSettings s = defaultCancelButtonSettings;
      expect(s.text, 'Cancelar');
      expect(s.backgroundColor, Colors.white);
      expect(s.textColor, const Color.fromARGB(255, 66, 70, 76));
      expect(s.customWidth, 160);
      expect(s.activeBorder, isTrue);
    });

    test('defaultOKButtonSettings', () {
      const DialogButtonSettings s = defaultOKButtonSettings;
      expect(s.text, 'OK');
      expect(s.customWidth, 160);
      expect(s.backgroundColor, isNull);
      expect(s.activeBorder, isFalse);
    });

    test('defaultEditButtonSettings', () {
      const DialogButtonSettings s = defaultEditButtonSettings;
      expect(s.text, 'Editar');
      expect(s.customWidth, 160);
      expect(s.backgroundColor, isNull);
      expect(s.activeBorder, isFalse);
    });
  });

  group('DialogSettings button getters', () {
    test('default to the constants', () {
      const DialogSettings s = DialogSettings();
      expect(s.customCancelButtonSettings, same(defaultCancelButtonSettings));
      expect(s.customDeleteButtonSettings, same(defaultDeleteButtonSettings));
      expect(s.customOkButtonSettings, same(defaultOKButtonSettings));
      expect(s.customEditButtonSettings, same(defaultEditButtonSettings));
      expect(s.editHint, 'Novo valor');
      expect(s.customEditHint, isNull);
    });

    test('return the custom settings and hint when given', () {
      const DialogButtonSettings a = DialogButtonSettings('a');
      const DialogButtonSettings b = DialogButtonSettings('b');
      const DialogButtonSettings c = DialogButtonSettings('c');
      const DialogButtonSettings d = DialogButtonSettings('d');
      const DialogSettings s = DialogSettings(
        customCancelButtonSettings: a,
        customDeleteButtonSettings: b,
        customOkButtonSettings: c,
        customEditButtonSettings: d,
        editHint: 'hint',
      );
      expect(s.customCancelButtonSettings, same(a));
      expect(s.customDeleteButtonSettings, same(b));
      expect(s.customOkButtonSettings, same(c));
      expect(s.customEditButtonSettings, same(d));
      expect(s.editHint, 'hint');
      expect(s.customEditHint, 'hint');
    });

    testWidgets('the dialogs render the default buttons', (tester) async {
      await tester.pumpWidget(host(WarningDialog(returnFunction: (_) {})));
      final List<DialogButton> buttons = tester
          .widgetList<DialogButton>(find.byType(DialogButton))
          .toList();
      expect(buttons.map((b) => b.buttonSettings.text), ['Cancelar', 'Apagar']);
      expect(
        tester.getSize(find.byType(DialogButton).first),
        const Size(160, 50),
      );
      final BoxDecoration cancel =
          tester
                  .widget<DecoratedBox>(
                    find
                        .descendant(
                          of: find.byType(DialogButton).first,
                          matching: find.byType(DecoratedBox),
                        )
                        .first,
                  )
                  .decoration
              as BoxDecoration;
      expect(
        cancel.border,
        Border.all(color: const Color.fromARGB(255, 66, 70, 76)),
      );
    });
  });
}
