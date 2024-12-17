// ignore_for_file: use_build_context_synchronously
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

  ///Function to be executed after the clear tabBar.
  final Function()? onClear;

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

  @override
  State<SearchDropDown<T>> createState() => SearchDropDownState<T>();
}

class SearchDropDownState<T> extends State<SearchDropDown<T>> {
  late OverlayScreen overlayScreen;
  List<ValueItem<T>> listaFiltrada = [];
  final LayerLink _layerLink = LayerLink();
  bool aberto = false;
  bool shouldScroll = true;
  bool clearVisible = false;
  late bool enabled;
  ValueItem<T>? selectedValue;

  final TextEditingController controllerBar = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.listItems.isNotEmpty) {
      _filtrarLista(null, start: true);
      if (widget.selectedItem != null) {
        controllerBar.text = widget.selectedItem!.label;
        selectedValue = widget.selectedItem!;
        if (widget.searchBarSettings.showClearIcon) {
          clearVisible = true;
        }
      }
    }
    enabled = widget.enabled;
    overlayScreen = OverlayScreen.of(context);
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

  void updateShouldScroll({bool reset = false}) {
    shouldScroll = reset;
  }

  void handleAddItem(ValueItem<T> item) {
    if (widget.addMode) {
      if (widget.verifyInputItem != null) {
        if (!widget.verifyInputItem!(item)) {
          controllerBar.clear();
          _filtrarLista(null);
          return overlayScreen.show(
            OverlayEntry(
              builder: (context) => WarningDialog(
                confirmDialog: false,
                returnFunction: (result) {
                  overlayScreen.closeLast();
                },
                settings: widget.verifyDialogSettings,
              ),
            ),
          );
        }
      }
      listaFiltrada.add(item);
      hideOverlay(item);
      widget.onAddItem!(item);
      _filtrarLista(null);
    }
  }

  void resetSelection() {
    controllerBar.clear();
    _filtrarLista(null);
    selectedValue = null;
    widget.updateSelectedItem(null);
    setState(() {
      clearVisible = false;
    });
  }

  void enableDisable() {
    setState(() {
      enabled = !enabled;
    });
  }

  void forceSelection(String label) {
    final ValueItem<T>? val =
        widget.listItems.where((element) => element.label == label).firstOrNull;
    if (val != null) {
      selectedValue = val;
      widget.updateSelectedItem(val);
      controllerBar.text = val.label;
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
        overlayScreen.show(
          OverlayEntry(
            builder: (context) => WarningDialog(
              returnFunction: (result) {
                if (result) {
                  widget.onDeleteItem!(item);
                  resetSelection();
                }
                overlayScreen
                  ..closeLast()
                  ..updateLast();
              },
              settings: widget.deleteDialogSettings,
            ),
          ),
        );
      } else {
        widget.onDeleteItem!(item);
        resetSelection();
        overlayScreen.updateLast();
      }
    }
  }

  // TODO ver como vai ser feito
  // void handleEditItem(ValueItem<T> item, BuildContext context) {
  //   if (widget.editMode) {
  //     widget.onEditItem!(item);
  //     resetSelection();
  //     overlayScreen.updateLast();
  //   }
  // }

  void _showOverlay(
    BuildContext context,
  ) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    sortFunction();
    overlayScreen.show(
      OverlayEntry(
        builder: (context) => Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => hideOverlay(null),
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),
            Positioned(
              width: size.width,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: Offset(widget.overlayListSettings.offsetWidth,
                    size.height + widget.overlayListSettings.offsetHeight),
                child: Material(
                  color: Colors.transparent,
                  child: SingleListView(
                    addMode: widget.addMode,
                    backgroundColor: widget.searchBarSettings.backgroundColor,
                    searchbarText: controllerBar.text,
                    deleteMode: widget.deleteMode,
                    elevation: widget.searchBarSettings.elevation,
                    listaFiltrada: listaFiltrada,
                    onAddItem: handleAddItem,
                    onDelete: (val) => handleDeleteItem(
                      val,
                      context,
                    ),
                    editMode: widget.editMode,
                    onEdit: (val) => (), // TODO colocar função
                    onPressed: hideOverlay,
                    dropdownwidth: widget.searchBarSettings.dropdownWidth,
                    newValueItem: widget.newValueItem,
                    selectedItem: selectedValue,
                    overlayListSettings: widget.overlayListSettings,
                    shouldScroll: shouldScroll,
                    updateShouldScroll: updateShouldScroll,
                    addAditionalWidget: widget.addAditionalWidget,
                    defaultAditionalWidget: widget.defaultAditionalWidget,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void hideOverlay(ValueItem<T>? val) {
    if (val != null) {
      selectedValue = val;
      widget.updateSelectedItem(val);
      controllerBar.text = val.label;
      if (widget.searchBarSettings.showClearIcon) {
        clearVisible = true;
      }
    } else {
      if (selectedValue != null) {
        final label = selectedValue!.label;
        if (controllerBar.text != label) {
          controllerBar.text = label;
        }
        if (widget.searchBarSettings.showClearIcon) {
          clearVisible = true;
        }
      } else {
        if ((widget.searchBarSettings.clearOnClose) || !widget.addMode) {
          controllerBar.clear();
        }
        clearVisible = false;
      }
    }
    setState(() {
      aberto = !aberto;
    });
    updateShouldScroll(reset: true);
    overlayScreen.closeAll();
    FocusScope.of(context).unfocus();
  }

  void onClear(){
    resetSelection();
    if(widget.onClear != null){
      widget.onClear!();
    } 
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: SizedBox(
        width: widget.searchBarSettings.dropdownWidth,
        height: widget.searchBarSettings.dropdownHeight,
        child: SearchBar(
          enabled: enabled,
          trailing: widget.searchBarSettings.actions ??
              [
                if (widget.searchBarSettings.showArrow)
                  if (aberto)
                    Icon(
                      widget.searchBarSettings.dropdownOpenedArrowIcon,
                      color: widget.searchBarSettings.outsideIconColor,
                      size: widget.searchBarSettings.outsideIconSize,
                    )
                  else
                    Icon(
                      widget.searchBarSettings.dropdownClosedArrowIcon,
                      color: widget.searchBarSettings.outsideIconColor,
                      size: widget.searchBarSettings.outsideIconSize,
                    ),
                Visibility(
                  visible: clearVisible,
                  child: Row(
                    children: [
                      if (widget.searchBarSettings.showArrow)
                        const SizedBox(
                          width: 5,
                        ),
                      IconButton(
                        onPressed: onClear,
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
          controller: controllerBar,
          backgroundColor:
              WidgetStatePropertyAll(widget.searchBarSettings.backgroundColor),
          hintStyle: WidgetStatePropertyAll(widget.searchBarSettings.hintStyle),
          overlayColor:
              WidgetStatePropertyAll(widget.searchBarSettings.hoverColor),
          surfaceTintColor:
              WidgetStatePropertyAll(widget.searchBarSettings.backgroundColor),
          shape: WidgetStatePropertyAll(widget.searchBarSettings.border),
          textStyle: WidgetStatePropertyAll(
              widget.searchBarSettings.searchBarTextStyle ??
                  widget.searchBarSettings.hintStyle),
          hintText: widget.searchBarSettings.hint,
          side: WidgetStateProperty.all<BorderSide>(
            const BorderSide(
              style: BorderStyle.none,
            ),
          ),
          onTap: () {
            if (overlayScreen.overlayEntrys.isEmpty) {
              setState(() {
                aberto = !aberto;
              });
              _showOverlay(context);
            } else {
              hideOverlay(null);
            }
          },
          onChanged: (a) {
            _filtrarLista(a);
            overlayScreen.updateLast();
          },
          elevation: WidgetStateProperty.all<double>(
              widget.searchBarSettings.elevation),
          padding: WidgetStateProperty.all<EdgeInsetsGeometry?>(
              widget.searchBarSettings.searchBarPadding),
        ),
      ),
    );
  }
}
