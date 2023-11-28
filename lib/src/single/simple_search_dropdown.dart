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
    this.deleteMode = true,
    this.onDeleteItem,
    required this.updateSelectedItem,
    this.sortType = 0,
    this.confirmDelete = false,
    this.elevation = 2,
    this.backgroundColor,
    this.addItemHint,
    this.addItemHintStyle,
    this.dialogBackgroundColor,
    this.searchBarSettings,
    this.overlayListSettings,
    this.widgetBuilder,
    this.selectedItem,
    this.deleteDialogSettings,
    this.verifyInputItem,
    this.verifyDialogSettings,
  })  : assert(
            (addMode && (newValueItem != null && onAddItem != null)) ||
                !addMode,
            'addMode can only be used with newValueItem != null && onAddItem != null'),
        assert((deleteMode && onDeleteItem != null) || !deleteMode,
            'deleteMode can only be used with onDeleteItem != null');

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

  ///The text of the add button when user is allowed to add items in the list.
  final String? addItemHint;

  ///The style of the add button when user is allowed to add items in the list.
  final TextStyle? addItemHintStyle;

  ///Allow the user to delete items of the list.
  final bool deleteMode;

  ///Function to be executed after the item was deleted.
  final Function(ValueItem<T>)? onDeleteItem;

  ///Force the user to confirm delete
  final bool confirmDelete;

  ///Visual delete dialog settings
  final DialogSettings? deleteDialogSettings;

  ///The SearchBarSettings.
  final SimpleSearchbarSettings? searchBarSettings;

  ///The overlay list of items settings.
  final SimpleOverlaySettings? overlayListSettings;

  ///The background color of the searchbar and overlay.
  final Color? backgroundColor;

  ///The elevation of the searchbar(default:2).
  final double elevation;

  ///Dropdown Container color
  final Color? dialogBackgroundColor;

  ///Custom droplist item widget.
  final Widget? widgetBuilder;

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

  @override
  State<SearchDropDown<T>> createState() => SearchDropDownState<T>();
}

class SearchDropDownState<T> extends State<SearchDropDown<T>> {
  late OverlayScreen overlayScreen;
  List<ValueItem<T>> listafiltrada = [];
  final LayerLink _layerLink = LayerLink();
  bool aberto = false;
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
      }
    }
    overlayScreen = OverlayScreen.of(context);
  }

  void _filtrarLista(String? text, {bool start = false}) {
    if (start) {
      listafiltrada = widget.listItems;
    } else {
      if (text != null && text != '') {
        listafiltrada = widget.listItems
            .where((element) => element.label
                .toLowerCase()
                .latinize()
                .contains(text.toLowerCase()))
            .toList();
      } else {
        listafiltrada = widget.listItems;
      }
    }
  }

  void handleAddItem(ValueItem<T> item) {
    if (widget.addMode) {
      if (widget.verifyInputItem != null) {
        if (!widget.verifyInputItem!(item)) {
          //TODO na pratica o item é visualmente adicionado e depois removido. Ajustar pra nem adicionar.
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
                overlayScreen.closeLast();
              },
              settings: widget.deleteDialogSettings,
            ),
          ),
        );
      } else {
        widget.onDeleteItem!(item);
        resetSelection();
      }
    }
  }

  void _showOverlay(
    BuildContext context,
  ) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
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
                offset: Offset(0.0, size.height + 3.0),
                child: Material(
                  color: Colors.transparent,
                  child: SingleListView(
                    addMode: widget.addMode,
                    animationDuration:
                        widget.overlayListSettings?.animationDuration,
                    backgroundColor: widget.backgroundColor,
                    controllerBar: controllerBar,
                    addItemHint: widget.addItemHint,
                    addItemHintStyle: widget.addItemHintStyle,
                    deleteMode: widget.deleteMode,
                    dialogActionIcon:
                        widget.overlayListSettings?.dialogActionIcon,
                    dialogActionWidget:
                        widget.overlayListSettings?.dialogActionWidget,
                    dialogBackgroundColor: widget.dialogBackgroundColor,
                    dialogHeight:
                        widget.overlayListSettings?.dialogHeight ?? 200,
                    elevation: widget.elevation,
                    listaFiltrada: listafiltrada,
                    onAddItem: (val) => handleAddItem(
                      val,
                    ),
                    onClear: (val) => handleDeleteItem(
                      val,
                      context,
                    ),
                    onPressed: (val) => hideOverlay(val),
                    itemsPadding: widget.overlayListSettings?.itemsPadding,
                    selectedItemBackgroundColor:
                        widget.overlayListSettings?.selectedItemBackgroundColor,
                    selectedItemTextStyle:
                        widget.overlayListSettings?.selectedItemTextStyle,
                    selectedItemHoverColor:
                        widget.overlayListSettings?.selectedItemHoverColor,
                    separatorHeight:
                        widget.overlayListSettings?.separatorHeight,
                    sortType: widget.sortType,
                    unselectedItemHoverColor:
                        widget.overlayListSettings?.unselectedItemHoverColor,
                    unselectedItemTextStyle:
                        widget.overlayListSettings?.unselectedItemTextStyle,
                    widgetBuilder: widget.widgetBuilder,
                    dropdownwidth: widget.searchBarSettings?.dropdownwidth ?? 300,
                    newValueItem: widget.newValueItem,
                    selectedItem: selectedValue,
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
    setState(() {
      aberto = !aberto;
    });
    if (val != null) {
      selectedValue = val;
      widget.updateSelectedItem(val);
      controllerBar.text = val.label;
    } else {
      if (selectedValue != null) {
        final label = selectedValue!.label;
        if (controllerBar.text != label) {
          controllerBar.text = label;
        }
      } else {
        if ((widget.searchBarSettings?.clearOnClose ?? false) ||
            !widget.addMode) {
          controllerBar.clear();
        }
      }
    }
    overlayScreen.closeAll();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: SizedBox(
        width: widget.searchBarSettings?.dropdownwidth ?? 300,
        height: widget.searchBarSettings?.dropdownHeight ?? 50,
        child: SearchBar(
          trailing: widget.searchBarSettings?.actions ??
              [
                aberto
                    ? Icon(
                        widget.searchBarSettings?.dropdownOpenedArrowIcon ??
                            Icons.arrow_drop_up,
                        color: widget.searchBarSettings?.outsideIconColor,
                        size: widget.searchBarSettings?.outsideIconSize ?? 20,
                      )
                    : Icon(
                        widget.searchBarSettings?.dropdownClosedArrowIcon ??
                            Icons.arrow_drop_down,
                        color: widget.searchBarSettings?.outsideIconColor,
                        size: widget.searchBarSettings?.outsideIconSize ?? 20,
                      ),
                Visibility(
                  visible: controllerBar.text != '',
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 5,
                      ),
                      IconButton(
                        onPressed: resetSelection,
                        icon: Icon(
                          Icons.clear,
                          color: widget.searchBarSettings?.clearIconColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
          controller: controllerBar,
          backgroundColor:
              MaterialStatePropertyAll(widget.backgroundColor ?? Colors.white),
          hintStyle: MaterialStatePropertyAll(
              widget.searchBarSettings?.hintStyle ??
                  const TextStyle(fontSize: 14)),
          overlayColor: MaterialStatePropertyAll(
              widget.searchBarSettings?.hoverColor ?? Colors.grey.shade100),
          surfaceTintColor:
              MaterialStatePropertyAll(widget.backgroundColor ?? Colors.white),
          shape: MaterialStateProperty.all<OutlinedBorder>(
            widget.searchBarSettings?.border ??
                const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(10.0),
                  ),
                ),
          ),
          hintText: widget.searchBarSettings?.hint ?? 'Selecione',
          side: MaterialStateProperty.all<BorderSide>(
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
          elevation: MaterialStateProperty.all<double>(widget.elevation),
        ),
      ),
    );
  }
}
