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
  final List<ValueItem> listitems = [
    ValueItem(label: 'Lorenzo', value: 'Lorenzo'),
    ValueItem(label: 'Teste', value: 'Teste'),
    ValueItem(label: '3', value: '3'),
    ValueItem(label: 'one more', value: 'one more2')
  ];
  List<ValueItem> selectedMultipleItems = [];
  ValueItem? selectedSingleItem;

  void removeItem(ValueItem item) {
    setState(() {
      listitems.remove(item);
    });
  }

  void addItem(ValueItem item) {
    setState(() {
      listitems.add(item);
    });
  }

  void updateSelectedItems(List<ValueItem> newSelectedItems) {
    setState(() {
      selectedMultipleItems = newSelectedItems;
    });
  }

  void updateSelectedItem(ValueItem? newSelectedItem) {
    setState(() {
      selectedSingleItem = newSelectedItem;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SearchDropDown(
              listItens: listitems,
              onDeleteItem: removeItem,
              onAddItem: addItem,
              addMode: true,
              deleteMode: true,
              updateSelectedItem: updateSelectedItem,
            ),
            const SizedBox(
              height: 20,
            ),
            MultipleSearchDropDown(
              listItems: listitems,
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
                    child: const Text('Print Single Result')),
                const SizedBox(
                  width: 10,
                ),
                TextButton(
                    onPressed: () {
                      print(selectedMultipleItems);
                    },
                    child: const Text('Print Multiple Result')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
