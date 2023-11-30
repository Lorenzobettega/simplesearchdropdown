import 'package:flutter/material.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';
import 'package:stringr/stringr.dart';

///This creates the list that contains the items to be selected.
class SingleListView<T> extends StatelessWidget {
  const SingleListView({
    required this.addMode,
    required this.onAddItem,
    required this.newValueItem,
    required this.backgroundColor,
    required this.controllerBar,
    required this.deleteMode,
    required this.elevation,
    required this.listaFiltrada,
    required this.onDelete,
    required this.onPressed,
    required this.sortType,
    required this.overlayListSettings,
    required this.dropdownwidth,
    required this.selectedItem,
    super.key,
  });

  ///Allow the user to add items to the list.
  final bool addMode;

  ///Function to be executed after the item was added.
  final Function(ValueItem<T> value) onAddItem;

  ///Function that defines how the user input transforms into a new ValueItem on the list.
  final ValueItem<T> Function(String input)? newValueItem;

  ///The overlay list of items settings.
  final SimpleOverlaySettings overlayListSettings;
  final Color? backgroundColor;
  final TextEditingController controllerBar;
  final bool deleteMode;
  final double elevation;
  final List<ValueItem<T>> listaFiltrada;
  final Function(ValueItem<T> value) onDelete;
  final Function(ValueItem<T> value) onPressed;
  final int sortType;
  final double dropdownwidth;
  final ValueItem<T>? selectedItem;

  void sortFunction() {
    switch (sortType) {
      case 0:
        break;
      case 1:
        listaFiltrada.sort((a, b) => a.label.compareTo(b.label));
        break;
      case 2:
        listaFiltrada.sort((a, b) => b.label.compareTo(a.label));
        break;
      case 3:
        if (selectedItem != null) {
          final indx = listaFiltrada.indexOf(selectedItem!);
          if (indx != -1) {
            listaFiltrada.removeAt(indx);
            listaFiltrada.insert(0, selectedItem!);
          }
        }
        break;
    }
  }

  ///Function to scroll the list to the selected item
  ///only works if the size of all tiles is equal.
  void goToSelectedItem(
      ScrollController controller, ValueItem<T> item, GlobalKey key) {
    final index = listaFiltrada.indexOf(item);
    final double separator = overlayListSettings.separatorHeight;
    final context = key.currentContext;
    if (index > 1 && context != null) {
      controller.position.animateTo(
        index * (context.size!.height + separator),
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
      );
    }
  }

  void itemAdded(String text) {
    final item = newValueItem!(text);
    onAddItem(item);
    listaFiltrada.add(item);
  }

  @override
  Widget build(BuildContext context) {
    final controller = ScrollController();
    final GlobalKey _itemKey = GlobalKey();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (selectedItem != null) {
        goToSelectedItem(controller, selectedItem!, _itemKey);
      }
    });
    return Card(
      surfaceTintColor:
          overlayListSettings.dialogBackgroundColor ?? backgroundColor,
      color: overlayListSettings.dialogBackgroundColor ?? backgroundColor,
      elevation: elevation,
      child: AnimatedContainer(
        duration: overlayListSettings.animationDuration,
        height: overlayListSettings.dialogHeight,
        width: dropdownwidth,
        child: ListView.separated(
          controller: controller,
          padding: EdgeInsets.zero,
          itemCount: listaFiltrada.length + (addMode ? 1 : 0),
          separatorBuilder: (context, index) => SizedBox(
            height: overlayListSettings.separatorHeight,
          ),
          itemBuilder: (context, index) {
            sortFunction();
            if (index == listaFiltrada.length && addMode) {
              if (controllerBar.text != '') {
                final list = listaFiltrada
                    .where(
                      (element) =>
                          element.label.toLowerCase().latinize().contains(
                                controllerBar.text.toLowerCase().latinize(),
                              ),
                    )
                    .toList();
                if (list.isEmpty) {
                  return DefaultAddListItem(
                    itemAdded: itemAdded,
                    overlayListSettings: overlayListSettings,
                    text: controllerBar.text,
                  );
                }
              }
              return const SizedBox.shrink();
            } else {
              return DefaultListTile<T>(
                deleteMode: deleteMode,
                item: listaFiltrada[index],
                onDelete: onDelete,
                onPressed: onPressed,
                overlayListSettings: overlayListSettings,
                selected: controllerBar.text == listaFiltrada[index].label,
                key: index == 0 ? _itemKey : null,
              );
            }
          },
        ),
      ),
    );
  }
}
