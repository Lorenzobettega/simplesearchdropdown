import 'package:flutter/material.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';
import '/listitems.dart';

class DialogTest extends StatelessWidget {
  const DialogTest({super.key});

  @override
  Widget build(BuildContext context) {
    final GlobalKey<SearchDropDownState> singleSearchKey = GlobalKey();
    final SearchController _searchController1 = SearchController();
    ValueItem? selectedSingleItem;

    void updateSelectedItem(ValueItem? newSelectedItem) {
      selectedSingleItem = newSelectedItem;
    }

    bool verifyInput(ValueItem item) {
      return item.label != 'name';
    }

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
                  const SizedBox(
                    height: 20,
                  ),
                  SearchDropDown(
                    key: singleSearchKey,
                    listItems: listitems,
                    deleteMode: false,
                    addMode: false,
                    updateSelectedItem: updateSelectedItem,
                    selectedItem: selectedSingleItem,
                    verifyInputItem: verifyInput,
                    newValueItem: (input) =>
                        ValueItem(label: input, value: input),
                    overlayListSettings: SimpleOverlaySettings(
                      itemWidgetBuilder: (item) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        color: Colors.blue,
                        child: Text(item.label),
                      ),
                    ),
                    searchBarSettings:
                        const SimpleSearchbarSettings(showKeyboardOnTap: false),
                    searchController: _searchController1,
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
