// The exported dialogs: DialogSettings layout fields reach the AlertDialog
// that WarningDialog and EditDialog paint, DefaultDialogTitle/Content in
// both confirmDialog variants, and sendDialog's barrier. Each test reads the
// rendered geometry or the Material that paints the dialog.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

import '../support/harness.dart';

const Key _titleKey = Key('title');
const Key _contentKey = Key('content');

/// Settings with every layout field away from its default. The title and
/// content are wide fixed boxes so the dialog fills the inset area and their
/// offsets inside the dialog are exactly the paddings.
const DialogSettings _layout = DialogSettings(
  title: SizedBox(key: _titleKey, width: 2000, height: 10),
  content: SizedBox(key: _contentKey, width: 2000, height: 10),
  titlePadding: EdgeInsets.fromLTRB(11, 12, 13, 14),
  contentPadding: EdgeInsets.fromLTRB(31, 32, 33, 34),
  actionsPadding: EdgeInsets.fromLTRB(5, 6, 7, 8),
  actionsAlignment: MainAxisAlignment.start,
  backgroundColor: Colors.amber,
  elevation: 17,
  shape: BeveledRectangleBorder(),
  insetPadding: EdgeInsets.symmetric(horizontal: 50, vertical: 30),
);

/// A button that shows [dialog] with [sendDialog].
Widget _launcher(Widget dialog, {bool? barrierDismissible}) => host(
  Builder(
    builder: (context) => TextButton(
      onPressed: () => barrierDismissible == null
          ? sendDialog<void>(context, dialog)
          : sendDialog<void>(
              context,
              dialog,
              barrierDismissible: barrierDismissible,
            ),
      child: const Text('open'),
    ),
  ),
);

Future<void> _show(
  WidgetTester tester,
  Widget dialog, {
  bool? barrierDismissible,
}) async {
  await tester.pumpWidget(
    _launcher(dialog, barrierDismissible: barrierDismissible),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

/// The Material that paints the dialog surface.
Finder _surface() => find
    .descendant(of: find.byType(Dialog), matching: find.byType(Material))
    .first;

/// The style the text [text] is painted with.
RichText _painted(WidgetTester tester, String text) => tester.widget<RichText>(
  find.descendant(
    of: find.text(text),
    matching: find.byType(RichText),
    matchRoot: true,
  ),
);

TextStyle _style(WidgetTester tester, String text) =>
    _painted(tester, text).text.style!;

TextAlign _align(WidgetTester tester, String text) =>
    _painted(tester, text).textAlign;

void main() {
  final Map<String, Widget Function(DialogSettings? s)> dialogs = {
    'WarningDialog (confirm)': (s) =>
        WarningDialog(settings: s, returnFunction: (_) {}),
    'WarningDialog (invalid item)': (s) => WarningDialog(
      settings: s,
      confirmDialog: false,
      returnFunction: (_) {},
    ),
    'EditDialog': (s) =>
        EditDialog(label: 'Uva', settings: s, returnFunction: (ok, text) {}),
  };

  for (final MapEntry<String, Widget Function(DialogSettings?)> d
      in dialogs.entries) {
    group('${d.key} applies DialogSettings layout', () {
      testWidgets('backgroundColor, elevation and shape paint the surface', (
        tester,
      ) async {
        await _show(tester, d.value(_layout));
        final Material m = tester.widget<Material>(_surface());
        expect(m.color, Colors.amber);
        expect(m.elevation, 17);
        expect(m.shape, const BeveledRectangleBorder());
      });

      testWidgets('insetPadding is the gap to the screen edges', (
        tester,
      ) async {
        await _show(tester, d.value(_layout));
        final Rect r = tester.getRect(_surface());
        expect(r.left, 50);
        expect(r.right, 800 - 50);
      });

      testWidgets('titlePadding offsets the title inside the surface', (
        tester,
      ) async {
        await _show(tester, d.value(_layout));
        final Rect surface = tester.getRect(_surface());
        final Rect title = tester.getRect(find.byKey(_titleKey));
        expect(title.left - surface.left, 11);
        expect(title.top - surface.top, 12);
        expect(surface.right - title.right, 13);
      });

      testWidgets('contentPadding offsets the content inside the surface', (
        tester,
      ) async {
        await _show(tester, d.value(_layout));
        final Rect surface = tester.getRect(_surface());
        final Rect content = tester.getRect(find.byKey(_contentKey));
        expect(content.left - surface.left, 31);
        expect(surface.right - content.right, 33);
      });

      testWidgets('actionsPadding and actionsAlignment place the buttons', (
        tester,
      ) async {
        await _show(tester, d.value(_layout));
        final Rect surface = tester.getRect(_surface());
        final Rect first = tester.getRect(find.byType(DialogButton).first);
        final Rect last = tester.getRect(find.byType(DialogButton).last);
        // start alignment: the first button sits at the left padding.
        expect(first.left - surface.left, 5);
        expect(surface.bottom - last.bottom, 8);
      });

      testWidgets('actionsAlignment center centres fixed-width buttons', (
        tester,
      ) async {
        const DialogButtonSettings fixed = DialogButtonSettings(
          'b',
          customWidth: 80,
        );
        await _show(
          tester,
          d.value(
            const DialogSettings(
              content: SizedBox(width: 2000, height: 10),
              actionsPadding: EdgeInsets.zero,
              actionsAlignment: MainAxisAlignment.center,
              customCancelButtonSettings: fixed,
              customDeleteButtonSettings: fixed,
              customOkButtonSettings: fixed,
              customEditButtonSettings: fixed,
            ),
          ),
        );
        final Rect surface = tester.getRect(_surface());
        final Rect first = tester.getRect(find.byType(DialogButton).first);
        final Rect last = tester.getRect(find.byType(DialogButton).last);
        expect(
          first.left - surface.left,
          moreOrLessEquals(surface.right - last.right),
        );
        expect(first.left - surface.left, greaterThan(0));
      });

      testWidgets('without settings the default insetPadding (40, 24) holds', (
        tester,
      ) async {
        await _show(
          tester,
          d.value(
            const DialogSettings(content: SizedBox(width: 2000, height: 10)),
          ),
        );
        final Rect r = tester.getRect(_surface());
        expect(r.left, 40);
        expect(r.right, 800 - 40);
      });
    });
  }

  group('DefaultDialogTitle and DefaultDialogContent', () {
    testWidgets('confirmDialog: true shows the delete confirmation', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const Column(
            children: [
              DefaultDialogTitle(confirmDialog: true),
              DefaultDialogContent(confirmDialog: true),
            ],
          ),
        ),
      );
      expect(find.text('Tem certeza?'), findsOneWidget);
      expect(find.text('Essa ação não poderá ser desfeita.'), findsOneWidget);
      expect(find.text('Erro!'), findsNothing);
      final TextStyle title = _style(tester, 'Tem certeza?');
      expect(title.fontWeight, FontWeight.w600);
      expect(title.fontSize, 20);
      expect(_align(tester, 'Tem certeza?'), TextAlign.center);
      final TextStyle body = _style(
        tester,
        'Essa ação não poderá ser desfeita.',
      );
      expect(body.fontSize, 14);
      expect(
        body.color,
        Theme.of(
          tester.element(find.byType(DefaultDialogContent)),
        ).colorScheme.onSurfaceVariant,
      );
      expect(
        _align(tester, 'Essa ação não poderá ser desfeita.'),
        TextAlign.center,
      );
    });

    testWidgets('confirmDialog: false shows the invalid-item warning', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const Column(
            children: [
              DefaultDialogTitle(confirmDialog: false),
              DefaultDialogContent(confirmDialog: false),
            ],
          ),
        ),
      );
      expect(find.text('Erro!'), findsOneWidget);
      expect(find.text('O valor adicionado não é válido.'), findsOneWidget);
      expect(find.text('Tem certeza?'), findsNothing);
      expect(_style(tester, 'Erro!').fontWeight, FontWeight.w600);
      expect(_style(tester, 'Erro!').fontSize, 20);
      expect(_style(tester, 'O valor adicionado não é válido.').fontSize, 14);
    });

    testWidgets('both variants use the given strings', (tester) async {
      const SearchDropDownStrings en = SearchDropDownStrings.en();
      await tester.pumpWidget(
        host(
          const Column(
            children: [
              DefaultDialogTitle(confirmDialog: true, strings: en),
              DefaultDialogContent(confirmDialog: true, strings: en),
              DefaultDialogTitle(confirmDialog: false, strings: en),
              DefaultDialogContent(confirmDialog: false, strings: en),
            ],
          ),
        ),
      );
      expect(find.text('Are you sure?'), findsOneWidget);
      expect(find.text('This action cannot be undone.'), findsOneWidget);
      expect(find.text('Error!'), findsOneWidget);
      expect(find.text('The value is not valid.'), findsOneWidget);
    });

    testWidgets('WarningDialog shows them unless title/content are set', (
      tester,
    ) async {
      await _show(tester, WarningDialog(returnFunction: (_) {}));
      expect(find.byType(DefaultDialogTitle), findsOneWidget);
      expect(find.byType(DefaultDialogContent), findsOneWidget);
      expect(find.text('Tem certeza?'), findsOneWidget);
    });
  });

  group('sendDialog barrier', () {
    testWidgets('by default a tap outside keeps the dialog open', (
      tester,
    ) async {
      await _show(tester, WarningDialog(returnFunction: (_) {}));
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.byType(WarningDialog), findsOneWidget);
    });

    testWidgets('barrierDismissible: true lets a tap outside close it', (
      tester,
    ) async {
      await _show(
        tester,
        WarningDialog(returnFunction: (_) {}),
        barrierDismissible: true,
      );
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.byType(WarningDialog), findsNothing);
    });

    testWidgets('returns the value the dialog pops with', (tester) async {
      String? result;
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async => result = await sendDialog<String>(
                context,
                Builder(
                  builder: (dc) => TextButton(
                    onPressed: () => Navigator.of(dc).pop('done'),
                    child: const Text('pop'),
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('pop'));
      await tester.pumpAndSettle();
      expect(result, 'done');
    });

    testWidgets(
      'a delete confirmation ignores a tap outside and deletes nothing',
      (tester) async {
        final List<ValueItem<int>> deleted = [];
        final SearchDropDownController<int> c = SearchDropDownController<int>(
          items: fruitItems(),
          addMode: false,
          onDeleteItem: deleted.add,
          confirmDelete: true,
        );
        addTearDown(c.dispose);
        await tester.pumpWidget(
          host(
            Builder(
              builder: (ctx) => TextButton(
                onPressed: () => c.deleteItem(c.items[1], ctx),
                child: const Text('open'),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        expect(find.text('Apagar item?'), findsOneWidget);

        await tester.tapAt(const Offset(5, 5));
        await tester.pumpAndSettle();
        expect(find.text('Apagar item?'), findsOneWidget);
        expect(deleted, isEmpty);
        expect(c.items.map((e) => e.label), fruitItems().map((e) => e.label));

        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();
        expect(find.text('Apagar item?'), findsNothing);
        expect(deleted, isEmpty);
        expect(c.items, hasLength(5));
      },
    );
  });
}
