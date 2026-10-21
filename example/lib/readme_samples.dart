// The README samples live here so `flutter analyze` keeps them compiling.
// Each region between `// #docregion name` and `// #enddocregion name` is
// copied verbatim into README.md.
import 'package:flutter/material.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

// #docregion single
class FruitPicker extends StatefulWidget {
  const FruitPicker({super.key});

  @override
  State<FruitPicker> createState() => _FruitPickerState();
}

class _FruitPickerState extends State<FruitPicker> {
  late final SearchDropDownController<String> controller =
      SearchDropDownController<String>(
    items: const [
      ValueItem(label: 'Maçã', value: 'apple'),
      ValueItem(label: 'Banana', value: 'banana'),
      ValueItem(label: 'Uva', value: 'grape'),
    ],
    addMode: false,
    deleteMode: false,
    updateSelectedItem: (item) => debugPrint('selected: ${item?.value}'),
  );

  @override
  Widget build(BuildContext context) {
    // The widget disposes the controller (disposeController: true).
    return SearchDropDown<String>(controller: controller);
  }
}
// #enddocregion single

// #docregion crud
SearchDropDownController<String> editableController(
        List<ValueItem<String>> db) =>
    SearchDropDownController<String>(
      items: db,
      newValueItem: (input) => ValueItem(label: input, value: input),
      onAddItem: (item) async => debugPrint('save $item'),
      editMode: true,
      onEditItem: (old, edited) async => debugPrint('$old -> $edited'),
      onDeleteItem: (item) async => debugPrint('delete $item'),
      confirmDelete: true,
      verifyInputItem: (item) => item.label.trim().isNotEmpty,
      sort: SortType.alphabetical,
    );
// #enddocregion crud

// #docregion multiple
class TagPicker extends StatefulWidget {
  const TagPicker({super.key});

  @override
  State<TagPicker> createState() => _TagPickerState();
}

class _TagPickerState extends State<TagPicker> {
  final MultipleSearchDropDownController<int> controller =
      MultipleSearchDropDownController<int>(
    items: List.generate(20, (i) => ValueItem(label: 'Tag $i', value: i)),
    addMode: false,
    deleteMode: false,
  );

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          MultipleSearchDropDown<int>(controller: controller),
          TextButton(
            onPressed: controller.resetSelection,
            child: const Text('Clear'),
          ),
        ],
      );
}
// #enddocregion multiple

// #docregion strings
Widget englishApp(Widget home) => MaterialApp(
      builder: (context, child) => SearchDropDownStringsScope(
        strings: const SearchDropDownStrings.en(),
        child: child!,
      ),
      home: home,
    );
// #enddocregion strings

// #docregion classic
/// The 8.0.0 light look, for apps that want it back.
const SimpleSearchbarSettings classicBar = SimpleSearchbarSettings(
  backgroundColor: Colors.white,
  hoverColor: Color.fromRGBO(245, 245, 245, 1),
  boxMultiSelectedBackgroundColor: Color.fromRGBO(224, 224, 224, 1),
  border: RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(10)),
  ),
);

/// The 8.0.0 light rows. A text style equal to the stock one follows the
/// theme, so these add the size the rows are drawn at (14).
const SimpleOverlaySettings classicList = SimpleOverlaySettings(
  selectedItemBackgroundColor: Colors.black38,
  selectedItemHoverColor: Color.fromRGBO(224, 224, 224, 1),
  unselectedItemHoverColor: Color.fromRGBO(245, 245, 245, 1),
  highlightedItemBackgroundColor: Color.fromRGBO(245, 245, 245, 1),
  highlightedItemBorderColor: Colors.black26,
  selectedItemTextStyle: TextStyle(color: Colors.black, fontSize: 14),
  unselectedItemTextStyle: TextStyle(color: Colors.black45, fontSize: 14),
  dialogEditIcon: Icon(Icons.edit, color: Colors.black, size: 20),
  dialogDeleteIcon: Icon(
    Icons.delete,
    color: Color.fromRGBO(183, 28, 28, 1),
    size: 20,
  ),
  loadingColor: darkGreen,
);
// #enddocregion classic
