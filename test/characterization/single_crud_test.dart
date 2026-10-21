// Characterization tests for the add / edit / delete (CRUD) surface of the
// single-selection SearchDropDown. Written against v7.8.0,
// they now lock the 8.0 behaviour; "(8.0)" marks a deliberate change from
// 7.x. Tests tagged 'B<n>' are regression tests for a 7.x bug fixed in 8.0.
//
// Note: rows show an indeterminate spinner while a delete / edit dialog is
// open, so those flows use [_frames] instead of pumpAndSettle (which would
// never settle while the spinner animates).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

import '../support/harness.dart';

// A taller overlay so every row of the small fixtures is built.
const SimpleOverlaySettings _tall = SimpleOverlaySettings(dialogHeight: 400);

ValueItem<int> _newItem(String input) =>
    ValueItem<int>(label: input, value: 99);

SearchDropDownController<int> _ctrl(
  List<ValueItem<int>> items, {
  bool addMode = false,
  bool deleteMode = false,
  bool editMode = false,
  bool confirmDelete = false,
  ValueItem<int> Function(String input)? newValueItem,
  Function(ValueItem<int>)? onAddItem,
  Function(ValueItem<int>)? onDeleteItem,
  Function(ValueItem<int> original, ValueItem<int> newValue)? onEditItem,
  bool Function(ValueItem<int>)? verifyInputItem,
  DialogSettings? deleteDialogSettings,
  DialogSettings? editDialogSettings,
  DialogSettings? verifyDialogSettings,
  void Function(ValueItem<int>?)? updateSelectedItem,
  ValueItem<int>? initial,
}) => SearchDropDownController<int>(
  items: items,
  addMode: addMode,
  newValueItem: newValueItem ?? _newItem,
  onAddItem: onAddItem ?? (_) {},
  deleteMode: deleteMode,
  onDeleteItem: onDeleteItem,
  confirmDelete: confirmDelete,
  deleteDialogSettings: deleteDialogSettings,
  editMode: editMode,
  onEditItem: onEditItem,
  editDialogSettings: editDialogSettings,
  verifyInputItem: verifyInputItem,
  verifyDialogSettings: verifyDialogSettings,
  updateSelectedItem: updateSelectedItem,
  initialSelectedItem: initial,
);

Future<void> _pump(
  WidgetTester tester,
  SearchDropDownController<int> controller, {
  SimpleOverlaySettings? overlay,
  Widget? addAdditionalWidget,
}) => tester.pumpWidget(
  host(
    SearchDropDown<int>(
      controller: controller,
      overlayListSettings: overlay ?? _tall,
      addAdditionalWidget: addAdditionalWidget,
    ),
  ),
);

/// Pumps enough frames for a dialog route transition, without settling.
Future<void> _frames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Finder _spinnerIn(String label) =>
    inRow<int>(label, find.byType(CircularProgressIndicator));

Finder _inAddRow(Finder matching) =>
    find.descendant(of: find.byType(DefaultAddListItem), matching: matching);

/// Whether [target] sits under a `Visibility(visible: false)`.
bool _hidden(Finder target) => find
    .ancestor(
      of: target,
      matching: find.byWidgetPredicate((w) => w is Visibility && !w.visible),
    )
    .evaluate()
    .isNotEmpty;

Finder _inDialog(Finder matching) =>
    find.descendant(of: find.byType(AlertDialog), matching: matching);

Finder _inEditDialog(Finder matching) =>
    find.descendant(of: find.byType(EditDialog), matching: matching);

TextField _editField(WidgetTester tester) =>
    tester.widget<TextField>(_inEditDialog(find.byType(TextField)));

Future<void> _tapCreate(WidgetTester tester) async {
  await tester.tap(_inAddRow(find.byType(TextButton)));
  await tester.pump();
}

Future<void> _tapDelete(WidgetTester tester, String label) async {
  await tester.tap(inRow<int>(label, find.byIcon(Icons.delete)));
  await _frames(tester);
}

Future<void> _tapEdit(WidgetTester tester, String label) async {
  await tester.tap(inRow<int>(label, find.byIcon(Icons.edit)));
  await _frames(tester);
}

Future<void> _submitEdit(WidgetTester tester, String text) async {
  await tester.enterText(_inEditDialog(find.byType(TextField)), text);
  await tester.tap(_inDialog(find.text('Editar')));
  await tester.pumpAndSettle();
}

const ValueItem<int> _banana = ValueItem(label: 'Banana', value: 2);
const ValueItem<int> _uva = ValueItem(label: 'Uva', value: 3);

void main() {
  group('add: add-item row visibility', () {
    testWidgets('hidden while the query is empty', (tester) async {
      await _pump(tester, _ctrl(fruitItems(), addMode: true));
      await openSingle(tester);

      expect(find.byType(DefaultAddListItem), findsNothing);
      expect(visualRowLabels<int>(tester), hasLength(5));
    });

    testWidgets('hidden when the query matches at least one item', (
      tester,
    ) async {
      await _pump(tester, _ctrl(fruitItems(), addMode: true));
      await openSingle(tester);
      await typeInSingle(tester, 'Ban');

      expect(find.byType(DefaultAddListItem), findsNothing);
      expect(visualRowLabels<int>(tester), <String>['Banana']);
    });

    testWidgets(
      'shown as the only row, with the typed text and the default "Criar" '
      'button, when nothing matches',
      (tester) async {
        await _pump(tester, _ctrl(fruitItems(), addMode: true));
        await openSingle(tester);
        await typeInSingle(tester, 'Kiwi');

        expect(find.byType(DefaultListTile<int>), findsNothing);
        expect(find.byType(DefaultAddListItem), findsOneWidget);
        expect(_inAddRow(find.text('Kiwi')), findsOneWidget);
        expect(
          _inAddRow(find.widgetWithText(TextButton, 'Criar')),
          findsOneWidget,
        );
      },
    );

    testWidgets('hidden when addMode is false even if nothing matches', (
      tester,
    ) async {
      await _pump(tester, _ctrl(fruitItems()));
      await openSingle(tester);
      await typeInSingle(tester, 'Kiwi');

      expect(find.byType(DefaultAddListItem), findsNothing);
      expect(find.byType(DefaultListTile<int>), findsNothing);
    });

    testWidgets('overlay addItemHint replaces the "Criar" label', (
      tester,
    ) async {
      await _pump(
        tester,
        _ctrl(fruitItems(), addMode: true),
        overlay: const SimpleOverlaySettings(
          dialogHeight: 400,
          addItemHint: 'Add',
        ),
      );
      await openSingle(tester);
      await typeInSingle(tester, 'Kiwi');

      expect(_inAddRow(find.text('Add')), findsOneWidget);
      expect(find.text('Criar'), findsNothing);
    });

    testWidgets('addAdditionalWidget is rendered inside the add row', (
      tester,
    ) async {
      await _pump(
        tester,
        _ctrl(fruitItems(), addMode: true),
        addAdditionalWidget: const Text('extra'),
      );
      await openSingle(tester);
      await typeInSingle(tester, 'Kiwi');

      expect(_inAddRow(find.text('extra')), findsOneWidget);
    });
  });

  group('add: create a new item', () {
    testWidgets(
      'tapping Criar calls newValueItem(text) and onAddItem(newItem), then '
      'selects the new item and closes the view',
      (tester) async {
        final List<String> inputs = <String>[];
        final List<ValueItem<int>> added = <ValueItem<int>>[];
        final List<ValueItem<int>?> selections = <ValueItem<int>?>[];
        final SearchDropDownController<int> c = _ctrl(
          fruitItems(),
          addMode: true,
          newValueItem: (s) {
            inputs.add(s);
            return _newItem(s);
          },
          onAddItem: added.add,
          updateSelectedItem: selections.add,
        );
        await _pump(tester, c);
        await openSingle(tester);
        await typeInSingle(tester, 'Kiwi');

        await _tapCreate(tester);
        await tester.pumpAndSettle();

        expect(inputs, <String>['Kiwi']);
        expect(added, <ValueItem<int>>[_newItem('Kiwi')]);
        expect(c.selectedItem, same(added.single));
        expect(selections, <ValueItem<int>?>[added.single]);
        expect(c.localSearchController.isOpen, isFalse);
        expect(c.localSearchController.text, 'Kiwi');
      },
    );

    testWidgets(
      'async onAddItem: a spinner replaces the button while awaiting, the '
      'item is selected once it completes',
      (tester) async {
        final List<ValueItem<int>> added = <ValueItem<int>>[];
        final SearchDropDownController<int> c = _ctrl(
          fruitItems(),
          addMode: true,
          onAddItem: (item) async {
            await Future<void>.delayed(const Duration(seconds: 1));
            added.add(item);
          },
        );
        await _pump(tester, c);
        await openSingle(tester);
        await typeInSingle(tester, 'Kiwi');

        await _tapCreate(tester);

        expect(
          _inAddRow(find.byType(CircularProgressIndicator)),
          findsOneWidget,
        );
        // Hidden behind the spinner, keeping its place (8.0.1).
        expect(find.text('Criar').hitTestable(), findsNothing);
        expect(c.selectedItem, isNull);
        expect(c.localSearchController.isOpen, isTrue);

        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        expect(added, <ValueItem<int>>[_newItem('Kiwi')]);
        expect(c.selectedItem, _newItem('Kiwi'));
        expect(c.localSearchController.isOpen, isFalse);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      },
    );

    testWidgets(
      'with an onAddItem that appends to the caller list, reopening lists '
      'the new item',
      (tester) async {
        final List<ValueItem<int>> items = fruitItems();
        final SearchDropDownController<int> c = _ctrl(
          items,
          addMode: true,
          onAddItem: items.add,
        );
        await _pump(tester, c);
        await openSingle(tester);
        await typeInSingle(tester, 'Kiwi');
        await _tapCreate(tester);
        await tester.pumpAndSettle();

        await openSingle(tester);

        expect(items.last, _newItem('Kiwi'));
        // D1 (8.0): reopening lists every item, scrolled to the selection.
        expect(visualRowLabels<int>(tester), contains('Kiwi'));
        expect(c.filteredItems.last, _newItem('Kiwi'));
      },
    );

    testWidgets(
      'a passing verifyInputItem receives the new item; it is added',
      (tester) async {
        final List<ValueItem<int>> verified = <ValueItem<int>>[];
        final List<ValueItem<int>> added = <ValueItem<int>>[];
        final SearchDropDownController<int> c = _ctrl(
          fruitItems(),
          addMode: true,
          onAddItem: added.add,
          verifyInputItem: (item) {
            verified.add(item);
            return true;
          },
        );
        await _pump(tester, c);
        await openSingle(tester);
        await typeInSingle(tester, 'Kiwi');
        await _tapCreate(tester);
        await tester.pumpAndSettle();

        expect(verified, <ValueItem<int>>[_newItem('Kiwi')]);
        expect(added, <ValueItem<int>>[_newItem('Kiwi')]);
        expect(find.byType(AlertDialog), findsNothing);
      },
    );
  });

  group('add: verifyInputItem rejection dialog', () {
    SearchDropDownController<int> rejecting(
      List<ValueItem<int>> added,
      List<ValueItem<int>?> selections,
    ) => _ctrl(
      fruitItems(),
      addMode: true,
      onAddItem: added.add,
      updateSelectedItem: selections.add,
      verifyInputItem: (item) => item.label != 'name',
    );

    testWidgets(
      'rejected input shows the "Erro!" dialog with the default message and '
      'a single OK button',
      (tester) async {
        await _pump(tester, rejecting(<ValueItem<int>>[], <ValueItem<int>?>[]));
        await openSingle(tester);
        await typeInSingle(tester, 'name');
        await _tapCreate(tester);
        await _frames(tester);

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(_inDialog(find.text('Erro!')), findsOneWidget);
        expect(
          _inDialog(find.text('O valor adicionado não é válido.')),
          findsOneWidget,
        );
        expect(_inDialog(find.byType(TextButton)), findsOneWidget);
        expect(
          _inDialog(find.widgetWithText(TextButton, 'OK')),
          findsOneWidget,
        );
        expect(find.text('Cancelar'), findsNothing);
      },
    );

    testWidgets(
      'OK closes the dialog; the item is not added, nothing is selected and '
      'the text is cleared',
      (tester) async {
        final List<ValueItem<int>> added = <ValueItem<int>>[];
        final List<ValueItem<int>?> selections = <ValueItem<int>?>[];
        final SearchDropDownController<int> c = rejecting(added, selections);
        await _pump(tester, c);
        await openSingle(tester);
        await typeInSingle(tester, 'name');
        await _tapCreate(tester);
        await _frames(tester);

        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
        expect(added, isEmpty);
        expect(selections, isEmpty);
        expect(c.selectedItem, isNull);
        expect(c.localSearchController.text, '');
        expect(c.localSearchController.isOpen, isTrue);
        expect(find.byType(DefaultAddListItem), findsNothing);
        expect(visualRowLabels<int>(tester), hasLength(5));
      },
    );
  });

  group('delete: delete icon', () {
    testWidgets('deleteMode shows a delete IconButton on every row', (
      tester,
    ) async {
      await _pump(
        tester,
        _ctrl(fruitItems(), deleteMode: true, onDeleteItem: (_) {}),
      );
      await openSingle(tester);

      expect(find.widgetWithIcon(IconButton, Icons.delete), findsNWidgets(5));
    });

    testWidgets('deleteMode false shows no delete icon', (tester) async {
      await _pump(tester, _ctrl(fruitItems()));
      await openSingle(tester);

      expect(visualRowLabels<int>(tester), hasLength(5));
      expect(find.byIcon(Icons.delete), findsNothing);
    });

    testWidgets('a custom dialogDeleteIcon replaces the default icon', (
      tester,
    ) async {
      await _pump(
        tester,
        _ctrl(fruitItems(), deleteMode: true, onDeleteItem: (_) {}),
        overlay: const SimpleOverlaySettings(
          dialogHeight: 400,
          dialogDeleteIcon: Icon(Icons.close),
        ),
      );
      await openSingle(tester);

      expect(find.widgetWithIcon(IconButton, Icons.close), findsNWidgets(5));
      expect(find.byIcon(Icons.delete), findsNothing);
    });

    testWidgets('dialogActionWidget replaces the delete IconButton', (
      tester,
    ) async {
      await _pump(
        tester,
        _ctrl(fruitItems(), deleteMode: true, onDeleteItem: (_) {}),
        overlay: const SimpleOverlaySettings(
          dialogHeight: 400,
          dialogActionWidget: Text('action'),
        ),
      );
      await openSingle(tester);

      expect(find.text('action'), findsNWidgets(5));
      expect(inRow<int>('Banana', find.text('action')), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsNothing);
      expect(
        find.descendant(
          of: find.byType(DefaultListTile<int>),
          matching: find.byType(IconButton),
        ),
        findsNothing,
      );
    });
  });

  group('delete: immediate delete (confirmDelete false)', () {
    testWidgets(
      'tapping delete calls onDeleteItem with the row item; a caller-list '
      'mutation removes the row',
      (tester) async {
        final List<ValueItem<int>> items = fruitItems();
        final List<ValueItem<int>> deleted = <ValueItem<int>>[];
        await _pump(
          tester,
          _ctrl(
            items,
            deleteMode: true,
            onDeleteItem: (item) {
              deleted.add(item);
              items.remove(item);
            },
          ),
        );
        await openSingle(tester);

        await _tapDelete(tester, 'Banana');
        await tester.pumpAndSettle();

        expect(deleted, <ValueItem<int>>[_banana]);
        expect(find.byType(AlertDialog), findsNothing);
        expect(visualRowLabels<int>(tester), <String>[
          'Maçã',
          'Uva',
          'abacaxi',
          'Pêra',
        ]);
      },
    );

    testWidgets(
      'deleting resets the selection: selectedItem null, text cleared, '
      'updateSelectedItem(null)',
      (tester) async {
        final List<ValueItem<int>> items = fruitItems();
        final List<ValueItem<int>?> selections = <ValueItem<int>?>[];
        final SearchDropDownController<int> c = _ctrl(
          items,
          deleteMode: true,
          onDeleteItem: items.remove,
          updateSelectedItem: selections.add,
          initial: _uva,
        );
        await _pump(tester, c);
        await openSingle(tester);
        expect(visualRowLabels<int>(tester), contains('Uva'));

        await _tapDelete(tester, 'Uva');
        await tester.pumpAndSettle();

        expect(c.selectedItem, isNull);
        expect(c.localSearchController.text, '');
        expect(selections, <ValueItem<int>?>[null]);
        expect(c.localSearchController.isOpen, isTrue);
        expect(visualRowLabels<int>(tester), <String>[
          'Maçã',
          'Banana',
          'abacaxi',
          'Pêra',
        ]);
      },
    );

    testWidgets('async onDeleteItem shows a row spinner while awaiting', (
      tester,
    ) async {
      final List<ValueItem<int>> items = fruitItems();
      await _pump(
        tester,
        _ctrl(
          items,
          deleteMode: true,
          onDeleteItem: (item) async {
            await Future<void>.delayed(const Duration(seconds: 1));
            items.remove(item);
          },
        ),
      );
      await openSingle(tester);

      await tester.tap(inRow<int>('Banana', find.byIcon(Icons.delete)));
      await tester.pump();

      expect(_spinnerIn('Banana'), findsOneWidget);
      // Hidden behind the spinner, keeping its place (8.0.1).
      expect(
        inRow<int>('Banana', find.byIcon(Icons.delete)).hitTestable(),
        findsNothing,
      );
      expect(find.byIcon(Icons.delete).hitTestable(), findsNWidgets(4));

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(rowTile<int>('Banana'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    group('B1', () {
      testWidgets(
        'B1: an onDeleteItem that leaves the list untouched does not crash; '
        'the deleted item is gone from the results',
        (tester) async {
          final List<ValueItem<int>> deleted = <ValueItem<int>>[];
          await _pump(
            tester,
            _ctrl(fruitItems(), deleteMode: true, onDeleteItem: deleted.add),
          );
          await openSingle(tester);

          await _tapDelete(tester, 'Banana');
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'while deleting');
          await typeInSingle(tester, 'an');
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(deleted, <ValueItem<int>>[_banana]);
          expect(visualRowLabels<int>(tester), isNot(contains('Banana')));
        },
      );
    }); // B1: fixed in 8.0
  });

  group('delete: confirmDelete dialog', () {
    SearchDropDownController<int> confirming(
      List<ValueItem<int>> items,
      List<ValueItem<int>> deleted,
    ) => _ctrl(
      items,
      deleteMode: true,
      confirmDelete: true,
      onDeleteItem: (item) {
        deleted.add(item);
        items.remove(item);
      },
    );

    testWidgets(
      'tapping delete opens "Apagar item?" naming the item, with the default '
      'content and Cancelar / Apagar, without deleting yet',
      (tester) async {
        final List<ValueItem<int>> deleted = <ValueItem<int>>[];
        await _pump(tester, confirming(fruitItems(), deleted));
        await openSingle(tester);

        await _tapDelete(tester, 'Banana');

        expect(_inDialog(find.text('Apagar item?')), findsOneWidget);
        expect(
          _inDialog(find.text('“Banana” será apagado.', findRichText: true)),
          findsOneWidget,
        );
        expect(
          _inDialog(find.text('Essa ação não poderá ser desfeita.')),
          findsOneWidget,
        );
        expect(
          _inDialog(find.widgetWithText(TextButton, 'Cancelar')),
          findsOneWidget,
        );
        expect(
          _inDialog(find.widgetWithText(TextButton, 'Apagar')),
          findsOneWidget,
        );
        expect(deleted, isEmpty);
        expect(rowTile<int>('Banana'), findsOneWidget);
      },
    );

    testWidgets('Apagar deletes the item and closes the dialog', (
      tester,
    ) async {
      final List<ValueItem<int>> items = fruitItems();
      final List<ValueItem<int>> deleted = <ValueItem<int>>[];
      await _pump(tester, confirming(items, deleted));
      await openSingle(tester);
      await _tapDelete(tester, 'Banana');

      await tester.tap(find.text('Apagar'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(deleted, <ValueItem<int>>[_banana]);
      expect(items, isNot(contains(_banana)));
      expect(rowTile<int>('Banana'), findsNothing);
    });

    testWidgets('Cancelar closes the dialog and keeps the item', (
      tester,
    ) async {
      final List<ValueItem<int>> items = fruitItems();
      final List<ValueItem<int>> deleted = <ValueItem<int>>[];
      await _pump(tester, confirming(items, deleted));
      await openSingle(tester);
      await _tapDelete(tester, 'Banana');

      await tester.tap(find.text('Cancelar'));
      await _frames(tester);

      expect(find.byType(AlertDialog), findsNothing);
      expect(deleted, isEmpty);
      expect(items, contains(_banana));
      expect(rowTile<int>('Banana'), findsOneWidget);
    });

    group('B5', () {
      testWidgets(
        'B5: after Cancelar the row spinner disappears and the delete icon '
        'returns',
        (tester) async {
          await _pump(tester, confirming(fruitItems(), <ValueItem<int>>[]));
          await openSingle(tester);
          await _tapDelete(tester, 'Banana');

          await tester.tap(find.text('Cancelar'));
          await _frames(tester);

          expect(_spinnerIn('Banana'), findsNothing);
          expect(
            inRow<int>('Banana', find.byIcon(Icons.delete)),
            findsOneWidget,
          );
        },
      );
    }); // B5: fixed in 8.0
  });

  group('edit: edit icon', () {
    testWidgets(
      'editMode shows an edit IconButton on every row, before the delete '
      'icon',
      (tester) async {
        await _pump(
          tester,
          _ctrl(
            fruitItems(),
            editMode: true,
            onEditItem: (_, _) {},
            deleteMode: true,
            onDeleteItem: (_) {},
          ),
        );
        await openSingle(tester);

        expect(find.widgetWithIcon(IconButton, Icons.edit), findsNWidgets(5));
        expect(find.widgetWithIcon(IconButton, Icons.delete), findsNWidgets(5));
        expect(
          tester.getCenter(inRow<int>('Banana', find.byIcon(Icons.edit))).dx,
          lessThan(
            tester
                .getCenter(inRow<int>('Banana', find.byIcon(Icons.delete)))
                .dx,
          ),
        );
      },
    );

    testWidgets('no edit icon when editMode is false (the default)', (
      tester,
    ) async {
      await _pump(tester, _ctrl(fruitItems()));
      await openSingle(tester);

      expect(find.byIcon(Icons.edit), findsNothing);
    });

    testWidgets('a custom dialogEditIcon replaces the default icon', (
      tester,
    ) async {
      await _pump(
        tester,
        _ctrl(fruitItems(), editMode: true, onEditItem: (_, _) {}),
        overlay: const SimpleOverlaySettings(
          dialogHeight: 400,
          dialogEditIcon: Icon(Icons.create),
        ),
      );
      await openSingle(tester);

      expect(find.widgetWithIcon(IconButton, Icons.create), findsNWidgets(5));
      expect(find.byIcon(Icons.edit), findsNothing);
    });
  });

  group('edit: EditDialog', () {
    // An onEditItem that replaces the original in the caller list.
    SearchDropDownController<int> editing(
      List<ValueItem<int>> items,
      List<List<ValueItem<int>>> edits, {
      List<String>? inputs,
      List<ValueItem<int>?>? selections,
      ValueItem<int>? initial,
    }) => _ctrl(
      items,
      editMode: true,
      newValueItem: (s) {
        inputs?.add(s);
        return _newItem(s);
      },
      onEditItem: (original, newValue) {
        edits.add(<ValueItem<int>>[original, newValue]);
        items[items.indexOf(original)] = newValue;
      },
      updateSelectedItem: selections?.add,
      initial: initial,
    );

    testWidgets(
      'tapping edit opens the dialog with "Editar item", the field prefilled '
      'with the item label, the "Novo valor" label and Cancelar / Editar',
      (tester) async {
        await _pump(tester, editing(fruitItems(), <List<ValueItem<int>>>[]));
        await openSingle(tester);

        await _tapEdit(tester, 'Banana');

        expect(find.byType(EditDialog), findsOneWidget);
        expect(_inEditDialog(find.text('Editar item')), findsOneWidget);
        // Only the field, prefilled (B2), shows the label: no line above it
        // (8.0.1), and the field label is not repeated as a hint.
        expect(_inEditDialog(find.text('Banana')), findsOneWidget);
        expect(_editField(tester).controller?.text, 'Banana');
        expect(_editField(tester).decoration?.hintText, isNull);
        expect(_editField(tester).decoration?.labelText, 'Novo valor');
        expect(
          _inEditDialog(find.widgetWithText(TextButton, 'Cancelar')),
          findsOneWidget,
        );
        expect(
          _inEditDialog(find.widgetWithText(TextButton, 'Editar')),
          findsOneWidget,
        );
      },
    );

    testWidgets('Editar with text calls newValueItem(text) and '
        'onEditItem(original, newValue), then closes the dialog', (
      tester,
    ) async {
      final List<ValueItem<int>> items = fruitItems();
      final List<List<ValueItem<int>>> edits = <List<ValueItem<int>>>[];
      final List<String> inputs = <String>[];
      await _pump(tester, editing(items, edits, inputs: inputs));
      await openSingle(tester);
      await _tapEdit(tester, 'Banana');

      await _submitEdit(tester, 'Banana2');

      expect(inputs, <String>['Banana2']);
      expect(edits, <List<ValueItem<int>>>[
        <ValueItem<int>>[_banana, _newItem('Banana2')],
      ]);
      expect(items[1], _newItem('Banana2'));
      expect(find.byType(EditDialog), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('Editar with empty text does nothing', (tester) async {
      final List<List<ValueItem<int>>> edits = <List<ValueItem<int>>>[];
      final List<String> inputs = <String>[];
      await _pump(tester, editing(fruitItems(), edits, inputs: inputs));
      await openSingle(tester);
      await _tapEdit(tester, 'Banana');
      // The field starts prefilled (B2); empty it first.
      await tester.enterText(
        find.descendant(
          of: find.byType(EditDialog),
          matching: find.byType(TextField),
        ),
        '',
      );

      await tester.tap(_inDialog(find.text('Editar')));
      await _frames(tester);

      expect(find.byType(EditDialog), findsOneWidget);
      expect(edits, isEmpty);
      expect(inputs, isEmpty);
    });

    testWidgets('Cancelar closes the dialog without calling onEditItem', (
      tester,
    ) async {
      final List<List<ValueItem<int>>> edits = <List<ValueItem<int>>>[];
      final List<String> inputs = <String>[];
      await _pump(tester, editing(fruitItems(), edits, inputs: inputs));
      await openSingle(tester);
      await _tapEdit(tester, 'Banana');
      await tester.enterText(
        _inEditDialog(find.byType(TextField)),
        'Discarded',
      );

      await tester.tap(_inDialog(find.text('Cancelar')));
      await tester.pumpAndSettle();

      expect(find.byType(EditDialog), findsNothing);
      expect(edits, isEmpty);
      expect(inputs, isEmpty);
      expect(visualRowLabels<int>(tester), contains('Banana'));
    });

    testWidgets(
      'the row shows a spinner while the dialog is open; the edit icon '
      'returns after closing',
      (tester) async {
        await _pump(tester, editing(fruitItems(), <List<ValueItem<int>>>[]));
        await openSingle(tester);
        await _tapEdit(tester, 'Banana');

        expect(_spinnerIn('Banana'), findsOneWidget);
        // Hidden behind the spinner, keeping its place (8.0.1); the dialog
        // barrier would hide it from hit tests anyway, so read the flag.
        expect(_hidden(inRow<int>('Banana', find.byIcon(Icons.edit))), isTrue);

        await tester.tap(_inDialog(find.text('Cancelar')));
        await tester.pumpAndSettle();

        expect(_spinnerIn('Banana'), findsNothing);
        expect(_hidden(inRow<int>('Banana', find.byIcon(Icons.edit))), isFalse);
        expect(
          inRow<int>('Banana', find.byIcon(Icons.edit)).hitTestable(),
          findsOneWidget,
        );
      },
    );

    group('B2', () {
      testWidgets(
        'B2: after editing with a list-agnostic onEditItem, typing does not '
        'crash and shows the new label',
        (tester) async {
          final List<List<ValueItem<int>>> edits = <List<ValueItem<int>>>[];
          await _pump(
            tester,
            _ctrl(
              fruitItems(),
              editMode: true,
              onEditItem: (original, newValue) =>
                  edits.add(<ValueItem<int>>[original, newValue]),
            ),
          );
          await openSingle(tester);
          await _tapEdit(tester, 'Banana');
          await _submitEdit(tester, 'Banana2');
          expect(tester.takeException(), isNull, reason: 'while editing');

          await typeInSingle(tester, 'Ban');
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(edits, hasLength(1));
          expect(visualRowLabels<int>(tester), <String>['Banana2']);
        },
      );

      testWidgets(
        'B2: after editing with an onEditItem that updates the caller list, '
        'typing does not crash and shows the new label',
        (tester) async {
          await _pump(tester, editing(fruitItems(), <List<ValueItem<int>>>[]));
          await openSingle(tester);
          await _tapEdit(tester, 'Banana');
          await _submitEdit(tester, 'Banana2');
          expect(tester.takeException(), isNull, reason: 'while editing');

          await typeInSingle(tester, 'Ban');
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(visualRowLabels<int>(tester), <String>['Banana2']);
        },
      );

      testWidgets('B2: the EditDialog field is prefilled with the old label', (
        tester,
      ) async {
        await _pump(tester, editing(fruitItems(), <List<ValueItem<int>>>[]));
        await openSingle(tester);

        await _tapEdit(tester, 'Banana');

        expect(_editField(tester).controller?.text, 'Banana');
      });

      testWidgets('B2: editing an item that is not selected keeps the current '
          'selection', (tester) async {
        const ValueItem<int> ana = ValueItem(label: 'Ana', value: 1);
        final List<ValueItem<int>> items = <ValueItem<int>>[ana, _banana, _uva];
        final List<ValueItem<int>?> selections = <ValueItem<int>?>[];
        final SearchDropDownController<int> c = editing(
          items,
          <List<ValueItem<int>>>[],
          selections: selections,
          initial: ana,
        );
        await _pump(tester, c);
        await openSingle(tester);
        // D1 (8.0): the view lists every item.
        expect(visualRowLabels<int>(tester), <String>['Ana', 'Banana', 'Uva']);

        await _tapEdit(tester, 'Banana');
        await _submitEdit(tester, 'Banana2');

        expect(c.selectedItem, ana);
        expect(selections, isEmpty);
        expect(c.localSearchController.text, 'Ana');
      });
    }); // B2: fixed in 8.0
  });

  group('controller: add/delete/edit mode asserts', () {
    Matcher assertion(String message) => throwsA(
      isA<AssertionError>().having(
        (e) => e.message,
        'message',
        contains(message),
      ),
    );

    test('addMode (default true) without newValueItem throws', () {
      expect(
        () => SearchDropDownController<int>(
          items: <ValueItem<int>>[],
          onAddItem: (_) {},
          deleteMode: false,
        ),
        assertion('addMode can only be used with newValueItem != null'),
      );
    });

    test('addMode (default true) without onAddItem throws', () {
      expect(
        () => SearchDropDownController<int>(
          items: <ValueItem<int>>[],
          newValueItem: _newItem,
          deleteMode: false,
        ),
        assertion('onAddItem != null'),
      );
    });

    test('deleteMode (default true) without onDeleteItem throws', () {
      expect(
        () => SearchDropDownController<int>(
          items: <ValueItem<int>>[],
          addMode: false,
        ),
        assertion('deleteMode can only be used with onDeleteItem != null'),
      );
    });

    test('editMode without onEditItem throws', () {
      expect(
        () => SearchDropDownController<int>(
          items: <ValueItem<int>>[],
          addMode: false,
          deleteMode: false,
          editMode: true,
          newValueItem: _newItem,
        ),
        assertion('editMode can only be used with onEditItem != null'),
      );
    });

    test('editMode without newValueItem throws', () {
      expect(
        () => SearchDropDownController<int>(
          items: <ValueItem<int>>[],
          addMode: false,
          deleteMode: false,
          editMode: true,
          onEditItem: (_, _) {},
        ),
        assertion('newValueItem != null'),
      );
    });

    test('all modes off needs no callbacks', () {
      final SearchDropDownController<int> c = SearchDropDownController<int>(
        items: <ValueItem<int>>[],
        addMode: false,
        deleteMode: false,
      );
      expect(c.addMode, isFalse);
      expect(c.deleteMode, isFalse);
      expect(c.editMode, isFalse);
      c.dispose();
    });

    test('all modes on with their callbacks constructs', () {
      final SearchDropDownController<int> c = SearchDropDownController<int>(
        items: <ValueItem<int>>[],
        newValueItem: _newItem,
        onAddItem: (_) {},
        onDeleteItem: (_) {},
        editMode: true,
        onEditItem: (_, _) {},
      );
      expect(c.addMode, isTrue);
      expect(c.deleteMode, isTrue);
      expect(c.editMode, isTrue);
      expect(c.confirmDelete, isFalse);
      c.dispose();
    });
  });

  group('dialogs: DialogSettings customisation', () {
    testWidgets(
      'deleteDialogSettings: custom title, content and button texts; the '
      'custom delete button deletes',
      (tester) async {
        final List<ValueItem<int>> deleted = <ValueItem<int>>[];
        final List<ValueItem<int>> items = fruitItems();
        await _pump(
          tester,
          _ctrl(
            items,
            deleteMode: true,
            confirmDelete: true,
            onDeleteItem: (item) {
              deleted.add(item);
              items.remove(item);
            },
            deleteDialogSettings: const DialogSettings(
              title: Text('Remove?'),
              content: Text('Gone forever'),
              customCancelButtonSettings: DialogButtonSettings('Keep'),
              customDeleteButtonSettings: DialogButtonSettings('Remove'),
            ),
          ),
        );
        await openSingle(tester);
        await _tapDelete(tester, 'Banana');

        expect(_inDialog(find.text('Remove?')), findsOneWidget);
        expect(_inDialog(find.text('Gone forever')), findsOneWidget);
        expect(
          _inDialog(find.widgetWithText(TextButton, 'Keep')),
          findsOneWidget,
        );
        expect(
          _inDialog(find.widgetWithText(TextButton, 'Remove')),
          findsOneWidget,
        );
        expect(find.text('Apagar item?'), findsNothing);
        expect(find.text('Tem certeza?'), findsNothing);
        expect(find.text('Essa ação não poderá ser desfeita.'), findsNothing);
        expect(find.text('Cancelar'), findsNothing);
        expect(find.text('Apagar'), findsNothing);

        await tester.tap(find.text('Remove'));
        await tester.pumpAndSettle();

        expect(deleted, <ValueItem<int>>[_banana]);
        expect(find.byType(AlertDialog), findsNothing);
      },
    );

    testWidgets(
      'verifyDialogSettings: custom title, content and OK text; the custom '
      'button closes the dialog',
      (tester) async {
        await _pump(
          tester,
          _ctrl(
            fruitItems(),
            addMode: true,
            verifyInputItem: (_) => false,
            verifyDialogSettings: const DialogSettings(
              title: Text('Invalid'),
              content: Text('Try again'),
              customOkButtonSettings: DialogButtonSettings('Got it'),
            ),
          ),
        );
        await openSingle(tester);
        await typeInSingle(tester, 'Kiwi');
        await _tapCreate(tester);
        await _frames(tester);

        expect(_inDialog(find.text('Invalid')), findsOneWidget);
        expect(_inDialog(find.text('Try again')), findsOneWidget);
        expect(
          _inDialog(find.widgetWithText(TextButton, 'Got it')),
          findsOneWidget,
        );
        expect(find.text('Erro!'), findsNothing);
        expect(find.text('OK'), findsNothing);

        await tester.tap(find.text('Got it'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
      },
    );

    testWidgets(
      'editDialogSettings: custom title, editHint and button texts; the '
      'custom edit button submits',
      (tester) async {
        final List<List<ValueItem<int>>> edits = <List<ValueItem<int>>>[];
        await _pump(
          tester,
          _ctrl(
            fruitItems(),
            editMode: true,
            onEditItem: (original, newValue) =>
                edits.add(<ValueItem<int>>[original, newValue]),
            editDialogSettings: const DialogSettings(
              title: Text('Rename'),
              editHint: 'New name',
              customCancelButtonSettings: DialogButtonSettings('Back'),
              customEditButtonSettings: DialogButtonSettings('Save'),
            ),
          ),
        );
        await openSingle(tester);
        await _tapEdit(tester, 'Banana');

        expect(_inEditDialog(find.text('Rename')), findsOneWidget);
        expect(find.text('Editar item'), findsNothing);
        // The field prefilled with the label (B2), shown once (8.0.1).
        expect(_inEditDialog(find.text('Banana')), findsOneWidget);
        expect(_editField(tester).controller?.text, 'Banana');
        expect(_editField(tester).decoration?.labelText, 'New name');
        expect(
          _inEditDialog(find.widgetWithText(TextButton, 'Back')),
          findsOneWidget,
        );
        expect(
          _inEditDialog(find.widgetWithText(TextButton, 'Save')),
          findsOneWidget,
        );
        expect(find.text('Cancelar'), findsNothing);
        expect(find.text('Editar'), findsNothing);

        await tester.enterText(_inEditDialog(find.byType(TextField)), 'Kiwi');
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(edits, <List<ValueItem<int>>>[
          <ValueItem<int>>[_banana, _newItem('Kiwi')],
        ]);
        expect(find.byType(EditDialog), findsNothing);
      },
    );

    testWidgets(
      'editDialogSettings.content replaces the label and the input field',
      (tester) async {
        await _pump(
          tester,
          _ctrl(
            fruitItems(),
            editMode: true,
            onEditItem: (_, _) {},
            editDialogSettings: const DialogSettings(content: Text('custom')),
          ),
        );
        await openSingle(tester);
        await _tapEdit(tester, 'Banana');

        expect(_inEditDialog(find.text('custom')), findsOneWidget);
        expect(_inEditDialog(find.text('Banana')), findsNothing);
        expect(_inEditDialog(find.byType(TextField)), findsNothing);
        expect(_inEditDialog(find.text('Editar item')), findsOneWidget);
      },
    );
  });
}
