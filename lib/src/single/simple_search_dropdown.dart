// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';
import 'package:stringr/stringr.dart';

class SearchDropDown<T> extends StatefulWidget {
  const SearchDropDown({
    super.key,
    this.newValueItem,
    required this.listItems,
    required this.onAddItem,
    required this.updateSelectedItem,
    this.addMode = true,
    this.deleteMode = true,
    this.sortSelecteds = true,
    this.confirmDelete = false,
    this.elevation = 2,
    this.dropdownwidth = 300,
    this.dropdownHeight = 50,
    this.outsideIconSize = 20,
    this.actions,
    this.animationDuration,
    this.backgroundColor,
    this.border,
    this.createHint,
    this.createHintStyle,
    this.clearIconColor,
    this.dialogActionIcon,
    this.dialogActionWidget,
    this.dialogBackgroundColor,
    this.dialogHeight,
    this.dropdownDisableActionIcon,
    this.dropdownEnableActionIcon,
    this.hint,
    this.hintStyle,
    this.hoverColor,
    this.onDeleteItem,
    this.padding,
    this.selectedDialogColor,
    this.selectedItemHoverColor,
    this.selectedInsideBoxTextStyle,
    this.separatorHeight,
    this.unselectedInsideBoxTextStyle,
    this.unselectedItemHoverColor,
    this.widgetBuilder,
    this.selectedItem,
    this.outsideIconColor,
    this.deleteDialogSettings,
    this.verifyInputItem,
    this.verifyDialogSettings,
    this.clearOnClose = false,
  }) : assert((addMode && newValueItem != null) || !addMode,
            'addMode can only be used with newValueItem != null');

  final List<Widget>? actions;
  final bool addMode;
  final Duration? animationDuration;
  final Color? backgroundColor;
  final OutlinedBorder? border;
  final String? createHint;
  final TextStyle? createHintStyle;
  final Color? clearIconColor;
  final bool deleteMode;
  final Icon? dialogActionIcon;
  final Widget? dialogActionWidget;
  final Color? dialogBackgroundColor;
  final double? dialogHeight;
  final IconData? dropdownDisableActionIcon;
  final IconData? dropdownEnableActionIcon;
  final double elevation;
  final String? hint;
  final TextStyle? hintStyle;
  final Color? hoverColor;
  final List<ValueItem<T>> listItems;
  final Function(ValueItem<T>) onAddItem;
  final Function(ValueItem<T>)? onDeleteItem;
  final EdgeInsets? padding;
  final bool confirmDelete;
  final Color? selectedDialogColor;
  final TextStyle? selectedInsideBoxTextStyle;
  final Color? selectedItemHoverColor;
  final double? separatorHeight;
  final bool sortSelecteds;
  final TextStyle? unselectedInsideBoxTextStyle;
  final Color? unselectedItemHoverColor;
  final Function(ValueItem<T>?) updateSelectedItem;
  final Widget? widgetBuilder;
  final double dropdownHeight;
  final double dropdownwidth;
  final ValueItem<T>? selectedItem;
  final Color? outsideIconColor;
  final double outsideIconSize;
  final DialogSettings? deleteDialogSettings;
  final bool Function(ValueItem<T>)? verifyInputItem;
  final DialogSettings? verifyDialogSettings;
  final ValueItem<T> Function(String input)? newValueItem;
  final bool clearOnClose;

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
      widget.listItems.sort((a, b) => a.label.compareTo(b.label));
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
      setState(() {
        widget.onAddItem(item);
        hideOverlay(item);
        _filtrarLista(null);
      });
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
                  child: NovoListView(
                    addMode: widget.addMode,
                    animationDuration: widget.animationDuration,
                    backgroundColor: widget.backgroundColor,
                    controllerBar: controllerBar,
                    createHint: widget.createHint,
                    createHintStyle: widget.createHintStyle,
                    deleteMode: widget.deleteMode,
                    dialogActionIcon: widget.dialogActionIcon,
                    dialogActionWidget: widget.dialogActionWidget,
                    dialogBackgroundColor: widget.dialogBackgroundColor,
                    dialogHeight: widget.dialogHeight ?? 200,
                    elevation: widget.elevation,
                    hoverColor: widget.hoverColor,
                    listaFiltrada: listafiltrada,
                    onAddItem: (val) => handleAddItem(
                      val,
                    ),
                    onClear: (val) => handleDeleteItem(
                      val,
                      context,
                    ),
                    onPressed: (val) => hideOverlay(val),
                    padding: widget.padding,
                    selectedDialogColor: widget.selectedDialogColor,
                    selectedInsideBoxTextStyle:
                        widget.selectedInsideBoxTextStyle,
                    selectedItemHoverColor: widget.selectedItemHoverColor,
                    separatorHeight: widget.separatorHeight,
                    sortSelecteds: widget.sortSelecteds,
                    unselectedItemHoverColor: widget.unselectedItemHoverColor,
                    unselectedInsideBoxTextStyle:
                        widget.unselectedInsideBoxTextStyle,
                    widgetBuilder: widget.widgetBuilder,
                    width: widget.dropdownwidth,
                    newValueItem: widget.newValueItem,
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
        if (widget.clearOnClose || !widget.addMode) {
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
        width: widget.dropdownwidth,
        height: widget.dropdownHeight,
        child: SearchBar(
          trailing: widget.actions ??
              [
                aberto
                    ? Icon(
                        widget.dropdownEnableActionIcon ?? Icons.arrow_drop_up,
                        color: widget.outsideIconColor,
                        size: widget.outsideIconSize,
                      )
                    : Icon(
                        widget.dropdownDisableActionIcon ??
                            Icons.arrow_drop_down,
                        color: widget.outsideIconColor,
                        size: widget.outsideIconSize,
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
                          color: widget.clearIconColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
          controller: controllerBar,
          backgroundColor:
              MaterialStatePropertyAll(widget.backgroundColor ?? Colors.white),
          hintStyle: MaterialStatePropertyAll(widget.hintStyle),
          overlayColor: MaterialStatePropertyAll(
              widget.hoverColor ?? Colors.grey.shade100),
          surfaceTintColor:
              MaterialStatePropertyAll(widget.backgroundColor ?? Colors.white),
          shape: MaterialStateProperty.all<OutlinedBorder>(
            widget.border ??
                const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(10.0),
                  ),
                ),
          ),
          hintText: widget.hint ?? 'Selecione',
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
