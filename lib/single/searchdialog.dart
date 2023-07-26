import 'package:flutter/material.dart';
import 'package:searchdialog/single/listview.dart';
import 'package:stringr/stringr.dart';

class SearchDialog extends StatefulWidget {
  const SearchDialog({
    super.key,
    this.actions,
    this.animationDuration,
    this.backgroundColor,
    this.border,
    required this.controllerBar,
    this.dialogBackgroundColor,
    this.dialogHeight = 300,
    this.elevation = 2,
    this.hint,
    this.hintStyle,
    this.hoverColor,
    required this.listItens,
    required this.onDeleteItem,
    this.selectedDialogColor,
    this.selectedInsideBoxTextStyle,
    this.unselectedInsideBoxTextStyle,
    this.widgetBuilder,
    this.width = 300,
  });

  final List<Widget>? actions;
  final Duration? animationDuration;
  final Color? backgroundColor;
  final OutlinedBorder? border;
  final TextEditingController controllerBar;
  final Color? dialogBackgroundColor;
  final double dialogHeight;
  final double elevation;
  final String? hint;
  final TextStyle? hintStyle;
  final Color? hoverColor;
  final List<String> listItens;
  final Function(String) onDeleteItem;
  final Color? selectedDialogColor;
  final TextStyle? selectedInsideBoxTextStyle;
  final TextStyle? unselectedInsideBoxTextStyle;
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

   void clearSelectedItem() {
    if (widget.listItens.contains(widget.controllerBar.text)) {
      widget.listItens.remove(widget.controllerBar.text);
      widget.controllerBar.clear();
      setState(() {});
    }
  }

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
                animationDuration: widget.animationDuration, 
                backgroundColor: widget.backgroundColor, 
                controllerBar: widget.controllerBar, 
                dialogBackgroundColor: widget.dialogBackgroundColor, 
                dialogHeight: widget.dialogHeight, 
                elevation: widget.elevation, 
                hoverColor: widget.hoverColor, 
                listaFiltrada: listafiltrada, 
                onClear: (val) => handleDeleteItem(val, context),
                onPressed: (val) => hideOverlay(val), 
                selectedDialogColor: widget.selectedDialogColor, 
                selectedInsideBoxTextStyle: widget.selectedInsideBoxTextStyle, 
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

  void handleDeleteItem(String item, BuildContext context) {
    widget.onDeleteItem(item); 
    hideOverlay(null);
    showOverlay(context);
  }

  void hideOverlay(String? val) {
    overlayEntry?.remove();
    overlayEntry = null;
    setState(() {
      aberto = !aberto;
      if (val != null) widget.controllerBar.text = val;
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
                visible: widget.controllerBar.text != '',
                child: Row(
                  children: [
                    const SizedBox(
                      width: 5,
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          widget.controllerBar.clear();
                        });
                      },  
                      icon: const Icon(Icons.clear)
                    ),
                  ],
                ),
              ),
            ],
        controller: widget.controllerBar,
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
