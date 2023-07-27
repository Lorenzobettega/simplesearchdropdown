import 'package:flutter/material.dart';
import 'package:search_dialog/search_dialog.dart';
import 'package:stringr/stringr.dart';

class SearchDialog extends StatefulWidget {
  const SearchDialog({
    super.key,
    this.actions,
    required this.addMode,
    this.animationDuration,
    this.backgroundColor,
    this.border,
    this.createHint,
    this.createHintStyle,
    required this.deleteMode,
    this.dialogActionIcon,
    this.dialogActionWidget,
    this.dialogBackgroundColor,
    this.dialogHeight = 300,
    this.elevation = 2,
    this.hint,
    this.hintStyle,
    this.hoverColor,
    required this.listItens,
    this.onAddItem,
    this.onDeleteItem,
    this.selectedDialogColor,
    this.selectedInsideBoxTextStyle,
    this.sortSelecteds = true,
    this.unselectedInsideBoxTextStyle,
    required this.updateSelectedItem,
    this.widgetBuilder,
    this.width = 300,
  });

  final List<Widget>? actions;
  final bool addMode;
  final Duration? animationDuration;
  final Color? backgroundColor;
  final OutlinedBorder? border;
  final String? createHint;
  final TextStyle? createHintStyle;
  final bool deleteMode;
  final Icon? dialogActionIcon;
  final Widget? dialogActionWidget;
  final Color? dialogBackgroundColor;
  final double dialogHeight;
  final double elevation;
  final String? hint;
  final TextStyle? hintStyle;
  final Color? hoverColor;
  final List<String> listItens;
  final Function(String)? onAddItem;
  final Function(String)? onDeleteItem;
  final Color? selectedDialogColor;
  final TextStyle? selectedInsideBoxTextStyle;
  final bool sortSelecteds;
  final TextStyle? unselectedInsideBoxTextStyle;
  final Function(String) updateSelectedItem;
  final Widget? widgetBuilder;
  final double width;

  @override
  State<SearchDialog> createState() => SearchDialogState();
}

class SearchDialogState extends State<SearchDialog> {
  @override
  void initState() {
    super.initState();
    _filtrarLista(null, start: true);
  }

  List<String> listafiltrada = [];
  OverlayEntry? overlayEntry;
  final GlobalKey overlayKey = GlobalKey();
  bool aberto = false;
  final TextEditingController controllerBar = TextEditingController();

  void _filtrarLista(String? text, {bool start = false}) {
    if (start) {
      listafiltrada = widget.listItens;
    } else {
      if (text != null && text != '') {
        listafiltrada = widget.listItens
            .where(
                (element) => element.toLowerCase().latinize().contains(text.toLowerCase()))
            .toList();
      } else {
        listafiltrada = widget.listItens;
      }
    }
  }

  void showOverlay(
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
                onAddItem: (val) => handleAddItem(val, context,),
                onClear: (val) => handleDeleteItem(val, context,),
                onPressed: (val) => hideOverlay(val), 
                selectedDialogColor: widget.selectedDialogColor, 
                selectedInsideBoxTextStyle: widget.selectedInsideBoxTextStyle, 
                sortSelecteds: widget.sortSelecteds,
                unselectedInsideBoxTextStyle: widget.unselectedInsideBoxTextStyle, 
                widgetBuilder: widget.widgetBuilder, 
                width: widget.width
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

  void handleAddItem(String item, BuildContext context){
    if(widget.addMode){
      widget.onAddItem!(item);
      hideOverlay(item);
      setState(() {});
    }
  }

  void handleDeleteItem(String item, BuildContext context) {
    if(widget.deleteMode){
      widget.onDeleteItem!(item);
      hideOverlay(null);
      setState(() {});
      showOverlay(context);
    }
  }

  void hideOverlay(String? val) {
    overlayEntry?.remove();
    overlayEntry = null;
    setState(() {
      aberto = !aberto;
      if (val != null) {
        widget.updateSelectedItem(val);
        controllerBar.text = val;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: 50,
      child: SearchBar(
        key: overlayKey,
        trailing: widget.actions ??
            [
              aberto
                  ? const Icon(Icons.arrow_drop_up)
                  : const Icon(Icons.arrow_drop_down),
              Visibility(
                visible: controllerBar.text != '',
                child: Row(
                  children: [
                    const SizedBox(
                      width: 5,
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          controllerBar.clear();
                          _filtrarLista(null);
                        });
                      },  
                      icon: const Icon(Icons.clear)
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
        constraints: BoxConstraints(maxHeight: 50, maxWidth: widget.width),
        surfaceTintColor:
            MaterialStatePropertyAll(widget.backgroundColor ?? Colors.white),
        shape: MaterialStateProperty.all<OutlinedBorder>(widget.border ??
            const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10.0)))),
        hintText: widget.hint ?? 'Selecione',
        side: MaterialStateProperty.all<BorderSide>(
          const BorderSide(
            style: BorderStyle.none,
          ),
        ),
        onTap: () {
          if (overlayEntry == null) {
            showOverlay(context);
          } else {
            hideOverlay(null);
          }
        },
        onChanged: (a) {
          _filtrarLista(a);
          hideOverlay(null);
          showOverlay(context);
        },
        elevation: MaterialStateProperty.all<double>(
          widget.elevation,
        ),
      ),
    );
  }
}
