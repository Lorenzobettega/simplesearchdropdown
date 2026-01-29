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
  final GlobalKey<MultipleSearchDropDownState> multipleSearchKey = GlobalKey();
  final GlobalKey<SearchDropDownState> searchKey = GlobalKey();
  final GlobalKey<SearchDropDownState> customSearchKey = GlobalKey();
  ValueItem<Custom>? selectedSingleCustom =
      ValueItem(label: 'Lorenzo', value: Custom('Lorenzo', 134));
  List<ValueItem> selectedMultipleItems = [];
  ValueItem? selectedSingleItem = listitems[1];
  final GlobalKey<SearchDropDownState> newsingleSearchKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    singleSearchController = SearchDropDownController(
      listItems: listitems,
      initialSelectedItem: listitems[1],
      confirmDelete: true,
      onDeleteItem: (item) async {
        await Future.delayed(const Duration(seconds: 2));
        listitems.remove(item);
      },
      onAddItem: (item) async {
        await Future.delayed(const Duration(seconds: 2));
        listitems.add(item);
      },
      updateSelectedItem: (item) => selectedSingleItem = item,
      verifyInputItem: (item) => item.label != 'name',
      newValueItem: (input) => ValueItem(label: input, value: input),
      sortType: 3,
      enabled: false,
      showClearIcon: true,
    );

    customSearchController = SearchDropDownController<Custom>(
      listItems: customListitems,
      initialSelectedItem: selectedSingleCustom,
      confirmDelete: true,
      onDeleteItem: (item) => customListitems.remove(item),
      onAddItem: (item) => customListitems.add(item),
      updateSelectedItem: (item) => selectedSingleCustom = item,
      verifyInputItem: (item) => item.label != 'name',
      newValueItem: (input) =>
          ValueItem(label: input, value: Custom(input, getRandomInt(4))),
      sortType: 3,
      addMode: false,
    );
  }

  void updateSelectedItems(List<ValueItem> newSelectedItems) {
    selectedMultipleItems = newSelectedItems;
  }

  void clearMultipleSelection() {
    multipleSearchKey.currentState?.resetSelection();
  }

  void onClearMultipleSelection() {
    print('clear');
  }

  void onClearItemMultipleSelection(ValueItem<dynamic> item) {
    print('item clear');
  }

  void clearCustomSelection() {
    customSearchKey.currentState?.resetSelection();
  }

  void force() {
    singleSearchController.forceSelection('one more');
  }

  void forceMultiple() {
    multipleSearchKey.currentState?.forceSelection('one more');
  }

  void enableSingle() {
    searchKey.currentState?.enableDisable();
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
              key: searchKey,
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
            MultipleSearchDropDown(
              key: multipleSearchKey,
              listItems: listitems,
              confirmDelete: true,
              onDeleteItem: (item) => listitems.remove(item),
              onAddItem: (item) => listitems.add(item),
              onClearList: onClearMultipleSelection,
              onClearItem: onClearItemMultipleSelection,
              selectedItems: selectedMultipleItems,
              updateSelectedItems: updateSelectedItems,
              newValueItem: (input) => ValueItem(label: input, value: input),
            ),
            const SizedBox(height: 20),
            SearchDropDown<Custom>(
              key: customSearchKey,
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
                  onPressed: () => searchKey.currentState?.resetSelection(),
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
          ],
        ),
      ),
    );
  }
}
