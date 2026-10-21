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
    final TextTheme text = Theme.of(context).textTheme;
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints box) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dialog Test', style: text.titleLarge),
              const SizedBox(height: 16),
              SearchDropDown(
                controller: dialogSearchController,
                // This State disposes the controller.
                disposeController: false,
                searchBarSettings: SimpleSearchbarSettings(
                  dropdownWidth: box.maxWidth,
                  showKeyboardOnTap: false,
                ),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
