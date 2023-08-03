import 'package:flutter/material.dart';
import 'package:stringr/stringr.dart';

class ContentMultiple extends StatefulWidget {
  const ContentMultiple({
    super.key,
    required this.addMode,
    required this.activeHoverColor,
    required this.animationDuration,
    required this.backgroundColor,
    required this.border,
    required this.createHint,
    required this.createHintStyle,
    required this.deleteMode,
    required this.deactivateHoverColor,
    required this.dialogActionIcon,
    required this.dialogActionWidget,
    required this.dialogBackgroundColor,
    required this.dialogHeight,
    required this.dialogListviewWidgetBuilder,
    required this.dialogSearchBarBorder,
    required this.dialogSearchBarColor,
    required this.dialogSearchBarElevation,
    required this.elevation,
    required this.hintSearchBar,
    required this.hintStyle,
    required this.listItens,
    required this.onAddItem,
    required this.onDeleteItem,
    required this.onItemSelected,
    required this.selectedDialogBoxColor,
    required this.selectedDialogColor,
    required this.selectedInsideBoxTextStyle,
    required this.selectedItens,
    required this.sortSelecteds,
    required this.unselectedInsideBoxTextStyle,
    required this.updateSelectedItems,
    required this.width,
  });

  final bool addMode;
  final Color? activeHoverColor;
  final Duration? animationDuration;
  final Color? backgroundColor;
  final OutlinedBorder? border;
  final String? createHint;
  final TextStyle? createHintStyle;
  final bool deleteMode;
  final Color? deactivateHoverColor;
  final Icon? dialogActionIcon;
  final Widget? dialogActionWidget;
  final Color? dialogBackgroundColor;
  final double dialogHeight;
  final OutlinedBorder? dialogSearchBarBorder;
  final Color? dialogSearchBarColor;
  final double dialogSearchBarElevation;
  final double elevation;
  final Function(String) onAddItem;
  final Function(String) onDeleteItem;
  final Function(String value) onItemSelected;
  final Widget? dialogListviewWidgetBuilder;
  final TextStyle? hintStyle;
  final String? hintSearchBar;
  final List<String> listItens;
  final List<String> selectedItens;
  final Color? selectedDialogBoxColor;
  final Color? selectedDialogColor;
  final TextStyle? selectedInsideBoxTextStyle;
  final bool sortSelecteds;
  final TextStyle? unselectedInsideBoxTextStyle;
  final Function(List<String>) updateSelectedItems;
  final double width;

  @override
  State<ContentMultiple> createState() => _ContentMultipleState();
}

class _ContentMultipleState extends State<ContentMultiple> {
  List<String> listafiltrada = [];
  final TextEditingController controllerBar = TextEditingController();

  @override
  void initState() {
    super.initState();
    filtrarLista(null);
  }

  void organizarLista() {
    List<String>? selecionado = listafiltrada
        .where((item) => widget.selectedItens.contains(item))
        .toList();
    if (selecionado.isNotEmpty) {
      listafiltrada.removeWhere((item) => widget.selectedItens.contains(item));
      listafiltrada.insertAll(0, selecionado);
    }
  }

  void filtrarLista(
    String? text,
  ) {
    if (text != null && text != '') {
      listafiltrada = widget.listItens
          .where((element) =>
              element.toLowerCase().latinize().contains(text.toLowerCase()))
          .toList();
    } else {
      listafiltrada = widget.listItens;
    }
    widget.sortSelecteds
        ? setState(() {
            organizarLista();
          })
        : null;
  }

  void addItem(String value) {
    widget.onItemSelected.call(value);
    widget.sortSelecteds
        ? setState(() {
            organizarLista();
          })
        : null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          surfaceTintColor: widget.dialogBackgroundColor ??
              widget.backgroundColor ??
              Colors.white,
          color: widget.dialogBackgroundColor ??
              widget.backgroundColor ??
              Colors.white,
          elevation: widget.elevation,
          child: AnimatedContainer(
            duration:
                widget.animationDuration ?? const Duration(milliseconds: 100),
            height: widget.dialogHeight,
            width: widget.width,
            child: Column(
              children: [
                SearchBar(
                  controller: controllerBar,
                  backgroundColor: MaterialStatePropertyAll(
                      widget.dialogSearchBarColor ?? Colors.white),
                  overlayColor: MaterialStatePropertyAll(
                      widget.deactivateHoverColor ?? Colors.grey.shade100),
                  constraints:
                      BoxConstraints(maxHeight: 50, maxWidth: widget.width),
                  surfaceTintColor: MaterialStatePropertyAll(
                      widget.dialogSearchBarColor ?? Colors.white),
                  shape: MaterialStateProperty.all<OutlinedBorder>(
                    widget.dialogSearchBarBorder ??
                        const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(
                            Radius.circular(10.0),
                          ),
                        ),
                  ),
                  hintText: widget.hintSearchBar ?? 'Pesquisar',
                  hintStyle: MaterialStateProperty.all<TextStyle>(
                    widget.hintStyle ?? const TextStyle(fontSize: 14),
                  ),
                  side: MaterialStateProperty.all<BorderSide>(
                    const BorderSide(
                      style: BorderStyle.none,
                    ),
                  ),
                  onChanged: (a) {
                    filtrarLista(a);
                  },
                  elevation: MaterialStateProperty.all<double>(
                      widget.dialogSearchBarElevation),
                ),
                const SizedBox(
                  height: 5,
                ),
                Expanded(
                  child: ListView.separated(
                    scrollDirection: Axis.vertical,
                    itemCount: listafiltrada.length + (widget.addMode ? 1 : 0),
                    separatorBuilder: (context, index) => const SizedBox(
                      height: 1,
                    ),
                    itemBuilder: (context, index) {
                      if (index == listafiltrada.length && widget.addMode) {
                        if (controllerBar.text != '') {
                          final list = listafiltrada
                              .where(
                                (element) =>
                                    element.toLowerCase().latinize().contains(
                                          controllerBar.text
                                              .toLowerCase()
                                              .latinize(),
                                        ),
                              )
                              .toList();
                          if (list.isEmpty) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  child: Text(controllerBar.text),
                                ),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      widget.onAddItem(controllerBar.text);
                                      listafiltrada.add(controllerBar.text);
                                    });
                                  },
                                  child: Text(
                                    widget.createHint ?? 'Criar',
                                    style: widget.createHintStyle,
                                  ),
                                ),
                              ],
                            );
                          }
                        }
                        return const SizedBox.shrink();
                      } else {
                        return Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 5),
                                child: TextButton(
                                    style: ButtonStyle(
                                      backgroundColor: MaterialStateProperty
                                          .resolveWith<Color>(
                                        (Set<MaterialState> states) {
                                          if (widget.selectedItens
                                              .contains(listafiltrada[index])) {
                                            return widget
                                                    .selectedDialogBoxColor ??
                                                Colors.black38;
                                          }
                                          return Colors.transparent;
                                        },
                                      ),
                                      shape: MaterialStateProperty.all<
                                          OutlinedBorder>(
                                        RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      overlayColor: MaterialStateProperty
                                          .resolveWith<Color>(
                                        (Set<MaterialState> states) {
                                          if (widget.selectedItens
                                              .contains(listafiltrada[index])) {
                                            return widget.activeHoverColor ??
                                                Colors.grey.shade400;
                                          }
                                          return widget.deactivateHoverColor ??
                                              Colors.grey.shade100;
                                        },
                                      ),
                                    ),
                                    onPressed: () =>
                                        addItem(listafiltrada[index]),
                                    child: widget.dialogListviewWidgetBuilder ??
                                        Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              listafiltrada[index],
                                              style: (controllerBar.text ==
                                                      listafiltrada[index]
                                                  ? widget.selectedInsideBoxTextStyle ??
                                                      const TextStyle(
                                                          color: Colors.black)
                                                  : widget.unselectedInsideBoxTextStyle ??
                                                      const TextStyle(
                                                          color:
                                                              Colors.black45)),
                                            ))),
                              ),
                            ),
                            widget.deleteMode
                                ? widget.dialogActionWidget ??
                                    IconButton(
                                      onPressed: () {
                                        widget
                                            .onDeleteItem(listafiltrada[index]);
                                      },
                                      icon: widget.dialogActionIcon ??
                                          Icon(
                                            Icons.delete,
                                            color: Colors.red.shade900,
                                            size: 20,
                                          ),
                                    )
                                : const SizedBox.shrink()
                          ],
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
