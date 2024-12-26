import 'package:flutter/material.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';
import 'package:stringr/stringr.dart';

///This creates a single selection dropdown widget.
class SearchDropDown<T> extends StatefulWidget {
  const SearchDropDown({
    super.key,
    required this.listItems,
    this.addMode = true,
    this.onAddItem,
    this.newValueItem,
    this.editMode = false,
    this.onEditItem,
    this.editDialogSettings,
    this.deleteMode = true,
    this.onDeleteItem,
    this.onClear,
    required this.updateSelectedItem,
    this.sortType = 0,
    this.confirmDelete = false,
    this.searchBarSettings = defaultSearchBarSettings,
    this.overlayListSettings = defaultOverlaySettings,
    this.selectedItem,
    this.deleteDialogSettings,
    this.verifyInputItem,
    this.verifyDialogSettings,
    this.addAditionalWidget,
    this.defaultAditionalWidget,
    this.enabled = true,
  })  : assert(
            (addMode && (newValueItem != null && onAddItem != null)) ||
                !addMode,
            'addMode can only be used with newValueItem != null && onAddItem != null'),
        assert((deleteMode && onDeleteItem != null) || !deleteMode,
            'deleteMode can only be used with onDeleteItem != null'),
        assert((editMode && onEditItem != null) || !editMode,
            'ediMode can only be used with onEditItem != null');

  /// List of the items to be presented on the dropdown.
  final List<ValueItem<T>> listItems;

  /// Allow the user to add items to the list.
  final bool addMode;

  /// Function to be executed after the item was added.
  final Function(ValueItem<T>)? onAddItem;

  /// Function that defines how the user input transforms into a new ValueItem on the list.
  ///
  /// Ex:`newValueItem: (input) => ValueItem(label: input, value: input)`
  final ValueItem<T> Function(String input)? newValueItem;

  /// Allow the user to delete items of the list.
  final bool deleteMode;

  /// Function to be executed after the item was deleted.
  final Function(ValueItem<T>)? onDeleteItem;

  /// Allow the user to edit items of the list.
  final bool editMode;

  /// Function to be executed after the item was edit.
  final Function(ValueItem<T> originalItem, ValueItem<T> newvalue)? onEditItem;

  /// Function to be executed after clear item.
  final Function()? onClear;

  /// Force the user to confirm delete.
  final bool confirmDelete;

  /// Delete dialog settings.
  final DialogSettings? deleteDialogSettings;

  /// Edit dialog settings.
  final DialogSettings? editDialogSettings;

  /// The SearchBarSettings.
  final SimpleSearchbarSettings searchBarSettings;

  /// The settings for the overlay list of items.
  final SimpleOverlaySettings overlayListSettings;

  /// Function to check if the item added is valid or not.
  final bool Function(ValueItem<T>)? verifyInputItem;

  /// Verify dialog settings.
  final DialogSettings? verifyDialogSettings;

  /// The initial selected value of the dropdown.
  final ValueItem<T>? selectedItem;

  /// The function to be executed after the user selects a value.
  final Function(ValueItem<T>?) updateSelectedItem;

  /// The way the items should be sorted.
  ///
  /// If `0`(default), no sort will be applied.
  ///
  /// If `1`, the items will be sorted on alphabetical order.
  ///
  /// If `2`, the items will be sorted on reverse alphabetical order.
  ///
  /// If `3`, the selected item will be put on first position.
  final int sortType;

  /// A custom additional widget to be inserted on the add item cell between the text and the create button.
  final Widget? addAditionalWidget;

  /// A custom additional widget to be inserted on the default item cell between the text and the delete button.
  final Widget? defaultAditionalWidget;

  /// A parameter to define if the widget is enabled or disabled (default: `true`).
  final bool enabled;

  @override
  State<SearchDropDown<T>> createState() => SearchDropDownState<T>();
}

class SearchDropDownState<T> extends State<SearchDropDown<T>> {
  final SearchController _searchController = SearchController();
  bool clearVisible = false;
  late bool enabled;
  ValueItem<T>? selectedValue;
  List<ValueItem<T>> listaFiltrada = [];
  String previousText = '';
  bool suppressFiltering = true;

  @override
  void initState() {
    super.initState();
    _sortFunction();
    if (widget.listItems.isNotEmpty) {
      if (widget.selectedItem != null) {
        selectedValue = widget.selectedItem;
        _searchController.text = selectedValue!.label;
        previousText = selectedValue!.label;
        if (widget.searchBarSettings.showClearIcon) {
          clearVisible = true;
        }
      }
    }
    enabled = widget.enabled;
    listaFiltrada.addAll(widget.listItems);
    _searchController.addListener(() {
      if (!suppressFiltering && _searchController.text != previousText) {
        previousText = _searchController.text;
        _filtrarLista(_searchController.text);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// enables/disables the widget.
  void enableDisable() {
    setState(() {
      enabled = !enabled;
    });
  }

  /// Sorts the list based on the sortType defined in the widget.
  void _sortFunction() {
    switch (widget.sortType) {
      case 0:
        break;
      case 1:
        widget.listItems.sort((a, b) => a.label.compareTo(b.label));
        break;
      case 2:
        widget.listItems.sort((a, b) => b.label.compareTo(a.label));
        break;
      case 3:
        if (selectedValue != null) {
          final indx = widget.listItems.indexOf(selectedValue!);
          if (indx != -1) {
            widget.listItems
              ..removeAt(indx)
              ..insert(0, selectedValue!);
          }
        }
        break;
    }
  }

  /// Filters the list based on the text input.
  void _filtrarLista(String text) {
    if (text.isNotEmpty) {
      listaFiltrada = widget.listItems
          .where((element) => element.label
              .toLowerCase()
              .latinize()
              .contains(text.latinize().toLowerCase()))
          .toList();
    } else {
      listaFiltrada = List<ValueItem<T>>.from(widget.listItems);
    }
  }

  /// Resets the selection to its default state.
  void resetSelection() {
    selectedValue = null;
    _searchController.clear();
    widget.updateSelectedItem(null);
    widget.onClear?.call();
    setState(() {
      clearVisible = false;
    });
  }

  /// Selects a specific item.
  void _selectedItem(ValueItem<T> item) {
    suppressFiltering = true;
    selectedValue = item;
    if (_searchController.isOpen) {
      _searchController.closeView(item.label);
    } else {
      _searchController.text = item.label;
    }
    previousText = _searchController.text;
    widget.updateSelectedItem(item);
    if (widget.searchBarSettings.showClearIcon) {
      setState(() {
        clearVisible = true;
      });
    }
  }

  /// Forces the selection of an item based on its label.
  void forceSelection(String label) {
    final ValueItem<T>? val =
        widget.listItems.where((element) => element.label == label).firstOrNull;
    if (val != null) {
      _selectedItem(val);
    }
  }

  /// Handles adding a new item to the list.
  Future<void> handleAddItem(String text) async {
    if (widget.addMode && widget.newValueItem != null) {
      final item = widget.newValueItem!(text);
      if (widget.verifyInputItem != null && !widget.verifyInputItem!(item)) {
        await sendDialog(
          context,
          WarningDialog(
            confirmDialog: false,
            returnFunction: (_) {
              Navigator.of(context).pop();
            },
            settings: widget.verifyDialogSettings,
          ),
        );
        _searchController.clear();
        return;
      }
      listaFiltrada.add(item);
      widget.onAddItem?.call(item);
      _selectedItem(item);
    }
  }

  /// Handles deleting an item from the list.
  Future<void> handleDeleteItem(ValueItem<T> item, BuildContext context) async {
    if (widget.deleteMode) {
      if (widget.confirmDelete) {
        await sendDialog(
          context,
          WarningDialog(
            returnFunction: (result) {
              if (result) {
                widget.onDeleteItem?.call(item);
                resetSelection();
              }
              Navigator.of(context).pop();
            },
            settings: widget.deleteDialogSettings,
          ),
        );
      } else {
        widget.onDeleteItem?.call(item);
        resetSelection();
      }
    }
  }

  //TODO add scroll to item.

  /// Handles editing an item from the list.
  Future<void> _handleEditItem(ValueItem<T> item) async {
    if (widget.editMode) {
      await sendDialog(
        context,
        EditDialog(
          label: item.label,
          returnFunction: (ok, text) {
            if (ok) {
              final newValue = widget.newValueItem!(text);
              widget.onEditItem?.call(item, newValue);
              resetSelection();
            }
            Navigator.of(context).pop();
          },
          settings: widget.editDialogSettings,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget clearButton = Visibility(
      visible: clearVisible,
      child: IconButton(
        onPressed: resetSelection,
        icon: Icon(
          Icons.clear,
          color: widget.searchBarSettings.clearIconColor,
          size: widget.searchBarSettings.outsideIconSize,
        ),
      ),
    );
    return SizedBox(
      width: widget.searchBarSettings.dropdownWidth,
      height: widget.searchBarSettings.dropdownHeight,
      child: SearchAnchor.bar(
        viewConstraints: BoxConstraints(
          maxWidth: widget.searchBarSettings.dropdownWidth,
          maxHeight: widget.overlayListSettings.dialogHeight,
        ),
        onTap: () {
          listaFiltrada = widget.listItems;
          suppressFiltering = false;
        },
        searchController: _searchController,
        viewHeaderHeight: widget.searchBarSettings.dropdownHeight,
        dividerColor: widget.searchBarSettings.showDivider
            ? null
            : (widget.overlayListSettings.dialogBackgroundColor ??
                widget.searchBarSettings.backgroundColor),
        viewTrailing: [
          if (widget.searchBarSettings.showArrow)
            Icon(
              widget.searchBarSettings.dropdownOpenedArrowIcon,
              color: widget.searchBarSettings.outsideIconColor,
              size: widget.searchBarSettings.outsideIconSize,
            ),
          clearButton
        ],
        barTrailing: widget.searchBarSettings.actions ??
            [
              if (widget.searchBarSettings.showArrow)
                Icon(
                  widget.searchBarSettings.dropdownClosedArrowIcon,
                  color: widget.searchBarSettings.outsideIconColor,
                  size: widget.searchBarSettings.outsideIconSize,
                ),
              clearButton
            ],
        barElevation:
            WidgetStatePropertyAll(widget.searchBarSettings.elevation),
        barShape: WidgetStatePropertyAll(
          widget.searchBarSettings.border ??
              RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
        ),
        viewShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        barBackgroundColor:
            WidgetStatePropertyAll(widget.searchBarSettings.backgroundColor),
        viewBackgroundColor: widget.overlayListSettings.dialogBackgroundColor ??
            widget.searchBarSettings.backgroundColor,
        isFullScreen: widget.overlayListSettings.openFullScreen,
        barHintStyle:
            WidgetStatePropertyAll(widget.searchBarSettings.hintStyle),
        barHintText: widget.searchBarSettings.hint,
        barOverlayColor:
            WidgetStatePropertyAll(widget.searchBarSettings.hoverColor),
        barTextStyle:
            WidgetStatePropertyAll(widget.searchBarSettings.searchBarTextStyle),
        barPadding:
            WidgetStatePropertyAll(widget.searchBarSettings.searchBarPadding),
        barLeading: const SizedBox.shrink(),
        barSide: WidgetStateProperty.all<BorderSide>(
          const BorderSide(
            style: BorderStyle.none,
          ),
        ),
        viewSide: const BorderSide(
          style: BorderStyle.none,
        ),
        viewLeading: const SizedBox.shrink(),
        viewElevation: widget.searchBarSettings.elevation,
        viewHintText: widget.searchBarSettings.hint,
        viewHeaderHintStyle: widget.searchBarSettings.hintStyle,
        viewHeaderTextStyle: widget.searchBarSettings.searchBarTextStyle,
        keyboardType: widget.searchBarSettings.showKeyboardOnTap
            ? widget.searchBarSettings.keyboardType
            : TextInputType.none,
        textInputAction: widget.searchBarSettings.textInputAction,
        suggestionsBuilder:
            (BuildContext context, SearchController controller) {
          return List<Widget>.generate(
              listaFiltrada.length + (widget.addMode ? 1 : 0), (int index) {
            if (index == listaFiltrada.length && widget.addMode) {
              if (controller.text.isNotEmpty) {
                final list = listaFiltrada
                    .where(
                      (element) =>
                          element.label.latinize().toLowerCase().contains(
                                controller.text.latinize().toLowerCase(),
                              ),
                    )
                    .toList();
                if (list.isEmpty) {
                  return DefaultAddListItem(
                    itemAdded: handleAddItem,
                    overlayListSettings: widget.overlayListSettings,
                    text: controller.text,
                    addAditionalWidget: widget.addAditionalWidget,
                  );
                }
              }
              return const SizedBox.shrink();
            } else {
              return DefaultListTile<T>(
                deleteMode: widget.deleteMode,
                editMode: widget.editMode,
                item: listaFiltrada[index],
                onDelete: (val) => handleDeleteItem(
                  val,
                  context,
                ),
                onEdit: _handleEditItem,
                onPressed: _selectedItem,
                overlayListSettings: widget.overlayListSettings,
                selected: controller.text == listaFiltrada[index].label,
                defaultAditionalWidget: widget.defaultAditionalWidget,
              );
            }
          });
        },
      ),
    );
  }
}
