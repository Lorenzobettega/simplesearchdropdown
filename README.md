# Search Dropdown
Search DropDown is a dropdown that offers a search bar.

## Import
```dart
import 'package:searchdropdown/searchdropdown.dart';
```

## Getting Started
This project is a sample widget for finding items in a list without sacrificing beauty and usefulness:

-[Different styles: Search DropDown can be customized with various styles, including colors, text styles, icons, and more.]
-[Multiple and single options: Search DropDown can be used to select multiple or single items.]
-[Add and Delete Mode: Search DropDown accept functions of Add and Delete for items about the list inside him]
-[Compact and Simple: Search DropDown is very compact and takes up very little space on the screen (It's because the dropdown works with overlay).] 

In pub.dev have famous packages like that:
https://pub.dev/packages/dropdown_search
https://pub.dev/packages/search_choices

But no one is too simply, so I created that, to offers users more comfartable and a removal of pop up or page navigations.

## Usage

### Features

![Add Mode](assets/image-1.png)

![Search Feature](assets/image-4.png)

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

![Single Menu](assets/image.png)

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

![Multi Menu](assets/image-2.png)

![Multi Menu Selection](assets/image-3.png)

## License

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](/LICENSE)
