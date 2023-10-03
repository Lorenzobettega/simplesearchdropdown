import 'dart:async';
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
    this.dialogHeight = 300,
    this.dropdownDisableActionIcon,
    this.dropdownEnableActionIcon,
    this.elevation = 2,
    this.hint,
    this.hintStyle,
    this.hoverColor,
    required this.listItens,
    required this.onAddItem,
    this.onDeleteItem,
    this.padding,
    this.confirmDelete = false,
    this.confirmDeleteFunction,
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
  }) : assert(confirmDelete && confirmDeleteFunction != null || !confirmDelete,
            'confirmDelete can only be true if confirmDeleteFunction != null ');

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
  final double dialogHeight;
  final IconData? dropdownDisableActionIcon;
  final IconData? dropdownEnableActionIcon;
  final double elevation;
  final String? hint;
  final TextStyle? hintStyle;
  final Color? hoverColor;
  final List<ValueItem> listItens;
  final Function(ValueItem) onAddItem;
  final Function(ValueItem)? onDeleteItem;
  final EdgeInsets? padding;
  final bool confirmDelete;
  final Future<bool> Function()? confirmDeleteFunction;
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

  @override
  State<SearchDropDown> createState() => SearchDropDownState();
}

class SearchDropDownState extends State<SearchDropDown> {
  @override
  void initState() {
    super.initState();
    _filtrarLista(null, start: true);
    controllerBar = TextEditingController(
        text: widget.selectedItem != null ? widget.selectedItem!.label : null);
  }

  List<ValueItem> listafiltrada = [];
  OverlayEntry? overlayEntry;
  final GlobalKey overlayKey = GlobalKey();
  bool aberto = false;
  late TextEditingController controllerBar;

  void _filtrarLista(String? text, {bool start = false}) {
    if (start) {
      listafiltrada = widget.listItens;
    } else {
      if (text != null && text != '') {
        listafiltrada = widget.listItens
            .where((element) => element.label
                .toLowerCase()
                .latinize()
                .contains(text.toLowerCase()))
            .toList();
      } else {
        listafiltrada = widget.listItens;
      }
    }
  }

  void _showOverlay(
    BuildContext context,
  ) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RenderBox widgetPosition =
        overlayKey.currentContext!.findRenderObject() as RenderBox;
    final Offset offset =
        widgetPosition.localToGlobal(Offset.zero, ancestor: overlay);

    overlayEntry = OverlayEntry(
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
            top: offset.dy + widgetPosition.size.height,
            left: offset.dx - 4,
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
                dialogHeight: widget.dialogHeight,
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
                selectedInsideBoxTextStyle: widget.selectedInsideBoxTextStyle,
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
        ],
      ),
    );
    setState(() {
      aberto = !aberto;
    });
    Overlay.of(context).insert(overlayEntry!);
  }

  void handleAddItem(ValueItem item) {
    if (widget.addMode) {
      setState(() {
        widget.onAddItem(item);
        hideOverlay(item);
        _filtrarLista(item.label);
      });
    }
  }

  void clearSelection() {
    setState(() {
      controllerBar.clear();
      _filtrarLista(null);
      widget.updateSelectedItem(null);
    });
  }

  Future<void> handleDeleteItem(ValueItem item, BuildContext context) async {
    if (widget.deleteMode) {
      if (widget.confirmDelete) {
        hideOverlay(null);
        final result = await widget.confirmDeleteFunction!();
        if (result) {
          widget.onDeleteItem!(item);
        }
        // ignore: use_build_context_synchronously
        _showOverlay(context);
      } else {
        setState(() {
          widget.onDeleteItem!(item);
          hideOverlay(null);
          _showOverlay(context);
        });
      }
    }
  }

  void hideOverlay(ValueItem? val) {
    setState(() {
      overlayEntry?.remove();
      overlayEntry = null;
      aberto = !aberto;
      if (val != null) {
        widget.updateSelectedItem(val);
        controllerBar.text = val.label;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.dropdownwidth,
      height: widget.dropdownHeight,
      child: SearchBar(
        key: overlayKey,
        trailing: widget.actions ??
            [
              aberto
                  ? Icon(
                      widget.dropdownEnableActionIcon ?? Icons.arrow_drop_up,
                      color: widget.outsideIconColor,
                      size: widget.outsideIconSize,
                    )
                  : Icon(
                      widget.dropdownDisableActionIcon ?? Icons.arrow_drop_down,
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
                      onPressed: () {
                        setState(
                          () => clearSelection(),
                        );
                      },
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
        overlayColor:
            MaterialStatePropertyAll(widget.hoverColor ?? Colors.grey.shade100),
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
          if (overlayEntry == null) {
            _showOverlay(context);
          } else {
            hideOverlay(null);
          }
        },
        onChanged: (a) {
          _filtrarLista(a);
          hideOverlay(null);
          _showOverlay(context);
        },
        elevation: MaterialStateProperty.all<double>(
          widget.elevation,
        ),
      ),
    );
  }
}
