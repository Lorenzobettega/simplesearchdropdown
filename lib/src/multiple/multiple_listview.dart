import 'package:flutter/material.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';
import 'package:stringr/stringr.dart';

class MultipleListView<T> extends StatefulWidget {
  const MultipleListView({
    super.key,
    required this.addMode,
    required this.overlayListSettings,
    required this.deleteMode,
    required this.listItens,
    required this.onAddItem,
    required this.onDeleteItem,
    required this.onItemSelected,
    required this.selectedItens,
    required this.sortType,
    required this.newValueItem,
    required this.searchBarSettings,
  });

  final bool addMode;
  final bool deleteMode;
  final Function(ValueItem<T> value) onAddItem;
  final Function(ValueItem<T> value) onDeleteItem;
  final Function(ValueItem<T> value) onItemSelected;
  final List<ValueItem<T>> listItens;
  final List<ValueItem<T>> selectedItens;
  final int sortType;

  ///The settings for the overlay list of items.
  final SimpleOverlaySettings overlayListSettings;

  ///The SearchBarSettings.
  final SimpleSearchbarSettings searchBarSettings;
  final ValueItem<T> Function(String input)? newValueItem;

  @override
  State<MultipleListView<T>> createState() => _MultipleListViewState<T>();
}

class _MultipleListViewState<T> extends State<MultipleListView<T>> {
  List<ValueItem<T>> listaFiltrada = [];
  final GlobalKey _itemKey = GlobalKey();
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

  void itemAdded(String text) {
    setState(() {
      final item = widget.newValueItem!(text);
      widget.onAddItem(item);
      listaFiltrada.add(item);
      controllerBar.clear();
    });
    filtrarLista(null);
  }

  void addItem(ValueItem<T> value) {
    widget.onItemSelected.call(value);
    widget.sortType > 0
        ? setState(() {
            sortFunction();
          })
        : setState(() {});
  }

  ///Function to scroll the list to the selected item
  void goToSelectedItem(ValueItem<T> item) {
    final index = listaFiltrada.indexOf(item);
    final double separator = widget.overlayListSettings.separatorHeight;
    final context = _itemKey.currentContext;
    if (index > 1 && context != null) {
      controller.position.animateTo(
        index * (context.size!.height + separator),
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Card(
          surfaceTintColor: widget.overlayListSettings.dialogBackgroundColor ??
              widget.searchBarSettings.backgroundColor,
          color: widget.overlayListSettings.dialogBackgroundColor ??
              widget.searchBarSettings.backgroundColor,
          elevation: widget.searchBarSettings.elevation,
          child: AnimatedContainer(
            duration: widget.overlayListSettings.animationDuration,
            height: widget.overlayListSettings.dialogHeight,
            width: widget.searchBarSettings.dropdownWidth,
            child: Column(
              children: [
                SearchBar(
                  controller: controllerBar,
                  backgroundColor: MaterialStatePropertyAll(
                      widget.searchBarSettings.backgroundColor),
                  overlayColor: MaterialStatePropertyAll(
                      widget.overlayListSettings.unselectedItemHoverColor),
                  constraints: BoxConstraints(
                      minHeight: widget.searchBarSettings.dropdownHeight,
                      maxWidth: widget.searchBarSettings.dropdownWidth),
                  surfaceTintColor: MaterialStatePropertyAll(
                      widget.searchBarSettings.backgroundColor),
                  shape: MaterialStatePropertyAll(widget.searchBarSettings.border),
                  hintText: widget.searchBarSettings.hint,
                  hintStyle: MaterialStateProperty.all<TextStyle?>(
                    widget.searchBarSettings.hintStyle,
                  ),
                  textStyle: MaterialStateProperty.all<TextStyle?>(
                    widget.searchBarSettings.searchBarTextStyle,
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
                      widget.searchBarSettings.elevation),
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
                      height: widget.overlayListSettings.separatorHeight,
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
                            return DefaultAddListItem(
                              itemAdded: itemAdded,
                              overlayListSettings: widget.overlayListSettings,
                              text: controllerBar.text,
                            );
                          }
                        }
                        return const SizedBox.shrink();
                      } else {
                        return DefaultListTile<T>(
                          deleteMode: widget.deleteMode,
                          item: listaFiltrada[index],
                          onDelete: widget.onDeleteItem,
                          onPressed: addItem,
                          overlayListSettings: widget.overlayListSettings,
                          selected:
                              widget.selectedItens.contains(listaFiltrada[index]),
                          key: index == 0 ? _itemKey : null,
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
