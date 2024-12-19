import 'package:flutter/material.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';
import 'package:stringr/stringr.dart';

class NewSingle<T> extends StatefulWidget {
  const NewSingle({
    super.key,
    required this.listItems,
    this.addMode = true,
    this.onAddItem,
    this.newValueItem,
    this.editMode = false,
    this.onEditItem,
    this.deleteMode = true,
    this.onDeleteItem,
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
    required this.controller,
  });

  ///List of the items to be presented on the dropdown.
  final List<ValueItem<T>> listItems;

  ///Allow the user to add items to the list.
  final bool addMode;

  ///Function to be executed after the item was added.
  final Function(ValueItem<T>)? onAddItem;

  ///Function that defines how the user input transforms into a new ValueItem on the list.
  ///
  ///Ex:`newValueItem: (input) => ValueItem(label: input, value: input)`
  final ValueItem<T> Function(String input)? newValueItem;

  ///Allow the user to delete items of the list.
  final bool deleteMode;

  ///Function to be executed after the item was deleted.
  final Function(ValueItem<T>)? onDeleteItem;

  ///Allow the user to edit items of the list.
  final bool editMode;

  ///Function to be executed after the item was edit.
  final Function(ValueItem<T>)? onEditItem;

  ///Force the user to confirm delete
  final bool confirmDelete;

  ///Visual delete dialog settings
  final DialogSettings? deleteDialogSettings;

  ///The SearchBarSettings.
  final SimpleSearchbarSettings searchBarSettings;

  ///The settings for the overlay list of items.
  final SimpleOverlaySettings overlayListSettings;

  ///Function to check if the item added is valid or not.
  final bool Function(ValueItem<T>)? verifyInputItem;

  ///Visual verify dialog settings
  final DialogSettings? verifyDialogSettings;

  ///The initial selected value of the dropdown.
  final ValueItem<T>? selectedItem;

  ///The function to be executed after the user selects a value.
  final Function(ValueItem<T>?) updateSelectedItem;

  ///The way the items should be sorted.
  ///
  ///If `0`(default), no sort will be applied
  ///
  ///If `1`, the items will be sorted on alphabetical order.
  ///
  ///If `2`, the items will be sorted on reverse alphabetical order.
  ///
  ///If `3`, the selected item will be put on first position.
  final int sortType;

  ///A custom aditional widget to be inserted on the add item cell between the text and the create button.
  final Widget? addAditionalWidget;

  ///A custom aditional widget to be inserted on the default item cell between the text and the delete button.
  final Widget? defaultAditionalWidget;

  ///A parameter to define if the widget is enabled or disabled (default: `true`).
  final bool enabled;

  final SearchController controller;

  @override
  State<NewSingle<T>> createState() => _NewSingleState<T>();
}

class _NewSingleState<T> extends State<NewSingle<T>> {
  bool clearVisible = false;
  ValueItem<T>? selectedValue;
  List<ValueItem<T>> listaFiltrada = [];

  @override
  void initState() {
    super.initState();
    if (widget.listItems.isNotEmpty) {
      _filtrarLista(null, start: true);
      if (widget.selectedItem != null) {
        widget.controller.text = widget.selectedItem!.label;
        selectedValue = widget.selectedItem!;
        if (widget.searchBarSettings.showClearIcon) {
          clearVisible = true;
        }
      }
    }
  }

  void sortFunction() {
    switch (widget.sortType) {
      case 0:
        break;
      case 1:
        listaFiltrada.sort((a, b) => a.label.compareTo(b.label));
        break;
      case 2:
        listaFiltrada.sort((a, b) => b.label.compareTo(a.label));
        break;
      case 3:
        if (selectedValue != null) {
          final indx = listaFiltrada.indexOf(selectedValue!);
          if (indx != -1) {
            listaFiltrada
              ..removeAt(indx)
              ..insert(0, selectedValue!);
          }
        }
        break;
    }
  }

  void _filtrarLista(String? text, {bool start = false}) {
    if (start) {
      listaFiltrada = widget.listItems;
    } else {
      if (text != null && text != '') {
        listaFiltrada = widget.listItems
            .where((element) => element.label
                .toLowerCase()
                .latinize()
                .contains(text.latinize().toLowerCase()))
            .toList();
      } else {
        listaFiltrada = widget.listItems;
      }
    }
  }

  void handleAddItem(ValueItem<T> item) {
    if (widget.addMode) {
      if (widget.verifyInputItem != null) {
        if (!widget.verifyInputItem!(item)) {
          widget.controller.clear();
          _filtrarLista(null);
        }
      }
      listaFiltrada.add(item);
      widget.controller.closeView(item.label);
      widget.onAddItem!(item);
      _filtrarLista(null);
    }
  }

  void resetSelection() {
    widget.controller.clear();
    _filtrarLista(null);
    selectedValue = null;
    widget.updateSelectedItem(null);
    setState(() {
      clearVisible = false;
    });
  }

  void forceSelection(String label) {
    final ValueItem<T>? val =
        widget.listItems.where((element) => element.label == label).firstOrNull;
    if (val != null) {
      selectedValue = val;
      widget.updateSelectedItem(val);
      widget.controller.text = val.label;
      if (widget.searchBarSettings.showClearIcon) {
        setState(() {
          clearVisible = true;
        });
      }
    }
  }

  void handleDeleteItem(ValueItem<T> item, BuildContext context) {
    if (widget.deleteMode) {
      if (widget.confirmDelete) {
        widget.controller.openView();
      } else {
        widget.onDeleteItem!(item);
        resetSelection();
      }
    }
  }

  void goToSelectedItem(ValueItem<T> item) {
    final index = listaFiltrada.indexOf(item);
    if (index > 1) {
      // scrollController.scrollTo(
      //   index: index,
      //   duration: overlayListSettings.reOpenedScrollDuration,
      //   curve: Curves.ease,
      // );
    }
  }

  void itemAdded(String text) {
    final item = widget.newValueItem!(text);
    widget.onAddItem!(item);
  }


  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.searchBarSettings.dropdownWidth,
      height: widget.searchBarSettings.dropdownHeight,
      child: SearchAnchor.bar(
        // Dialog box
        viewConstraints: BoxConstraints(
          maxWidth: widget.searchBarSettings.dropdownWidth,
          maxHeight: widget.overlayListSettings.dialogHeight,
        ),
        searchController: widget.controller,
        // altura textinputfield drop down aberto
        viewHeaderHeight: widget.searchBarSettings.dropdownHeight,
        //o que vai de widget no final do drop fechado
        barTrailing: [
          Visibility(
            visible: clearVisible,
            child: Row(
              children: [
                if (widget.searchBarSettings.showArrow)
                  const SizedBox(
                    width: 5,
                  ),
                IconButton(
                  onPressed: () {
                    widget.controller.clear();
                    clearVisible = false;
                  },
                  icon: Icon(
                    Icons.clear,
                    color: widget.searchBarSettings.clearIconColor,
                    size: widget.searchBarSettings.outsideIconSize,
                  ),
                ),
              ],
            ),
          ),
        ],
        barElevation:
            WidgetStatePropertyAll(widget.searchBarSettings.elevation),
        // Borda drop fechado
        barShape: WidgetStatePropertyAll(
          widget.searchBarSettings.border ??
              RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
        ),
        // Borda quando abre o drop
        viewShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        barBackgroundColor:
            WidgetStatePropertyAll(widget.searchBarSettings.backgroundColor),
        viewBackgroundColor: widget.overlayListSettings.dialogBackgroundColor ??
            widget.searchBarSettings.backgroundColor,
        // abrir full screen no drop
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
        barLeading: SizedBox.shrink(),
        barSide: WidgetStateProperty.all<BorderSide>(
          const BorderSide(
            style: BorderStyle.none,
          ),
        ),
        viewSide: const BorderSide(
          style: BorderStyle.none,
        ),
        onChanged: (a) {
          _filtrarLista(a);
        },
        // Tirar ou colocar seta para voltar do drop
        viewLeading: null,
        viewElevation: widget.searchBarSettings.elevation,
        viewHintText: widget.searchBarSettings.hint,
        viewHeaderHintStyle: widget.searchBarSettings.hintStyle,
        viewHeaderTextStyle: widget.searchBarSettings.searchBarTextStyle,
        keyboardType: widget.searchBarSettings.showKeyboardOnTap ? TextInputType.none : widget.searchBarSettings.keyboardType,
        textInputAction: widget.searchBarSettings.textInputAction,
        suggestionsBuilder:
            (BuildContext context, SearchController controller) {
          return List<Widget>.generate(listaFiltrada.length + (widget.addMode ? 1 : 0), (int index) {
            if (index == listaFiltrada.length && widget.addMode) {
              if (controller.text != '') {
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
                    itemAdded: itemAdded,
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
                onDelete: (val) => handleDeleteItem(val,context,),
                onEdit: (val){},
                onPressed: (_) {
                  controller.closeView(_.label);
                },
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
