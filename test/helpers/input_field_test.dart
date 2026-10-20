// InputField (exported since 7.x, used by the edit dialog) and the
// top-level allValues formatter. Each test drives the field like a user or
// reads what the EditableText / decoration actually renders.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

import '../support/harness.dart';

/// A formatter with a `clear()` method, like the mask formatters InputField
/// resets when its clear button is tapped.
class _ClearableMask extends TextInputFormatter {
  int clears = 0;

  void clear() => clears++;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue;
}

Future<TextEditingController> _pump(
  WidgetTester tester,
  InputField Function(TextEditingController c) build, {
  String text = '',
}) async {
  final TextEditingController c = TextEditingController(text: text);
  addTearDown(c.dispose);
  await tester.pumpWidget(host(Form(child: build(c))));
  return c;
}

EditableText _editable(WidgetTester tester) =>
    tester.widget<EditableText>(find.byType(EditableText));

InputDecoration _decoration(WidgetTester tester) =>
    tester.widget<InputDecorator>(find.byType(InputDecorator)).decoration;

void main() {
  group('allValues', () {
    test('lets any text through', () {
      const TextEditingValue v = TextEditingValue(text: 'aZ 9 ç-!');
      expect(
        allValues.formatEditUpdate(TextEditingValue.empty, v).text,
        'aZ 9 ç-!',
      );
    });
  });

  group('InputField', () {
    testWidgets('shows and edits the controller text', (tester) async {
      final TextEditingController c = await _pump(
        tester,
        (c) => InputField(controle: c),
        text: 'Uva',
      );
      expect(find.text('Uva'), findsOneWidget);
      await tester.enterText(find.byType(EditableText), 'Pêra');
      expect(c.text, 'Pêra');
    });

    testWidgets('defaults: width 200, one line, text style 16, enabled', (
      tester,
    ) async {
      await _pump(tester, (c) => InputField(controle: c));
      expect(tester.getSize(find.byType(InputField)).width, 200);
      final EditableText e = _editable(tester);
      expect(e.maxLines, 1);
      expect(e.style.fontSize, 16);
      expect(
        tester.widget<InputField>(find.byType(InputField)).estilo,
        const TextStyle(fontSize: 16),
        reason: 'the public field holds the default style',
      );
      expect(e.obscureText, isFalse);
      expect(e.textAlign, TextAlign.start);
      expect(e.keyboardType, TextInputType.text);
      expect(e.textInputAction, TextInputAction.done);
      expect(e.textCapitalization, TextCapitalization.none);
      expect(e.autocorrect, isFalse);
      expect(_decoration(tester).enabled, isTrue);
    });

    testWidgets('mudeiTextoFunction receives each change', (tester) async {
      final List<String> changes = [];
      await _pump(
        tester,
        (c) => InputField(controle: c, mudeiTextoFunction: changes.add),
      );
      await tester.enterText(find.byType(EditableText), 'ab');
      expect(changes, ['ab']);
    });

    testWidgets('validator shows its message after the user types', (
      tester,
    ) async {
      await _pump(
        tester,
        (c) => InputField(
          controle: c,
          validator: (v) => (v ?? '').length < 3 ? 'curto' : null,
        ),
      );
      expect(find.text('curto'), findsNothing);
      await tester.enterText(find.byType(EditableText), 'ab');
      await tester.pump();
      expect(find.text('curto'), findsOneWidget);
      await tester.enterText(find.byType(EditableText), 'abc');
      await tester.pump();
      expect(find.text('curto'), findsNothing);
    });

    testWidgets('hint is label and hint; mostrarHint: false drops the label', (
      tester,
    ) async {
      await _pump(tester, (c) => InputField(controle: c, hint: 'Nome'));
      expect(_decoration(tester).labelText, 'Nome');
      expect(_decoration(tester).hintText, 'Nome');

      await _pump(
        tester,
        (c) => InputField(controle: c, hint: 'Nome', mostrarHint: false),
      );
      expect(_decoration(tester).labelText, isNull);
      expect(_decoration(tester).hintText, 'Nome');
    });

    testWidgets('mascara filters the input', (tester) async {
      final TextEditingController c = await _pump(
        tester,
        (c) => InputField(
          controle: c,
          mascara: FilteringTextInputFormatter.digitsOnly,
        ),
      );
      await tester.enterText(find.byType(EditableText), 'a1b2');
      expect(c.text, '12');
    });

    testWidgets('clear: the button empties the field and reports it', (
      tester,
    ) async {
      final List<String> changes = [];
      final _ClearableMask mask = _ClearableMask();
      final TextEditingController c = await _pump(
        tester,
        (c) => InputField(
          controle: c,
          clear: true,
          mascara: mask,
          mudeiTextoFunction: changes.add,
        ),
        text: 'Uva',
      );
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();
      expect(c.text, '');
      expect(changes, ['']);
      expect(mask.clears, 1);
    });

    testWidgets('without clear there is no clear button', (tester) async {
      await _pump(tester, (c) => InputField(controle: c), text: 'Uva');
      expect(find.byIcon(Icons.clear), findsNothing);
    });

    testWidgets('finishFunction runs when editing completes', (tester) async {
      int done = 0;
      await _pump(
        tester,
        (c) => InputField(controle: c, finishFunction: () => done++),
      );
      await tester.showKeyboard(find.byType(EditableText));
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(done, 1);
    });

    testWidgets('tapFunction runs on tap', (tester) async {
      int taps = 0;
      await _pump(
        tester,
        (c) => InputField(controle: c, tapFunction: () => taps++),
      );
      await tester.tap(find.byType(EditableText));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('liberado: false disables the field and ignores typing', (
      tester,
    ) async {
      final TextEditingController c = await _pump(
        tester,
        (c) => InputField(
          controle: c,
          liberado: false,
          disabledColor: Colors.orange,
        ),
      );
      expect(_decoration(tester).enabled, isFalse);
      final OutlineInputBorder b =
          _decoration(tester).disabledBorder! as OutlineInputBorder;
      expect(b.borderSide.color, Colors.orange);
      await tester.enterText(find.byType(EditableText), 'x');
      expect(c.text, '');
    });

    testWidgets('the remaining params reach the rendered field', (
      tester,
    ) async {
      await _pump(
        tester,
        (c) => InputField(
          controle: c,
          width: 321,
          oculto: true,
          raio: 4,
          elevacao: 3,
          estilo: const TextStyle(fontSize: 22),
          alinhamento: TextAlign.end,
          tipoTeclado: TextInputType.number,
          textInputButton: TextInputAction.search,
          capitalization: TextCapitalization.words,
        ),
      );
      expect(tester.getSize(find.byType(InputField)).width, 321);
      final EditableText e = _editable(tester);
      expect(e.obscureText, isTrue);
      expect(e.style.fontSize, 22);
      expect(e.textAlign, TextAlign.end);
      expect(e.keyboardType, TextInputType.number);
      expect(e.textInputAction, TextInputAction.search);
      expect(e.textCapitalization, TextCapitalization.words);
      final Material m = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(InputField),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(m.elevation, 3);
      expect(m.borderRadius, BorderRadius.circular(4));
      final OutlineInputBorder border =
          _decoration(tester).enabledBorder! as OutlineInputBorder;
      expect(border.borderRadius, BorderRadius.circular(4));
    });

    testWidgets('lines sets the maximum number of lines', (tester) async {
      await _pump(tester, (c) => InputField(controle: c, lines: 3));
      expect(_editable(tester).maxLines, 3);
    });
  });
}
