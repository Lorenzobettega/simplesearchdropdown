import 'package:flutter/material.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';
import 'package:stringr/stringr.dart';

class MultipleListView<T> extends StatefulWidget {
  const MultipleListView({
    super.key,
    required this.addMode,
    required this.animationDuration,
    required this.backgroundColor,
    required this.border,
    required this.createHint,
    required this.createHintStyle,
    required this.deleteMode,
    required this.unselectedItemHoverColor,
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
    required this.itemsPadding,
    required this.selectedDialogBoxColor,
    required this.selectedInsideBoxTextStyle,
    required this.selectedItemHoverColor,
    required this.selectedItens,
    required this.separatorHeight,
    required this.sortSelecteds,
    required this.unselectedInsideBoxTextStyle,
    required this.width,
    required this.minHeight,
    required this.newValueItem,
  });

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
  final Widget? dialogListviewWidgetBuilder;
  final OutlinedBorder? dialogSearchBarBorder;
  final Color? dialogSearchBarColor;
  final double dialogSearchBarElevation;
  final double elevation;
  final Function(ValueItem<T> value) onAddItem;
  final Function(ValueItem<T> value) onDeleteItem;
  final Function(ValueItem<T> value) onItemSelected;
  final EdgeInsets? itemsPadding;
  final TextStyle? hintStyle;
  final String? hintSearchBar;
  final List<ValueItem<T>> listItens;
  final List<ValueItem<T>> selectedItens;
  final Color? selectedDialogBoxColor;
  final TextStyle? selectedInsideBoxTextStyle;
  final Color? selectedItemHoverColor;
  final double? separatorHeight;
  final bool sortSelecteds;
  final TextStyle? unselectedInsideBoxTextStyle;
  final Color? unselectedItemHoverColor;
  final double width;
  final double minHeight;
  final ValueItem<T> Function(String input)? newValueItem;

  @override
  State<MultipleListView<T>> createState() => _MultipleListViewState<T>();
}

class _MultipleListViewState<T> extends State<MultipleListView<T>> {
  List<ValueItem<T>> listaFiltrada = [];
  final TextEditingController controllerBar = TextEditingController();
  final controller = ScrollController();

  @override
  void initState() {
    super.initState();
    filtrarLista(null);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.selectedItens.isNotEmpty) {
        goToSelectedItem(widget.selectedItens.first);
      }
    });
  }

  void organizarLista() {
    List<ValueItem<T>> selecionado = listaFiltrada
        .where((item) => widget.selectedItens.contains(item))
        .toList();
    if (selecionado.isNotEmpty) {
      listaFiltrada.removeWhere((item) => widget.selectedItens.contains(item));
      listaFiltrada.insertAll(0, selecionado);
    }
  }

  void filtrarLista(
    String? text,
  ) {
    if (text != null && text != '') {
      listaFiltrada = widget.listItens
          .where((element) => element.label
              .toLowerCase()
              .latinize()
              .contains(text.toLowerCase()))
          .toList();
    } else {
      listaFiltrada = widget.listItens;
    }
    widget.sortSelecteds
        ? setState(() {
            organizarLista();
          })
        : null;
  }

  void addItem(ValueItem<T> value) {
    widget.onItemSelected.call(value);
    widget.sortSelecteds
        ? setState(() {
            organizarLista();
          })
        : null;
  }

  ///Function to scroll the list to the selected item
  void goToSelectedItem(ValueItem<T> item) {
    final index = listaFiltrada.indexOf(item);
    if (index > 0) {
      final contentSize = controller.position.viewportDimension +
          controller.position.maxScrollExtent;

      final target = contentSize * index / listaFiltrada.length;
      controller.position.animateTo(
        target,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      surfaceTintColor: widget.dialogBackgroundColor ??
          widget.backgroundColor ??
          Colors.white,
      color: widget.dialogBackgroundColor ??
          widget.backgroundColor ??
          Colors.white,
      elevation: widget.elevation,
      child: AnimatedContainer(
        duration: widget.animationDuration ?? const Duration(milliseconds: 100),
        height: widget.dialogHeight,
        width: widget.width,
        child: Column(
          children: [
            SearchBar(
              controller: controllerBar,
              backgroundColor: MaterialStatePropertyAll(
                  widget.dialogSearchBarColor ?? Colors.white),
              overlayColor: MaterialStatePropertyAll(
                  widget.unselectedItemHoverColor ?? Colors.grey.shade100),
              constraints: BoxConstraints(
                  minHeight: widget.minHeight, maxWidth: widget.width),
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
                controller: controller,
                padding: EdgeInsets.zero,
                scrollDirection: Axis.vertical,
                itemCount: listaFiltrada.length + (widget.addMode ? 1 : 0),
                separatorBuilder: (context, index) => SizedBox(
                  height: widget.separatorHeight ?? 1,
                ),
                itemBuilder: (context, index) {
                  if (index == listaFiltrada.length && widget.addMode) {
                    if (controllerBar.text != '') {
                      final list = listaFiltrada
                          .where(
                            (element) => element.label
                                .toLowerCase()
                                .latinize()
                                .contains(
                                  controllerBar.text.toLowerCase().latinize(),
                                ),
                          )
                          .toList();
                      if (list.isEmpty) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(controllerBar.text),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  final item =
                                      widget.newValueItem!(controllerBar.text);
                                  widget.onAddItem(item);
                                  listaFiltrada.add(item);
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
                            padding: widget.itemsPadding ??
                                const EdgeInsets.symmetric(horizontal: 4),
                            child: TextButton(
                              style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.resolveWith<Color>(
                                  (Set<MaterialState> states) {
                                    if (widget.selectedItens
                                        .contains(listaFiltrada[index])) {
                                      return widget.selectedDialogBoxColor ??
                                          Colors.black38;
                                    }
                                    return Colors.transparent;
                                  },
                                ),
                                shape:
                                    MaterialStateProperty.all<OutlinedBorder>(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                overlayColor:
                                    MaterialStateProperty.resolveWith<Color>(
                                  (Set<MaterialState> states) {
                                    if (widget.selectedItens
                                        .contains(listaFiltrada[index])) {
                                      return widget.selectedItemHoverColor ??
                                          Colors.grey.shade300;
                                    }
                                    return widget.unselectedItemHoverColor ??
                                        Colors.grey.shade100;
                                  },
                                ),
                              ),
                              onPressed: () => addItem(listaFiltrada[index]),
                              child: widget.dialogListviewWidgetBuilder ??
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      listaFiltrada[index].label,
                                      style: (controllerBar.text ==
                                              listaFiltrada[index].label
                                          ? widget.selectedInsideBoxTextStyle ??
                                              const TextStyle(
                                                  color: Colors.black)
                                          : widget.unselectedInsideBoxTextStyle ??
                                              const TextStyle(
                                                  color: Colors.black45)),
                                    ),
                                  ),
                            ),
                          ),
                        ),
                        widget.deleteMode
                            ? widget.dialogActionWidget ??
                                IconButton(
                                  onPressed: () {
                                    widget.onDeleteItem(listaFiltrada[index]);
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
    );
  }
}
