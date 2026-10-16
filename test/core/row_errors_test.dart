import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

import '../support/harness.dart';

/// Runs [body] while collecting what is sent to [FlutterError.onError].
Future<List<FlutterErrorDetails>> _reported(
  Future<void> Function() body,
) async {
  final List<FlutterErrorDetails> errors = <FlutterErrorDetails>[];
  final previous = FlutterError.onError;
  FlutterError.onError = errors.add;
  try {
    await body();
  } finally {
    FlutterError.onError = previous;
  }
  return errors;
}

void _expectOneReport(List<FlutterErrorDetails> errors) {
  expect(errors, hasLength(1));
  expect(errors.single.exception, isA<StateError>());
  expect(errors.single.library, 'simple_search_dropdown');
  expect(errors.single.stack, isNotNull);
}

const ValueItem<int> _apple = ValueItem(label: 'Apple', value: 1);

final Map<String, Future<void> Function(Object?)> _throwers =
    <String, Future<void> Function(Object?)>{
      'sync': (_) => throw StateError('offline'),
      'async': (_) async => throw StateError('offline'),
    };

void main() {
  group('a throwing row callback is reported and the row recovers (F8)', () {
    for (final MapEntry<String, Future<void> Function(Object?)> t
        in _throwers.entries) {
      for (final String action in <String>['delete', 'edit']) {
        testWidgets('${t.key} $action on DefaultListTile', (tester) async {
          await tester.pumpWidget(
            host(
              DefaultListTile<int>(
                deleteMode: true,
                editMode: true,
                item: _apple,
                onDelete: action == 'delete' ? t.value : (_) {},
                onEdit: action == 'edit' ? t.value : (_) {},
                onPressed: (_) {},
                overlayListSettings: defaultOverlaySettings,
                selected: false,
              ),
            ),
          );
          final errors = await _reported(() async {
            await tester.tap(
              find.byIcon(action == 'delete' ? Icons.delete : Icons.edit),
            );
            await tester.pump();
            await tester.pump();
          });
          _expectOneReport(errors);
          expect(find.byType(Loading), findsNothing);
          expect(find.byIcon(Icons.delete), findsOneWidget);
          expect(find.byIcon(Icons.edit), findsOneWidget);
        });
      }

      testWidgets('${t.key} add on DefaultAddListItem', (tester) async {
        await tester.pumpWidget(
          host(
            DefaultAddListItem(
              text: 'Kiwi',
              overlayListSettings: defaultOverlaySettings,
              itemAdded: t.value,
            ),
          ),
        );
        final errors = await _reported(() async {
          await tester.tap(find.text('Criar'));
          await tester.pump();
          await tester.pump();
        });
        _expectOneReport(errors);
        expect(find.byType(Loading), findsNothing);
        expect(find.text('Criar'), findsOneWidget);
      });
    }
  });

  group('a throwing CRUD callback leaves the list as it was (F8)', () {
    testWidgets('single: delete, edit and add', (tester) async {
      final List<ValueItem<int>> items = fruitItems();
      final c = SearchDropDownController<int>(
        listItems: items,
        editMode: true,
        onAddItem: (_) async => throw StateError('offline'),
        onDeleteItem: (_) async => throw StateError('offline'),
        onEditItem: (_, _) async => throw StateError('offline'),
        newValueItem: (s) => ValueItem<int>(label: s, value: 99),
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(host(SearchDropDown<int>(controller: c)));
      await openSingle(tester);

      final errors = await _reported(() async {
        await tester.tap(find.byIcon(Icons.delete).first);
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.edit).first);
        // The row spinner runs while the dialog is open: no settle.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.enterText(find.byType(TextField).last, 'Kiwi');
        await tester.tap(find.text('Editar'));
        await tester.pumpAndSettle();
        await typeInSingle(tester, 'Figo');
        await tester.tap(find.text('Criar'));
        await tester.pumpAndSettle();
      });
      expect(errors, hasLength(3));
      expect(items, unorderedEquals(fruitItems()));
      expect(c.selectedItem, isNull);
      expect(find.byType(Loading), findsNothing);
    });

    testWidgets('multiple: delete, edit and add', (tester) async {
      final List<ValueItem<int>> items = fruitItems();
      final List<ValueItem<int>> selected = <ValueItem<int>>[items.first];
      final c = MultipleSearchDropDownController<int>(
        listItems: items,
        selectedItems: selected,
        editMode: true,
        onAddItem: (_) async => throw StateError('offline'),
        onDeleteItem: (_) async => throw StateError('offline'),
        onEditItem: (_, _) async => throw StateError('offline'),
        newValueItem: (s) => ValueItem<int>(label: s, value: 99),
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(host(MultipleSearchDropDown<int>(controller: c)));
      await openMultiple(tester);

      final errors = await _reported(() async {
        await tester.tap(find.byIcon(Icons.delete).first);
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.edit).first);
        // The row spinner runs while the dialog is open: no settle.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.enterText(find.byType(TextField).last, 'Kiwi');
        await tester.tap(find.text('Editar'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).last, 'Figo');
        await tester.pump();
        await tester.tap(find.text('Criar'));
        await tester.pumpAndSettle();
      });
      expect(errors, hasLength(3));
      expect(items, unorderedEquals(fruitItems()));
      expect(selected, <ValueItem<int>>[items.first]);
      expect(find.byType(Loading), findsNothing);
    });
  });
}
