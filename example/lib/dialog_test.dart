import 'package:flutter/material.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

/// A dialog with a read-only single dropdown over [items].
class DialogTest extends StatefulWidget {
  const DialogTest({required this.items, super.key});

  /// The app's shared list, as it is when the dialog opens.
  final List<ValueItem> items;

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
      items: widget.items,
      addMode: false,
      deleteMode: false,
      updateSelectedItem: (item) => selectedSingleItem = item,
    );
  }

  @override
  void dispose() {
    dialogSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        height: 250,
        width: 350,
        child: Scaffold(
          appBar: AppBar(title: const Text('Dialog Test')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Column(
                children: [
                  const Text('Name:'),
                  const SizedBox(height: 20),
                  SearchDropDown(
                    controller: dialogSearchController,
                    // This State disposes the controller.
                    disposeController: false,
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
                    searchBarSettings: const SimpleSearchbarSettings(
                      showKeyboardOnTap: false,
                    ),
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
