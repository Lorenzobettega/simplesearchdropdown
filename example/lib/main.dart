// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';
import '/custom.dart';
import '/dialog_test.dart';
import '/listitems.dart';

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
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final SearchDropDownController singleSearchController;
  late final SearchDropDownController<Custom> customSearchController;
  late final MultipleSearchDropDownController multipleSearchController;
  ValueItem<Custom>? selectedSingleCustom =
      ValueItem(label: 'Lorenzo', value: Custom('Lorenzo', 134));
  List<ValueItem> selectedMultipleItems = [];
  ValueItem? selectedSingleItem = listitems[1];

  @override
  void initState() {
    super.initState();

    singleSearchController = SearchDropDownController(
      items: listitems,
      initialSelectedItem: listitems[1],
      confirmDelete: true,
      onDeleteItem: (item) async {
        await Future.delayed(const Duration(seconds: 2));
        listitems.remove(item);
        multipleSearchController.updateListItems(listitems, false);
      },
      onAddItem: (item) async {
        await Future.delayed(const Duration(seconds: 2));
        listitems.add(item);
        multipleSearchController.updateListItems(listitems, false);
      },
      updateSelectedItem: (item) => selectedSingleItem = item,
      verifyInputItem: (item) => item.label != 'name',
      newValueItem: (input) => ValueItem(label: input, value: input),
      sort: SortType.selectedFirst,
      enabled: false,
      showClearIcon: true,
    );

    customSearchController = SearchDropDownController<Custom>(
      items: customListitems,
      initialSelectedItem: selectedSingleCustom,
      confirmDelete: true,
      onDeleteItem: (item) => customListitems.remove(item),
      onAddItem: (item) => customListitems.add(item),
      updateSelectedItem: (item) => selectedSingleCustom = item,
      verifyInputItem: (item) => item.label != 'name',
      newValueItem: (input) =>
          ValueItem(label: input, value: Custom(input, getRandomInt(4))),
      sort: SortType.selectedFirst,
      addMode: false,
    );

    multipleSearchController = MultipleSearchDropDownController(
      items: listitems,
      confirmDelete: true,
      onDeleteItem: (item) {
        listitems.remove(item);
        syncSingleItems();
      },
      onAddItem: (item) {
        listitems.add(item);
        syncSingleItems();
      },
      onClearList: onClearMultipleSelection,
      onClearItem: onClearItemMultipleSelection,
      selectedItems: selectedMultipleItems,
      updateSelectedItems: updateSelectedItems,
      newValueItem: (input) => ValueItem(label: input, value: input),
    );
  }

  @override
  void dispose() {
    multipleSearchController.dispose();
    super.dispose();
  }

  /// The first single dropdown shows the shared `listitems` too: hand it the
  /// new list, keeping its selection.
  void syncSingleItems() {
    final ValueItem? selected = singleSearchController.selectedItem;
    singleSearchController.updateListItems(listitems, false);
    if (selected != null && listitems.contains(selected)) {
      singleSearchController.selectItem(selected);
    }
  }

  void updateSelectedItems(List<ValueItem> newSelectedItems) {
    selectedMultipleItems = newSelectedItems;
  }

  void clearMultipleSelection() {
    multipleSearchController.resetSelection();
  }

  void onClearMultipleSelection() {
    print('clear');
  }

  void onClearItemMultipleSelection(ValueItem<dynamic> item) {
    print('item clear');
  }

  void clearCustomSelection() {
    customSearchController.resetSelection();
  }

  void force() {
    singleSearchController.forceSelection('one more');
  }

  void forceMultiple() {
    multipleSearchController.forceSelection('one more');
  }

  void enableSingle() {
    singleSearchController.toggleEnabled();
  }

  void resetCustom() {
    final List<ValueItem<Custom>> reset = <ValueItem<Custom>>[
      ValueItem(label: 'Reset 1', value: Custom('Reset 1', 80)),
      ValueItem(label: 'Reset 2', value: Custom('Reset 2', 90)),
    ];
    // The controller keeps its own copy; the app keeps its list in step.
    customListitems
      ..clear()
      ..addAll(reset);
    customSearchController.updateListItems(reset, true);
  }

  void printNewSingleSelection() {
    print(singleSearchController.selectedItem?.label);
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
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return const DialogTest();
                  },
                );
              },
              child: const Text('Open Dialog'),
            ),
            const SizedBox(height: 20),
            SearchDropDown(
              controller: singleSearchController,
              searchBarSettings: const SimpleSearchbarSettings(
                showKeyboardOnTap: false,
                actions: [Icon(Icons.abc)],
                showDivider: true,
                clearOnClose: true,
              ),
              overlayListSettings: SimpleOverlaySettings(
                itemWidgetBuilder: (item) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  color: Colors.blue,
                  child: Text(item.label),
                ),
              ),
            ),
            const SizedBox(height: 20),
            MultipleSearchDropDown(controller: multipleSearchController),
            const SizedBox(height: 20),
            SearchDropDown<Custom>(
              controller: customSearchController,
              searchBarSettings:
                  const SimpleSearchbarSettings(showArrow: false),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    print(selectedSingleItem);
                    print(singleSearchController.localSearchController.text);
                    print(singleSearchController.selectedItem);
                  },
                  child: const Text('Print Single Result'),
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: () => print(selectedMultipleItems),
                  child: const Text('Print Multiple Result'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: singleSearchController.resetSelection,
                  child: const Text('Clear Single Selection'),
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: clearMultipleSelection,
                  child: const Text('Clear Multiple Selection'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    print(selectedSingleCustom);
                    if (selectedSingleCustom != null) {
                      print('name: ${selectedSingleCustom!.value!.name}');
                      print(selectedSingleCustom.runtimeType);
                    }
                  },
                  child: const Text('Print Custom Result'),
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: clearCustomSelection,
                  child: const Text('Clear Custom Selection'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: force,
                  child: const Text('Force Single Selection'),
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: forceMultiple,
                  child: const Text('Force Multiple Selection'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: enableSingle,
              child: const Text('Enable/Disable Single Selection'),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: printNewSingleSelection,
                  child: const Text('Print new Single Selection'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: resetCustom,
              child: const Text('Reset custom list'),
            ),
          ],
        ),
      ),
    );
  }
}
