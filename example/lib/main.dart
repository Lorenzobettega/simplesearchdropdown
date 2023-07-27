// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:search_dropdown/search_dropdown.dart';

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
  final List<String> listitems = ['Lorenzo', 'É', 'Muito', 'Bonito'];
  List<String> selectedMultipleItems = [];
  String? selectedSingleItem;

  void removeItem(String item) {
    setState(() {
      listitems.remove(item);
    });
  }

  void addItem(String item) {
    setState(() {
      listitems.add(item);
    });
  }

  void updateSelectedItems(List<String> newSelectedItems) {
    setState(() {
      selectedMultipleItems = newSelectedItems;
    });
  }

  void updateSelectedItem(String newSelectedItem) {
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
            const SizedBox(height: 20,),
            MultipleSearchDropDown(
              listItems: listitems,
              onDeleteItem: removeItem, 
              onAddItem: addItem,
              addMode: true,
              deleteMode: true,
              selectedItems: selectedMultipleItems,
              updateSelectedItems: updateSelectedItems,
            ),
            const SizedBox(height: 20,),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: (){print(selectedSingleItem);}, 
                  child: const Text('Print Single Result')
                ),
                const SizedBox(width: 10,),
                TextButton(
                  onPressed: (){print(selectedMultipleItems);}, 
                  child: const Text('Print Multiple Result')
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
