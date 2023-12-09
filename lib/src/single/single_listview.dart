import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';
import 'package:stringr/stringr.dart';

///This creates the list that contains the items to be selected.
class SingleListView<T> extends StatelessWidget {
  SingleListView({
    required this.addMode,
    required this.onAddItem,
    required this.newValueItem,
    required this.backgroundColor,
    required this.searchbarText,
    required this.deleteMode,
    required this.elevation,
    required this.listaFiltrada,
    required this.onDelete,
    required this.onPressed,
    required this.overlayListSettings,
    required this.dropdownwidth,
    required this.selectedItem,
    required this.shouldScroll,
    required this.updateShouldScroll,
    super.key,
  });

  ///Allow the user to add items to the list.
  final bool addMode;

  ///Function to be executed after the item was added.
  final Function(ValueItem<T> value) onAddItem;

  ///Function that defines how the user input transforms into a new ValueItem on the list.
  final ValueItem<T> Function(String input)? newValueItem;

  ///The settings for the overlay list of items.
  final SimpleOverlaySettings overlayListSettings;
  final Color? backgroundColor;
  final String searchbarText;
  final bool deleteMode;
  final double elevation;
  final List<ValueItem<T>> listaFiltrada;
  final Function(ValueItem<T> value) onDelete;
  final Function(ValueItem<T> value) onPressed;
  final double dropdownwidth;
  final ValueItem<T>? selectedItem;
  final bool shouldScroll;
  final VoidCallback updateShouldScroll;
  final ItemScrollController scrollController = ItemScrollController();

  ///Function to scroll the list to the selected item
  ///only works if the size of all tiles is equal.
  ///
  void goToSelectedItem(ValueItem<T> item) {
    final index = listaFiltrada.indexOf(item);
    if (index > 1) {
      scrollController.scrollTo(
        index: index,
        duration: overlayListSettings.reOpenedScrollDuration,
        curve: Curves.ease,
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
    final PageStorageBucket pageStorageBucket = PageStorageBucket();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (selectedItem != null && shouldScroll) {
        goToSelectedItem(selectedItem!);
        updateShouldScroll();
      }
    });
    return PageStorage(
      bucket: pageStorageBucket,
      child: Card(
        surfaceTintColor:
            overlayListSettings.dialogBackgroundColor ?? backgroundColor,
        color: overlayListSettings.dialogBackgroundColor ?? backgroundColor,
        elevation: elevation,
        child: AnimatedContainer(
          duration: overlayListSettings.animationDuration,
          height: overlayListSettings.dialogHeight,
          width: dropdownwidth,
          child: ScrollablePositionedList.separated(
            itemScrollController: scrollController,
            padding: EdgeInsets.zero,
            itemCount: listaFiltrada.length + (addMode ? 1 : 0),
            separatorBuilder: (context, index) => SizedBox(
              height: overlayListSettings.separatorHeight,
            ),
            itemBuilder: (context, index) {
              if (index == listaFiltrada.length && addMode) {
                if (searchbarText != '') {
                  final list = listaFiltrada
                      .where(
                        (element) =>
                            element.label.toLowerCase().latinize().contains(
                                  searchbarText.toLowerCase().latinize(),
                                ),
                      )
                      .toList();
                  if (list.isEmpty) {
                    return DefaultAddListItem(
                      itemAdded: itemAdded,
                      overlayListSettings: overlayListSettings,
                      text: searchbarText,
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
                  selected: searchbarText == listaFiltrada[index].label,
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
