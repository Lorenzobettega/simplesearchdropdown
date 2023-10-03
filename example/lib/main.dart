// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

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
  final GlobalKey<MultipleSearchDropDownState> multipleSearchKey = GlobalKey();
  final List<ValueItem> listitems = [
    const ValueItem(label: 'Lorenzo', value: 'Lorenzo'),
    const ValueItem(label: 'Teste', value: 'Teste'),
    const ValueItem(label: '3', value: '3'),
    const ValueItem(label: 'one more', value: 'one more2')
  ];
  List<ValueItem> selectedMultipleItems = [];
  ValueItem? selectedSingleItem;

  void removeItem(ValueItem item) {
    listitems.remove(item);
  }

  void addItem(ValueItem item) {
    listitems.add(item);
  }

  void updateSelectedItems(List<ValueItem> newSelectedItems) {
    selectedMultipleItems = newSelectedItems;
  }

  void updateSelectedItem(ValueItem? newSelectedItem) {
    selectedSingleItem = newSelectedItem;
  }

  void clearSingleSelection() {
    singleSearchKey.currentState?.clearSelection();
  }

  void clearMultipleSelection() {
    multipleSearchKey.currentState?.clearSelection();
  }

  Future<bool> retornaTrue() async {
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SearchDropDown(
              key: singleSearchKey,
              listItens: listitems,
              preAceptDeleteMode: true,
              preAceptDelete: retornaTrue(),
              onDeleteItem: removeItem,
              onAddItem: addItem,
              addMode: true,
              deleteMode: true,
              updateSelectedItem: updateSelectedItem,
              selectedItem: listitems[0],
            ),
            const SizedBox(
              height: 20,
            ),
            MultipleSearchDropDown(
              key: multipleSearchKey,
              listItems: listitems,
              preAceptDeleteMode: true,
              preAceptDelete: retornaTrue(),
              onDeleteItem: removeItem,
              onAddItem: addItem,
              addMode: true,
              deleteMode: true,
              selectedItems: selectedMultipleItems,
              updateSelectedItems: updateSelectedItems,
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
          ],
        ),
      ),
    );
  }
}
