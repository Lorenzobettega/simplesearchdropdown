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
    required this.selectedItemsColor,
    required this.selectedItemsTextStyle,
    required this.selectedItemHoverColor,
    required this.selectedItens,
    required this.separatorHeight,
    required this.sortType,
    required this.unselectedItemsTextStyle,
    required this.dropdownWidth,
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
  final Color? selectedItemsColor;
  final TextStyle? selectedItemsTextStyle;
  final Color? selectedItemHoverColor;
  final double? separatorHeight;
  final int sortType;
  final TextStyle? unselectedItemsTextStyle;
  final Color? unselectedItemHoverColor;
  final double dropdownWidth;
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
        if (widget.selectedItens.isNotEmpty) {
          final first = widget.selectedItens.first;
          final indx = listaFiltrada.indexOf(first);
          if (indx != -1) {
            listaFiltrada.removeAt(indx);
            listaFiltrada.insert(0, first);
          }
        }
        break;
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
    widget.sortType > 0
        ? setState(() {
            sortFunction();
          })
        : setState(() {});
  }

  void addItem(ValueItem<T> value) {
    widget.onItemSelected.call(value);
    widget.sortType > 0
        ? setState(() {
            sortFunction();
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
        width: widget.dropdownWidth,
        child: Column(
          children: [
            SearchBar(
              controller: controllerBar,
              backgroundColor: MaterialStatePropertyAll(
                  widget.dialogSearchBarColor ?? Colors.white),
              overlayColor: MaterialStatePropertyAll(
                  widget.unselectedItemHoverColor ?? Colors.grey.shade100),
              constraints: BoxConstraints(
                  minHeight: widget.minHeight, maxWidth: widget.dropdownWidth),
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
                                  controllerBar.clear();
                                });
                                filtrarLista(null);
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
                                      return widget.selectedItemsColor ??
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
                                      style: (widget.selectedItens
                                              .contains(listaFiltrada[index])
                                          ? widget.selectedItemsTextStyle ??
                                              const TextStyle(
                                                  color: Colors.black)
                                          : widget.unselectedItemsTextStyle ??
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
