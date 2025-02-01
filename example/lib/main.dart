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
  final GlobalKey<SearchDropDownState> singleSearchKey = GlobalKey();
  final GlobalKey<SearchDropDownState> customSearchKey = GlobalKey();
  final GlobalKey<MultipleSearchDropDownState> multipleSearchKey = GlobalKey();
  final SearchController _searchController1 = SearchController();
  final SearchController _searchController2 = SearchController();
  final SearchController _searchController3 = SearchController();
  ValueItem<Custom>? selectedSingleCustom =
      ValueItem(label: 'Lorenzo', value: Custom('Lorenzo', 134));

  List<ValueItem> selectedMultipleItems = [];
  ValueItem? selectedSingleItem;
  final GlobalKey<SearchDropDownState> newsingleSearchKey = GlobalKey();

  void removeItem(ValueItem item) {
    listitems.remove(item);
  }

  void addItem(ValueItem item) {
    listitems.add(item);
  }

  void editItem(ValueItem item, ValueItem newvalue) {
    final indx = listitems.indexOf(item);
    if (indx != -1) {
      listitems[indx] = newvalue;
    }
  }

  void updateSelectedItem(ValueItem? newSelectedItem) {
    selectedSingleItem = newSelectedItem;
  }

  void clearSingleSelection() {
    singleSearchKey.currentState?.resetSelection();
  }

  void onClearSingleSelection() {
    print('clear');
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

  void removeCustom(ValueItem<Custom> item) {
    customListitems.remove(item);
  }

  void addCustom(ValueItem<Custom> item) {
    customListitems.add(item);
  }

  void updateSelectedCustom(ValueItem<Custom>? newSelectedItem) {
    selectedSingleCustom = newSelectedItem;
  }

  void clearCustomSelection() {
    customSearchKey.currentState?.resetSelection();
  }

  void force() {
    singleSearchKey.currentState?.forceSelection('one more');
  }

  void forceMultiple() {
    multipleSearchKey.currentState?.forceSelection('one more');
  }

  void enableSingle() {
    singleSearchKey.currentState?.enableDisable();
    print(singleSearchKey.currentState?.enabled);
  }

  void printNewSingleSelection() {
    print(newsingleSearchKey.currentState?.selectedValue!.label);
  }

  bool verifyInput(ValueItem item) {
    return item.label != 'name';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              height: 70,
            ),
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
            const SizedBox(
              height: 20,
            ),
            SearchDropDown(
              key: singleSearchKey,
              listItems: listitems,
              confirmDelete: true,
              onDeleteItem: removeItem,
              onAddItem: addItem,
              updateSelectedItem: updateSelectedItem,
              onClear: onClearSingleSelection,
              selectedItem: listitems[0],
              verifyInputItem: verifyInput,
              newValueItem: (input) => ValueItem(label: input, value: input),
              overlayListSettings: SimpleOverlaySettings(
                itemWidgetBuilder: (item) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  color: Colors.blue,
                  child: Text(item.label),
                ),
              ),
              sortType: 3,
              enabled: false,
              searchBarSettings:
                  const SimpleSearchbarSettings(showKeyboardOnTap: false),
              searchController: _searchController1,
            ),
            const SizedBox(
              height: 20,
            ),
            MultipleSearchDropDown(
              key: multipleSearchKey,
              listItems: listitems,
              confirmDelete: true,
              onDeleteItem: removeItem,
              onAddItem: addItem,
              onClearList: onClearMultipleSelection,
              onClearItem: onClearItemMultipleSelection,
              selectedItems: selectedMultipleItems,
              updateSelectedItems: updateSelectedItems,
              newValueItem: (input) => ValueItem(label: input, value: input),
            ),
            const SizedBox(
              height: 20,
            ),
            SearchDropDown<Custom>(
              searchController: _searchController2,
              key: customSearchKey,
              selectedItem: selectedSingleCustom,
              listItems: customListitems,
              confirmDelete: true,
              onDeleteItem: removeCustom,
              onAddItem: addCustom,
              updateSelectedItem: updateSelectedCustom,
              verifyInputItem: verifyInput,
              sortType: 3,
              searchBarSettings:
                  const SimpleSearchbarSettings(showArrow: false),
              newValueItem: (input) => ValueItem(
                label: input,
                value: Custom(input, getRandomInt(4)),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            SearchDropDown(
              searchController: _searchController3,
              key: newsingleSearchKey,
              listItems: listitems,
              updateSelectedItem: updateSelectedItem,
              onAddItem: addItem,
              newValueItem: (input) => ValueItem(value: input, label: input),
              selectedItem: const ValueItem(
                label: 'Lorenzo',
              ),
              sortType: 2,
              confirmDelete: true,
              onDeleteItem: removeItem,
              verifyInputItem: verifyInput,
              searchBarSettings: const SimpleSearchbarSettings(
                  actions: [Icon(Icons.abc)], showDivider: true),
              editMode: true,
              onEditItem: editItem,
            ),
            const SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    print(selectedSingleItem);
                    print(_searchController1.text);
                    print(singleSearchKey.currentState?.selectedValue);
                  },
                  child: const Text('Print Single Result'),
                ),
                const SizedBox(
                  width: 10,
                ),
                TextButton(
                  onPressed: () {
                    print(selectedMultipleItems);
                  },
                  child: const Text('Print Multiple Result'),
                ),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: clearSingleSelection,
                  child: const Text('Clear Single Selection'),
                ),
                const SizedBox(
                  width: 10,
                ),
                TextButton(
                  onPressed: clearMultipleSelection,
                  child: const Text('Clear Multiple Selection'),
                ),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
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
                const SizedBox(
                  width: 10,
                ),
                TextButton(
                  onPressed: clearCustomSelection,
                  child: const Text('Clear Custom Selection'),
                ),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: force,
                  child: const Text('Force Single Selection'),
                ),
                const SizedBox(
                  width: 10,
                ),
                TextButton(
                  onPressed: forceMultiple,
                  child: const Text('Force Multiple Selection'),
                ),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            TextButton(
              onPressed: enableSingle,
              child: const Text('Enable/Disable Single Selection'),
            ),
            const SizedBox(
              height: 20,
            ),
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
