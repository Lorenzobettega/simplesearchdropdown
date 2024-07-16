import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
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
    required this.addAditionalWidget,
    required this.defaultAditionalWidget,
  });

  final bool addMode;
  final bool deleteMode;
  final Function(ValueItem<T> value) onAddItem;
  final Function(ValueItem<T> value) onDeleteItem;
  final Function(ValueItem<T> value) onItemSelected;
  final List<ValueItem<T>> listItens;
  final List<ValueItem<T>> selectedItens;
  final int sortType;
  final Widget? addAditionalWidget;
  final Widget? defaultAditionalWidget;

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
  final TextEditingController controllerBar = TextEditingController();
  final ItemScrollController scrollController = ItemScrollController();
  final PageStorageBucket pageStorageBucket = PageStorageBucket();

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
            listaFiltrada
              ..removeAt(indx)
              ..insert(0, first);
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
              .contains(text.latinize().toLowerCase()))
          .toList();
    } else {
      listaFiltrada = widget.listItens;
    }
    widget.sortType > 0 ? setState(sortFunction) : setState(() {});
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
    widget.sortType > 0 ? setState(sortFunction) : setState(() {});
  }

  ///Function to scroll the list to the selected item
  void goToSelectedItem(ValueItem<T> item) {
    final index = listaFiltrada.indexOf(item);
    if (index > 1) {
      scrollController.scrollTo(
        index: index,
        duration: widget.overlayListSettings.reOpenedScrollDuration,
        curve: Curves.ease,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
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
              backgroundColor: WidgetStatePropertyAll(
                  widget.searchBarSettings.backgroundColor),
              overlayColor: WidgetStatePropertyAll(
                  widget.overlayListSettings.unselectedItemHoverColor),
              constraints: BoxConstraints(
                  minHeight: widget.searchBarSettings.dropdownHeight,
                  maxWidth: widget.searchBarSettings.dropdownWidth),
              surfaceTintColor: WidgetStatePropertyAll(
                  widget.searchBarSettings.backgroundColor),
              shape: WidgetStatePropertyAll(widget.searchBarSettings.border),
              hintText: widget.searchBarSettings.hint,
              hintStyle: WidgetStateProperty.all<TextStyle?>(
                widget.searchBarSettings.hintStyle,
              ),
              textStyle: WidgetStatePropertyAll(
                  widget.searchBarSettings.searchBarTextStyle ??
                      widget.searchBarSettings.hintStyle),
              side: WidgetStateProperty.all<BorderSide>(
                const BorderSide(
                  style: BorderStyle.none,
                ),
              ),
              onChanged: filtrarLista,
              elevation: WidgetStateProperty.all<double>(
                  widget.searchBarSettings.elevation),
            ),
            const SizedBox(
              height: 5,
            ),
            Expanded(
              child: PageStorage(
                bucket: pageStorageBucket,
                child: ScrollablePositionedList.separated(
                  itemScrollController: scrollController,
                  padding: EdgeInsets.zero,
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
                                    controllerBar.text.latinize().toLowerCase(),
                                  ),
                            )
                            .toList();
                        if (list.isEmpty) {
                          return DefaultAddListItem(
                            itemAdded: itemAdded,
                            overlayListSettings: widget.overlayListSettings,
                            text: controllerBar.text,
                            addAditionalWidget: widget.addAditionalWidget,
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
                        defaultAditionalWidget: widget.defaultAditionalWidget,
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
