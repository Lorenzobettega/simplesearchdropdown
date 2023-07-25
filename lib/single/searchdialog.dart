import 'package:flutter/material.dart';
import 'package:searchdialog/single/listview.dart';
import 'package:stringr/stringr.dart';

class SearchDialog extends StatefulWidget {
  const SearchDialog({
    super.key,
    required this.controllerBar,
    required this.listItens,
    this.dialogHeight = 300,
    this.animationDuration,
    this.hint,
    this.border,
    this.width = 300,
    this.widgetBuilder,
    this.elevation = 2,
    this.backgroundColor,
    this.dialogBackgroundColor,
    this.hintStyle,
    this.hoverColor,
    this.selectedDialogColor,
    this.selectedInsideBoxTextStyle,
    this.unselectedInsideBoxTextStyle,
    this.actions,
  });

  final TextEditingController controllerBar;
  final List<String> listItens;
  final double dialogHeight;
  final Duration? animationDuration;
  final String? hint;
  final OutlinedBorder? border;
  final double width;
  final Widget? widgetBuilder;
  final double elevation;
  final Color? backgroundColor;
  final Color? dialogBackgroundColor;
  final Color? hoverColor;
  final TextStyle? hintStyle;
  final Color? selectedDialogColor;
  final TextStyle? selectedInsideBoxTextStyle;
  final TextStyle? unselectedInsideBoxTextStyle;
  final List<Widget>? actions;

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
              child: Card(
                surfaceTintColor: widget.dialogBackgroundColor ??
                    widget.backgroundColor ??
                    Colors.white,
                color: widget.dialogBackgroundColor ??
                    widget.backgroundColor ??
                    Colors.white,
                elevation: widget.elevation,
                child: AnimatedContainer(
                  duration: widget.animationDuration ??
                      const Duration(milliseconds: 100),
                  height: widget.dialogHeight,
                  width: widget.width,
                  child: NovoListView(
                    listaFiltrada: listafiltrada,
                    controllerBar: widget.controllerBar,
                    widgetBuilder: widget.widgetBuilder,
                    hoverColor: widget.hoverColor,
                    selectedDialogColor: widget.selectedDialogColor,
                    selectedInsideBoxTextStyle:
                        widget.selectedInsideBoxTextStyle,
                    unselectedInsideBoxTextStyle:
                        widget.unselectedInsideBoxTextStyle,
                    onPressed: (val) => hideOverlay(val),
                  ),
                ),
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
                      onPressed: () => widget.controllerBar.clear(), 
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
