import 'package:flutter/material.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';
import '/listitems.dart';

class DialogTest extends StatefulWidget {
  const DialogTest({super.key});

  @override
  State<DialogTest> createState() => _DialogTestState();
}

class _DialogTestState extends State<DialogTest> {
  late final SearchDropDownController dialogSearchController;
  ValueItem? selectedSingleItem;

  @override
  void initState() {
    super.initState();
    dialogSearchController = SearchDropDownController(
      listItems: listitems,
      deleteMode: false,
      addMode: false,
      initialSelectedItem: selectedSingleItem,
      updateSelectedItem: (item) => selectedSingleItem = item,
      verifyInputItem: (item) => item.label != 'name',
      newValueItem: (input) => ValueItem(label: input, value: input),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        height: 250,
        width: 350,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Dialog Test'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Column(
                children: [
                  const Text('Name:'),
                  const SizedBox(height: 20),
                  SearchDropDown(
                    controller: dialogSearchController,
                    overlayListSettings: SimpleOverlaySettings(
                      itemWidgetBuilder: (item) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        color: Colors.blue,
                        child: Text(item.label),
                      ),
                    ),
                    searchBarSettings: const SimpleSearchbarSettings(
                        showKeyboardOnTap: false),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
