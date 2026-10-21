// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';
import 'package:simple_search_dropdown_example/custom.dart';
import 'package:simple_search_dropdown_example/dialog_test.dart';
import 'package:simple_search_dropdown_example/listitems.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // Follows the system setting: the dropdowns and dialogs take their
      // surfaces from the theme.
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

/// Three dropdowns: a single and a multiple one over a list the app shares
/// between them, and a single one over a custom value type.
///
/// Each controller keeps its own copy of the items. The app owns [items]:
/// the add/edit/delete callbacks of one dropdown update it and hand it to
/// the other dropdown with `updateListItems`.
class _MyHomePageState extends State<MyHomePage> {
  final List<ValueItem> items = List.of(initialItems);

  late final SearchDropDownController singleController;
  late final MultipleSearchDropDownController multipleController;
  late final SearchDropDownController<Custom> customController;

  ValueItem? selectedSingleItem = initialItems[1];
  List<ValueItem> selectedMultipleItems = [];
  ValueItem<Custom>? selectedCustomItem = initialCustomItems.first;

  @override
  void initState() {
    super.initState();

    singleController = SearchDropDownController(
      items: items,
      initialSelectedItem: selectedSingleItem,
      newValueItem: (input) => ValueItem(label: input, value: input),
      // Slow callbacks: the row shows a spinner until they complete.
      onAddItem: (item) async {
        await Future<void>.delayed(const Duration(seconds: 2));
        items.add(item);
        syncMultiple();
      },
      onDeleteItem: (item) async {
        await Future<void>.delayed(const Duration(seconds: 2));
        items.remove(item);
        syncMultiple();
      },
      confirmDelete: true,
      editMode: true,
      onEditItem: (item, edited) {
        replaceItem(item, edited);
        syncMultiple(edited: item, by: edited);
      },
      updateSelectedItem: (item) => selectedSingleItem = item,
      verifyInputItem: (item) => item.label != 'name',
      sort: SortType.selectedFirst,
      enabled: false,
    );

    multipleController = MultipleSearchDropDownController(
      items: items,
      selectedItems: selectedMultipleItems,
      updateSelectedItems: (selected) => selectedMultipleItems = selected,
      newValueItem: (input) => ValueItem(label: input, value: input),
      onAddItem: (item) {
        items.add(item);
        syncSingle();
      },
      onDeleteItem: (item) {
        items.remove(item);
        syncSingle();
      },
      confirmDelete: true,
      editMode: true,
      onEditItem: (item, edited) {
        replaceItem(item, edited);
        syncSingle(edited: item, by: edited);
      },
      onClearList: () => print('clear'),
      onClearItem: (item) => print('item clear'),
    );

    customController = SearchDropDownController<Custom>(
      items: initialCustomItems,
      initialSelectedItem: selectedCustomItem,
      addMode: false,
      // Nothing else shows these items, so the controller's copy is enough.
      onDeleteItem: (item) => print('deleted ${item.label}'),
      confirmDelete: true,
      updateSelectedItem: (item) => selectedCustomItem = item,
      sort: SortType.selectedFirst,
    );
  }

  @override
  void dispose() {
    singleController.dispose();
    multipleController.dispose();
    customController.dispose();
    super.dispose();
  }

  void replaceItem(ValueItem item, ValueItem edited) {
    final int index = items.indexOf(item);
    if (index >= 0) {
      items[index] = edited;
    }
  }

  /// Hands [items] to the single dropdown, keeping its selection (following
  /// it when the selected item was [edited] into [by]).
  void syncSingle({ValueItem? edited, ValueItem? by}) {
    ValueItem? selected = singleController.selectedItem;
    if (edited != null && selected == edited) {
      selected = by;
    }
    // updateListItems resets a selection; select it again if it is still there.
    singleController.updateListItems(items, false);
    if (selected != null && items.contains(selected)) {
      singleController.selectItem(selected);
    }
  }

  /// Hands [items] to the multiple dropdown; a selected item that was
  /// [edited] stays selected as [by].
  void syncMultiple({ValueItem? edited, ValueItem? by}) {
    final bool wasSelected =
        edited != null && multipleController.isSelected(edited);
    multipleController.updateListItems(items, false);
    if (wasSelected && by != null) {
      multipleController.toggle(by, forced: true);
    }
  }

  void resetCustom() {
    customController.updateListItems(<ValueItem<Custom>>[
      ValueItem(label: 'Reset 1', value: Custom('Reset 1', 80)),
      ValueItem(label: 'Reset 2', value: Custom('Reset 2', 90)),
    ], true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 70),
            TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (BuildContext context) => DialogTest(items: items),
              ),
              child: const Text('Open Dialog'),
            ),
            const SizedBox(height: 20),
            SearchDropDown(
              controller: singleController,
              // This State creates and disposes the controllers.
              disposeController: false,
              searchBarSettings: const SimpleSearchbarSettings(
                showKeyboardOnTap: false,
                actions: [Icon(Icons.abc)],
                showDivider: true,
                clearOnClose: true,
              ),
              // A custom row: the edit and delete buttons stay beside it.
              overlayListSettings: SimpleOverlaySettings(
                itemWidgetBuilder: (item) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  color: Colors.blue,
                  child: Text(item.label),
                ),
              ),
            ),
            const SizedBox(height: 20),
            MultipleSearchDropDown(controller: multipleController),
            const SizedBox(height: 20),
            SearchDropDown<Custom>(
              controller: customController,
              disposeController: false,
              searchBarSettings: const SimpleSearchbarSettings(
                showArrow: false,
              ),
            ),
            const SizedBox(height: 20),
            _buttons([
              (
                'Print Single Result',
                () {
                  print(selectedSingleItem);
                  print(singleController.localSearchController.text);
                  print(singleController.selectedItem);
                },
              ),
              (
                'Print Multiple Result',
                () => print(selectedMultipleItems),
              ),
            ]),
            _buttons([
              ('Clear Single Selection', singleController.resetSelection),
              ('Clear Multiple Selection', multipleController.resetSelection),
            ]),
            _buttons([
              (
                'Print Custom Result',
                () {
                  final ValueItem<Custom>? custom = selectedCustomItem;
                  print(custom);
                  if (custom != null) {
                    print('name: ${custom.value!.name}');
                    print(custom.runtimeType);
                  }
                },
              ),
              ('Clear Custom Selection', customController.resetSelection),
            ]),
            _buttons([
              (
                'Force Single Selection',
                () => singleController.forceSelection('one more'),
              ),
              (
                'Force Multiple Selection',
                () => multipleController.forceSelection('one more'),
              ),
            ]),
            _buttons([
              (
                'Enable/Disable Single Selection',
                singleController.toggleEnabled,
              ),
            ]),
            _buttons([
              (
                'Print new Single Selection',
                () => print(singleController.selectedItem?.label),
              ),
            ]),
            _buttons([('Reset custom list', resetCustom)]),
          ],
        ),
      ),
    );
  }

  /// A centred row of text buttons, followed by a gap.
  Widget _buttons(List<(String, VoidCallback)> buttons) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        children: [
          for (final (String label, VoidCallback onPressed) in buttons)
            TextButton(onPressed: onPressed, child: Text(label)),
        ],
      ),
    );
  }
}
