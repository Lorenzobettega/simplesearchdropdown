# Search Dropdown
Search DropDown is a dropdown that offers a search bar, multiple and single selections.

[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-FFDD00?style=flat)](https://buymeacoffee.com/gian.bettega)

## Import
```dart
import 'package:simple_search_dropdown/simple_search_dropdown.dart';
```

## Getting Started
This project is a widget to find items in a list without sacrifying beauty and usefulness:

- Different styles: Search DropDown can be customized with various styles, including colors, text styles, icons, and more.
- Multiple and single options: Search DropDown can be used to select multiple or single items.
- Add and Delete Mode: Search Dropdown accepts functions to add and delete items from the list inside it
- Compact and Simple: Search DropDown is very compact and takes up very little space on the screen.

## Usage

### Features

#### Add Mode:
![Add Mode](https://github.com/Lorenzobettega/simplesearchdropdown/assets/84482292/d3b61c7e-b4ac-4b53-867b-71daab10d687)

#### Delete Mode:
![Delete Mode](https://github.com/Lorenzobettega/simplesearchdropdown/assets/84482292/ee4df7de-ec95-4804-a239-dc9ab8b5af9b)

#### Search:
![Search Feature](https://github.com/Lorenzobettega/simplesearchdropdown/assets/84482292/2e8360a7-9dd2-4b23-9431-d50b44cb7e07)

### 1. Single SearchDropDown

```dart
    SearchDropDown(
        listItens: listitems,
        onDeleteItem: removeItem, 
        onAddItem: addItem,
        addMode: true,
        deleteMode: true,
        updateSelectedItem: updateSelectedItem,
    ),
```

![Single Menu](https://github.com/Lorenzobettega/simplesearchdropdown/assets/84482292/826cf8ba-3dc2-4b2f-b5b8-7069a46893ed)

### 2. Multiple SearchDropDown

```dart
    MultipleSearchDropDown(
        listItems: listitems,
        onDeleteItem: removeItem, 
        onAddItem: addItem,
        addMode: true,
        deleteMode: true,
        selectedItems: selectedMultipleItems,
        updateSelectedItems: updateSelectedItems,
    ),
```

### 3. Reseting the dropdown to the unselected state:

```dart
    //create a key and add it to the dropdown:
    final GlobalKey<SearchDropDownState> singleSearchKey = GlobalKey();
    SearchDropDown(
        listItens: listitems,
        onDeleteItem: removeItem, 
        onAddItem: addItem,
        addMode: true,
        deleteMode: true,
        updateSelectedItem: updateSelectedItem,
    ),
    //create a function to clear the selection:
    void clearSingleSelection() {
        singleSearchKey.currentState?.clearSelection();
    }
    //assign it to a widget (like a button):
    TextButton(
        onPressed: clearSingleSelection,
        child: const Text('Clear Single Selection'),
    ),
```

![Multi Menu](https://github.com/Lorenzobettega/simplesearchdropdown/assets/84482292/1a531a60-84e5-4dd4-84e1-8196cfe08fc5)

![Multi Menu Selection](https://github.com/Lorenzobettega/simplesearchdropdown/assets/84482292/12f2db48-ca39-439a-9594-fc4b2b32b1f8)

## License

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](/LICENSE)
