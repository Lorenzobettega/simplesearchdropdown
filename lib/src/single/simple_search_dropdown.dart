// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';
import 'package:stringr/stringr.dart';

class SearchDropDown extends StatefulWidget {
  const SearchDropDown({
    super.key,
    this.actions,
    required this.addMode,
    this.animationDuration,
    this.backgroundColor,
    this.border,
    this.createHint,
    this.createHintStyle,
    this.clearIconColor,
    required this.deleteMode,
    this.dialogActionIcon,
    this.dialogActionWidget,
    this.dialogBackgroundColor,
    this.dialogHeight,
    this.dropdownDisableActionIcon,
    this.dropdownEnableActionIcon,
    this.elevation = 2,
    this.hint,
    this.hintStyle,
    this.hoverColor,
    required this.listItems,
    required this.onAddItem,
    this.onDeleteItem,
    this.padding,
    this.confirmDelete = false,
    this.selectedDialogColor,
    this.selectedItemHoverColor,
    this.selectedInsideBoxTextStyle,
    this.separatorHeight,
    this.sortSelecteds = true,
    this.unselectedInsideBoxTextStyle,
    this.unselectedItemHoverColor,
    required this.updateSelectedItem,
    this.widgetBuilder,
    this.dropdownwidth = 300,
    this.dropdownHeight = 50,
    this.selectedItem,
    this.outsideIconColor,
    this.outsideIconSize = 20,
    this.deleteDialogSettings,
    this.verifyInputItem,
    this.verifyDialogSettings,
  });

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
  final List<ValueItem> listItems;
  final Function(ValueItem) onAddItem;
  final Function(ValueItem)? onDeleteItem;
  final EdgeInsets? padding;
  final bool confirmDelete;
  final Color? selectedDialogColor;
  final TextStyle? selectedInsideBoxTextStyle;
  final Color? selectedItemHoverColor;
  final double? separatorHeight;
  final bool sortSelecteds;
  final TextStyle? unselectedInsideBoxTextStyle;
  final Color? unselectedItemHoverColor;
  final Function(ValueItem?) updateSelectedItem;
  final Widget? widgetBuilder;
  final double dropdownHeight;
  final double dropdownwidth;
  final ValueItem? selectedItem;
  final Color? outsideIconColor;
  final double outsideIconSize;
  final DialogSettings? deleteDialogSettings;
  final bool Function(ValueItem)? verifyInputItem;
  final DialogSettings? verifyDialogSettings;

  @override
  State<SearchDropDown> createState() => SearchDropDownState();
}

class SearchDropDownState extends State<SearchDropDown> {
  late OverlayScreen overlayScreen;
  List<ValueItem> listafiltrada = [];
  final LayerLink _layerLink = LayerLink();
  bool aberto = false;

  final TextEditingController controllerBar = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.listItems.isNotEmpty) {
      widget.listItems.sort((a, b) => a.label.compareTo(b.label));
      _filtrarLista(null, start: true);
      if (widget.selectedItem != null) {
        controllerBar.text = widget.selectedItem!.label;
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

  void handleAddItem(ValueItem item) {
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
    widget.updateSelectedItem(null);
  }

  void handleDeleteItem(ValueItem item, BuildContext context) {
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
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void hideOverlay(ValueItem? val) {
    setState(() {
      aberto = !aberto;
    });
    if (val != null) {
      widget.updateSelectedItem(val);
      controllerBar.text = val.label;
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
            //TODO fix: não deveria ter que ficar refazendo o overlay pra atualizar a lista
            hideOverlay(null);
            _showOverlay(context);
          },
          elevation: MaterialStateProperty.all<double>(
            widget.elevation,
          ),
        ),
      ),
    );
  }
}
