import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';
import 'package:stringr/stringr.dart';

class MultipleSearchDropDownController<T> extends ChangeNotifier {
  MultipleSearchDropDownController({
    required List<ValueItem<T>> listItems,
    List<ValueItem<T>>? initialSelectedItems,
    this.addMode = true,
    this.onAddItem,
    this.newValueItem,
    this.deleteMode = true,
    this.onDeleteItem,
    this.editMode = false,
    this.onEditItem,
    this.onClearItem,
    this.onClearList,
    this.confirmDelete = false,
    this.deleteDialogSettings,
    this.verifyInputItem,
    this.verifyDialogSettings,
    this.enabled = true,
    int sortType = 0,
    this.onFilterUpdated,
  })  : _allListItems = listItems,
        _selectedItems = initialSelectedItems ?? [],
        _enabled = enabled,
        _currentSortType = sortType {
    _rebuildCaches();
    if (sortType != 0) {
      sortList(sortType);
    }
    _setAll();
  }

  final List<ValueItem<T>> _allListItems;
  final List<ValueItem<T>> _selectedItems;
  final List<ValueItem<T>> _filteredItems = <ValueItem<T>>[];
  late final UnmodifiableListView<ValueItem<T>> _filteredView =
      UnmodifiableListView(_filteredItems);

  bool _aberto = false;
  bool _enabled;

  final bool enabled;
  final bool addMode;
  final Function(ValueItem<T>)? onAddItem;
  final ValueItem<T> Function(String input)? newValueItem;
  final bool deleteMode;
  final Function(ValueItem<T>)? onDeleteItem;
  final bool editMode;
  final Function(ValueItem<T>)? onEditItem;
  final Function(ValueItem<T>)? onClearItem;
  final Function()? onClearList;
  final bool confirmDelete;
  final DialogSettings? deleteDialogSettings;
  final bool Function(ValueItem<T>)? verifyInputItem;
  final DialogSettings? verifyDialogSettings;
  final void Function()? onFilterUpdated;

  final Map<ValueItem<T>, String> _normLabel = <ValueItem<T>, String>{};
  final Map<String, ValueItem<T>> _byLabel = <String, ValueItem<T>>{};
  int _currentSortType;
  int _highlightedIndex = -1;
  List<ValueItem<T>> get listItems => UnmodifiableListView(_allListItems);
  List<ValueItem<T>> get selectedItems => UnmodifiableListView(_selectedItems);
  UnmodifiableListView<ValueItem<T>> get filteredItems => _filteredView;
  bool get isOpened => _aberto;
  bool get isEnabled => _enabled;
  int get highlightedIndex => _highlightedIndex;

  void toggleDropdownVisibility() {
    _aberto = !_aberto;
    notifyListeners();
  }

  void enableDisable(bool enabled) {
    _enabled = enabled;
    notifyListeners();
  }

  void onItemSelected(ValueItem<T> val, {bool forced = false}) {
    if (_selectedItems.contains(val)) {
      if (!forced) {
        _selectedItems.remove(val);
        onClearItem?.call(val);
      }
    } else {
      _selectedItems.add(val);
    }
    notifyListeners();
  }

  void resetSelection() {
    _selectedItems.clear();
    notifyListeners();
  }

  void onClear() {
    _selectedItems.clear();
    onClearList?.call();
    notifyListeners();
  }

  void forceSelection(String label) {
    final ValueItem<T>? val = _byLabel[_normalize(label)];
    if (val != null && !_selectedItems.contains(val)) {
      _selectedItems.add(val);
      notifyListeners();
    }
  }

  void forceMultipleSelection(List<ValueItem<T>> values) {
    final Set<ValueItem<T>> referenceSet = _allListItems.toSet();
    final List<ValueItem<T>> listaFinal =
        values.where((item) => referenceSet.contains(item)).toList();
    _selectedItems
      ..clear()
      ..addAll(listaFinal);
    notifyListeners();
  }

  Future<void> handleAddItem(String text, BuildContext context) async {
    if (addMode && newValueItem != null) {
      final ValueItem<T> item = newValueItem!(text);
      if (verifyInputItem != null && !verifyInputItem!(item)) {
        await sendDialog(
          context,
          WarningDialog(
            confirmDialog: false,
            returnFunction: (_) {
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            settings: verifyDialogSettings,
          ),
        );
        return;
      }
      _allListItems.add(item);
      _normLabel[item] = _normalize(item.label);
      _byLabel[_normLabel[item]!] = item;

      await onAddItem?.call(item);
      _setAll();
      onItemSelected(item);
    }
  }

  Future<void> delete(ValueItem<T> item) async {
    await onDeleteItem?.call(item);
    _allListItems.remove(item);
    _selectedItems.remove(item);
    _normLabel.remove(item);
    final norm = _normalize(item.label);
    if (_byLabel[norm] == item) {
      _byLabel.remove(norm);
    }
    _setAll();
  }

  Future<void> handleDeleteItem(ValueItem<T> item, BuildContext context) async {
    if (deleteMode) {
      if (confirmDelete) {
        await sendDialog(
          context,
          WarningDialog(
            returnFunction: (bool result) {
              if (result) {
                delete(item);
              }
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            settings: deleteDialogSettings,
          ),
        );
      } else {
        await delete(item);
      }
    }
  }

  String _normalize(String s) => s.latinize().toLowerCase();

  void _rebuildCaches() {
    _normLabel.clear();
    _byLabel.clear();
    for (final e in _allListItems) {
      final n = _normalize(e.label);
      _normLabel[e] = n;
      _byLabel[n] = e;
    }
  }

  void _setAll() {
    _filteredItems.clear();
    final List<ValueItem<T>> source = _currentSortType != 0
        ? List<ValueItem<T>>.from(_allListItems)
        : _allListItems;

    if (_currentSortType == 1) {
      source.sort((a, b) => a.label.compareTo(b.label));
    } else if (_currentSortType == 2) {
      source.sort((a, b) => b.label.compareTo(a.label));
    } else if (_currentSortType == 3) {
      if (_selectedItems.isNotEmpty) {
        final firstSelected = _selectedItems.first;
        final int index = source.indexOf(firstSelected);
        if (index != -1) {
          source
            ..removeAt(index)
            ..insert(0, firstSelected);
        }
      }
    }
    _filteredItems.addAll(source);
    resetHighlight();
    notifyListeners();
  }

  void filterList(String text) {
    if (text.isEmpty) {
      _setAll();
      return;
    }
    _filterFrom(_allListItems, text);
  }

  void _filterFrom(List<ValueItem<T>> source, String text) {
    final String q = _normalize(text);

    final List<ValueItem<T>> result = <ValueItem<T>>[];
    for (final e in source) {
      if (_normLabel[e]!.contains(q)) {
        result.add(e);
      }
    }

    _filteredItems
      ..clear()
      ..addAll(result);

    resetHighlight();
    onFilterUpdated?.call();
    notifyListeners();
  }

  void sortList(int sortType) {
    if (_currentSortType == sortType) {
      return;
    }
    _currentSortType = sortType;
    _setAll();
  }

  void resetHighlight() {
    _highlightedIndex = -1;
  }

  void highlightNext() {
    if (_filteredItems.isEmpty) {
      _highlightedIndex = -1;
      return;
    }
    if (_highlightedIndex < 0) {
      _highlightedIndex = 0;
    } else {
      _highlightedIndex = (_highlightedIndex + 1) % _filteredItems.length;
    }
    notifyListeners();
  }

  void highlightPrevious() {
    if (_filteredItems.isEmpty) {
      _highlightedIndex = -1;
      return;
    }
    if (_highlightedIndex < 0) {
      _highlightedIndex = _filteredItems.length - 1;
    } else {
      _highlightedIndex = (_highlightedIndex - 1 + _filteredItems.length) %
          _filteredItems.length;
    }
    notifyListeners();
  }

  void selectHighlighted() {
    if (_highlightedIndex >= 0 && _highlightedIndex < _filteredItems.length) {
      onItemSelected(_filteredItems[_highlightedIndex]);
      resetHighlight();
    }
  }
}
