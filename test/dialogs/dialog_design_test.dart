// The visual contract of the three package dialogs (edit, delete
// confirmation, invalid-item warning) on a 390 px phone: one row of
// equal-width buttons, legible filled buttons, a themed outlined Cancelar,
// the item label in the delete confirmation, an edit field that is prefilled,
// selected and submits on Enter, and list rows that do not shift while an
// action spinner runs.

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

import '../support/harness.dart';

/// WCAG contrast ratio of two opaque colours.
double _contrast(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  final double hi = la > lb ? la : lb;
  final double lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// Pumps [dialog] alone on a 390x844 phone (devicePixelRatio 2).
Future<void> _phone(
  WidgetTester tester,
  Widget dialog, {
  ThemeData? theme,
}) async {
  tester.view.physicalSize = const Size(780, 1688);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(host(dialog, theme: theme));
  await tester.pump();
}

Finder _button(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(DialogButton));

/// The Material the button labelled [label] paints its background with.
Material _fill(WidgetTester tester, String label) => tester.widget<Material>(
  find.descendant(of: _button(label), matching: find.byType(Material)).first,
);

/// The colour the label [label] is painted with.
Color _ink(WidgetTester tester, String label) => tester
    .widget<RichText>(
      find.descendant(
        of: find.text(label),
        matching: find.byType(RichText),
        matchRoot: true,
      ),
    )
    .text
    .style!
    .color!;

BoxDecoration _box(WidgetTester tester, String label) =>
    tester
            .widget<DecoratedBox>(
              find
                  .descendant(
                    of: _button(label),
                    matching: find.byType(DecoratedBox),
                  )
                  .first,
            )
            .decoration
        as BoxDecoration;

/// The dialog's surface colour.
Color _surface(WidgetTester tester) => tester
    .widget<Material>(
      find
          .descendant(of: find.byType(Dialog), matching: find.byType(Material))
          .first,
    )
    .color!;

void _expectOneRow(WidgetTester tester, List<String> labels) {
  expect(tester.takeException(), isNull, reason: 'no overflow');
  final List<Rect> rects = [
    for (final String l in labels) tester.getRect(_button(l)),
  ];
  for (final Rect r in rects) {
    expect(r.top, rects.first.top, reason: 'one row');
    expect(r.width, moreOrLessEquals(rects.first.width), reason: 'equal');
    expect(r.height, 48);
  }
  for (int i = 1; i < rects.length; i++) {
    expect(rects[i].left - rects[i - 1].right, 12, reason: 'gap 12');
  }
  final Rect dialog = tester.getRect(
    find
        .descendant(of: find.byType(Dialog), matching: find.byType(Material))
        .first,
  );
  // The row spans the dialog content width (24 padding each side).
  expect(rects.first.left - dialog.left, 24);
  expect(dialog.right - rects.last.right, 24);
  for (final String l in labels) {
    final Rect text = tester.getRect(find.text(l));
    final Rect button = tester.getRect(_button(l));
    expect(text.height, lessThan(30), reason: '"$l" on one line');
    expect(
      button.contains(text.topLeft) && button.contains(text.bottomRight),
      isTrue,
      reason: '"$l" not clipped',
    );
  }
}

/// Loads the SDK's Roboto (the Material font on the test platform) so
/// label widths are the real ones, not the square test glyphs.
Future<void> _loadRoboto() async {
  final String fonts =
      '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/'
      'material_fonts';
  final FontLoader loader = FontLoader('Roboto');
  for (final String w in ['Regular', 'Medium', 'Bold']) {
    final File f = File('$fonts/Roboto-$w.ttf');
    loader.addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
  }
  await loader.load();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadRoboto();
  });

  final Map<String, (Widget, List<String>)> dialogs = {
    'edit': (
      EditDialog(label: 'Lorenzo', returnFunction: (_, _) {}),
      ['Cancelar', 'Editar'],
    ),
    'delete': (
      WarningDialog(itemLabel: 'Lorenzo', returnFunction: (_) {}),
      ['Cancelar', 'Apagar'],
    ),
    'warning': (
      WarningDialog(confirmDialog: false, returnFunction: (_) {}),
      ['OK'],
    ),
  };

  group('buttons sit on one row at 390 px, equal width, 48 high', () {
    for (final MapEntry<String, (Widget, List<String>)> d in dialogs.entries) {
      testWidgets('${d.key} dialog (Portuguese)', (tester) async {
        await _phone(tester, d.value.$1);
        _expectOneRow(tester, d.value.$2);
      });
    }

    testWidgets('delete dialog in English', (tester) async {
      await _phone(
        tester,
        WarningDialog(
          itemLabel: 'Lorenzo',
          strings: const SearchDropDownStrings.en(),
          returnFunction: (_) {},
        ),
      );
      _expectOneRow(tester, ['Cancel', 'Delete']);
    });

    testWidgets('an explicit customWidth is still honoured', (tester) async {
      await _phone(
        tester,
        WarningDialog(
          settings: const DialogSettings(
            customDeleteButtonSettings: DialogButtonSettings(
              'Apagar',
              customWidth: 90,
            ),
          ),
          returnFunction: (_) {},
        ),
      );
      expect(tester.getSize(_button('Apagar')).width, 90);
      expect(
        tester.getRect(_button('Cancelar')).right,
        tester.getRect(_button('Apagar')).left - 12,
      );
    });
  });

  group('button colours', () {
    for (final String label in ['Editar', 'OK']) {
      testWidgets('$label is filled darkGreen with white text (>= 4.5:1)', (
        tester,
      ) async {
        await _phone(
          tester,
          label == 'OK' ? dialogs['warning']!.$1 : dialogs['edit']!.$1,
        );
        expect(_fill(tester, label).color, darkGreen);
        expect(_ink(tester, label), Colors.white);
        expect(
          _contrast(_ink(tester, label), darkGreen),
          greaterThanOrEqualTo(4.5),
        );
      });
    }

    testWidgets('Apagar stays red with white text (>= 4.5:1)', (tester) async {
      await _phone(tester, dialogs['delete']!.$1);
      const Color red = Color.fromARGB(255, 198, 0, 0);
      expect(_fill(tester, 'Apagar').color, red);
      expect(_contrast(_ink(tester, 'Apagar'), red), greaterThanOrEqualTo(4.5));
    });

    for (final Brightness b in Brightness.values) {
      testWidgets('Cancelar is outlined in the theme colours ($b)', (
        tester,
      ) async {
        final ThemeData theme = ThemeData(useMaterial3: true, brightness: b);
        await _phone(tester, dialogs['delete']!.$1, theme: theme);
        final Color fill =
            _fill(tester, 'Cancelar').color ?? Colors.transparent;
        expect(fill.a, 0, reason: 'no fill: the dialog surface shows');
        expect(_ink(tester, 'Cancelar'), theme.colorScheme.onSurface);
        expect(
          _box(tester, 'Cancelar').border,
          Border.all(color: theme.colorScheme.outline),
        );
        expect(
          _contrast(_ink(tester, 'Cancelar'), _surface(tester)),
          greaterThanOrEqualTo(4.5),
        );
      });
    }
  });

  group('typography and alignment', () {
    for (final MapEntry<String, (Widget, List<String>)> d in dialogs.entries) {
      testWidgets('${d.key}: centred semibold 20 title', (tester) async {
        await _phone(tester, d.value.$1);
        final Finder title = find
            .descendant(
              of: find.byType(Dialog),
              matching: find.byType(RichText),
            )
            .first;
        final RichText t = tester.widget<RichText>(title);
        expect(t.text.style!.fontWeight, FontWeight.w600);
        expect(t.text.style!.fontSize, 20);
        expect(t.textAlign, TextAlign.center);
      });
    }
  });

  group('delete confirmation shows the item label', () {
    testWidgets('by default: "Apagar item?" and the label in bold, once', (
      tester,
    ) async {
      await _phone(tester, dialogs['delete']!.$1);
      expect(find.text('Apagar item?'), findsOneWidget);
      expect(find.text('Tem certeza?'), findsNothing);
      final Finder line = find.textContaining('Lorenzo', findRichText: true);
      expect(line, findsOneWidget);
      final RichText rich = tester.widget<RichText>(
        find.descendant(
          of: line,
          matching: find.byType(RichText),
          matchRoot: true,
        ),
      );
      expect(rich.text.toPlainText(), '“Lorenzo” será apagado.');
      final List<TextSpan> bold = <TextSpan>[];
      rich.text.visitChildren((InlineSpan s) {
        if (s is TextSpan && s.style?.fontWeight == FontWeight.w600) {
          bold.add(s);
        }
        return true;
      });
      expect(bold.map((s) => s.text), ['Lorenzo']);
      expect(find.text('Essa ação não poderá ser desfeita.'), findsOneWidget);
    });

    testWidgets('showItemLabel: false keeps the generic texts', (tester) async {
      await _phone(
        tester,
        WarningDialog(
          itemLabel: 'Lorenzo',
          settings: const DialogSettings(showItemLabel: false),
          returnFunction: (_) {},
        ),
      );
      expect(find.text('Tem certeza?'), findsOneWidget);
      expect(find.textContaining('Lorenzo', findRichText: true), findsNothing);
      expect(find.text('Essa ação não poderá ser desfeita.'), findsOneWidget);
    });

    testWidgets('the invalid-item warning ignores itemLabel', (tester) async {
      await _phone(
        tester,
        WarningDialog(
          confirmDialog: false,
          itemLabel: 'Lorenzo',
          returnFunction: (_) {},
        ),
      );
      expect(find.text('Erro!'), findsOneWidget);
      expect(find.textContaining('Lorenzo', findRichText: true), findsNothing);
    });

    testWidgets('English strings and a template without {item}', (
      tester,
    ) async {
      await _phone(
        tester,
        WarningDialog(
          itemLabel: 'Grape',
          strings: const SearchDropDownStrings.en(),
          returnFunction: (_) {},
        ),
      );
      expect(find.text('Delete item?'), findsOneWidget);
      expect(
        find.text('“Grape” will be deleted.', findRichText: true),
        findsOneWidget,
      );
      await _phone(
        tester,
        WarningDialog(
          itemLabel: 'Grape',
          strings: const SearchDropDownStrings(
            confirmDeleteItemContent: 'Sem marcador.',
          ),
          returnFunction: (_) {},
        ),
      );
      expect(find.text('Sem marcador.', findRichText: true), findsOneWidget);
    });

    for (final bool multiple in [false, true]) {
      testWidgets(
        '${multiple ? 'multiple' : 'single'} controller passes the label',
        (tester) async {
          final dynamic c = multiple
              ? MultipleSearchDropDownController<int>(
                  items: fruitItems(),
                  addMode: false,
                  confirmDelete: true,
                  onDeleteItem: (_) {},
                )
              : SearchDropDownController<int>(
                  items: fruitItems(),
                  addMode: false,
                  confirmDelete: true,
                  onDeleteItem: (_) {},
                );
          addTearDown(() => c.dispose());
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
          expect(
            find.text('“Banana” será apagado.', findRichText: true),
            findsOneWidget,
          );
          await tester.tap(find.text('Cancelar'));
          await tester.pumpAndSettle();
        },
      );
    }
  });

  group('edit field', () {
    testWidgets('is prefilled, fully selected, focused; label shown once', (
      tester,
    ) async {
      await _phone(tester, dialogs['edit']!.$1);
      final TextField field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, 'Lorenzo');
      expect(
        field.controller!.selection,
        const TextSelection(baseOffset: 0, extentOffset: 7),
      );
      expect(field.autofocus, isTrue);
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isTrue,
      );
      // Only the field shows the label: no duplicated line above it.
      expect(find.text('Lorenzo'), findsOneWidget);
      expect(field.decoration!.labelText, 'Novo valor');
      expect(field.decoration!.hintText, isNull);
      expect(field.decoration!.border, isA<OutlineInputBorder>());
      // Full content width: the dialog minus its 24 padding each side.
      final Rect dialog = tester.getRect(
        find
            .descendant(
              of: find.byType(Dialog),
              matching: find.byType(Material),
            )
            .first,
      );
      final Rect r = tester.getRect(find.byType(TextField));
      expect(r.left - dialog.left, 24);
      expect(dialog.right - r.right, 24);
    });

    testWidgets('Enter confirms with the typed text', (tester) async {
      final List<(bool, String)> results = [];
      await _phone(
        tester,
        EditDialog(
          label: 'Lorenzo',
          returnFunction: (ok, text) => results.add((ok, text)),
        ),
      );
      await tester.enterText(find.byType(TextField), 'Lorena');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(results, [(true, 'Lorena')]);
    });

    testWidgets('Enter on an empty field does nothing', (tester) async {
      final List<(bool, String)> results = [];
      await _phone(
        tester,
        EditDialog(
          label: 'Lorenzo',
          returnFunction: (ok, text) => results.add((ok, text)),
        ),
      );
      await tester.enterText(find.byType(TextField), '');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(results, isEmpty);
    });

    testWidgets('an app inputDecorationTheme border is kept', (tester) async {
      await _phone(
        tester,
        dialogs['edit']!.$1,
        theme: ThemeData(
          useMaterial3: true,
          inputDecorationTheme: const InputDecorationTheme(
            border: UnderlineInputBorder(),
          ),
        ),
      );
      final TextField field = tester.widget<TextField>(find.byType(TextField));
      expect(field.decoration!.border, isNull);
      final InputDecorator d = tester.widget<InputDecorator>(
        find.byType(InputDecorator),
      );
      expect(d.decoration.border, isA<UnderlineInputBorder>());
    });
  });

  group('rows keep their layout while an action spinner runs', () {
    for (final IconData icon in [Icons.delete, Icons.edit]) {
      testWidgets('$icon: label and row do not move', (tester) async {
        final Completer<void> done = Completer<void>();
        await tester.pumpWidget(
          host(
            SizedBox(
              width: 340,
              child: DefaultListTile<int>(
                deleteMode: true,
                editMode: true,
                item: const ValueItem(label: 'Lorenzo', value: 1),
                onDelete: (_) => done.future,
                onEdit: (_) => done.future,
                onPressed: (_) {},
                overlayListSettings: const SimpleOverlaySettings(),
                selected: false,
              ),
            ),
          ),
        );
        final Rect label = tester.getRect(find.text('Lorenzo'));
        final Rect row = tester.getRect(find.byType(DefaultListTile<int>));
        final Rect actions = tester
            .getRect(find.byIcon(Icons.edit))
            .expandToInclude(tester.getRect(find.byIcon(Icons.delete)));

        await tester.tap(find.byIcon(icon));
        await tester.pump();
        expect(find.byType(Loading), findsOneWidget);
        expect(tester.getRect(find.text('Lorenzo')), label);
        expect(tester.getRect(find.byType(DefaultListTile<int>)), row);
        // The spinner sits inside the area the buttons used.
        final Rect spin = tester.getRect(find.byType(Loading));
        expect(actions.inflate(12).contains(spin.center), isTrue);
        // The hidden buttons take no taps and no focus.
        FocusNode focusOf(IconData i) =>
            Focus.of(tester.element(find.byIcon(i, skipOffstage: false)));
        expect(focusOf(Icons.delete).canRequestFocus, isFalse);
        expect(focusOf(Icons.edit).canRequestFocus, isFalse);
        expect(find.byTooltip('Apagar item').hitTestable(), findsNothing);

        done.complete();
        await tester.pumpAndSettle();
        expect(find.byType(Loading), findsNothing);
        expect(find.byIcon(Icons.delete).hitTestable(), findsOneWidget);
        expect(focusOf(Icons.delete).canRequestFocus, isTrue);
      });
    }

    testWidgets('the add row keeps its height and text place', (tester) async {
      final Completer<void> done = Completer<void>();
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 340,
            child: DefaultAddListItem(
              text: 'Novo',
              overlayListSettings: const SimpleOverlaySettings(),
              itemAdded: (_) => done.future,
            ),
          ),
        ),
      );
      final Rect text = tester.getRect(find.text('Novo'));
      final Rect row = tester.getRect(find.byType(DefaultAddListItem));
      await tester.tap(find.text('Criar'));
      await tester.pump();
      expect(find.byType(Loading), findsOneWidget);
      expect(tester.getRect(find.text('Novo')), text);
      expect(tester.getRect(find.byType(DefaultAddListItem)), row);
      expect(find.text('Criar').hitTestable(), findsNothing);
      done.complete();
      await tester.pumpAndSettle();
      expect(find.text('Criar').hitTestable(), findsOneWidget);
    });
  });
}
