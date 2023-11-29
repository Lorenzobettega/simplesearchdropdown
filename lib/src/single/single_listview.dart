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
    required this.onClear,
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
  final SimpleOverlaySettings? overlayListSettings;
  final Color? backgroundColor;
  final TextEditingController controllerBar;
  final bool deleteMode;
  final double elevation;
  final List<ValueItem<T>> listaFiltrada;
  final Function(ValueItem<T> value) onClear;
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
  void goToSelectedItem(ScrollController controller, ValueItem<T> item) {
    final index = listaFiltrada.indexOf(item);
    if (index > 1) {
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
    final controller = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (selectedItem != null) {
        goToSelectedItem(controller, selectedItem!);
      }
    });
    return Card(
      surfaceTintColor:
          overlayListSettings?.dialogBackgroundColor ?? backgroundColor,
      color: overlayListSettings?.dialogBackgroundColor ?? backgroundColor,
      elevation: elevation,
      child: AnimatedContainer(
        duration: overlayListSettings?.animationDuration ??
            const Duration(milliseconds: 100),
        height: overlayListSettings?.dialogHeight ?? 200,
        width: dropdownwidth,
        child: ListView.separated(
          controller: controller,
          padding: EdgeInsets.zero,
          itemCount: listaFiltrada.length + (addMode ? 1 : 0),
          separatorBuilder: (context, index) => SizedBox(
            height: overlayListSettings?.separatorHeight ?? 1,
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
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(controllerBar.text),
                        TextButton(
                          onPressed: () {
                            final item = newValueItem!(controllerBar.text);
                            onAddItem(item);
                            listaFiltrada.add(item);
                          },
                          child: Text(
                            overlayListSettings?.addItemHint ?? 'Criar',
                            style: overlayListSettings?.addItemHintStyle,
                          ),
                        ),
                      ],
                    ),
                  );
                }
              }
              return const SizedBox.shrink();
            } else {
              return Padding(
                padding: overlayListSettings?.itemsPadding ??
                    const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.resolveWith<Color>(
                            (Set<MaterialState> states) {
                              if (controllerBar.text ==
                                  listaFiltrada[index].label) {
                                return overlayListSettings
                                        ?.selectedItemBackgroundColor ??
                                    Colors.black38;
                              }
                              return Colors.transparent;
                            },
                          ),
                          shape: MaterialStateProperty.all<OutlinedBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          overlayColor:
                              MaterialStateProperty.resolveWith<Color>(
                            (Set<MaterialState> states) {
                              if (controllerBar.text ==
                                  listaFiltrada[index].label) {
                                return overlayListSettings
                                        ?.selectedItemHoverColor ??
                                    Colors.grey.shade300;
                              }
                              return overlayListSettings
                                      ?.unselectedItemHoverColor ??
                                  Colors.grey.shade100;
                            },
                          ),
                        ),
                        onPressed: () => onPressed(listaFiltrada[index]),
                        child: overlayListSettings?.itemWidgetBuilder != null
                            ? overlayListSettings!
                                .itemWidgetBuilder!(listaFiltrada[index])
                            : Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  listaFiltrada[index].label,
                                  style: (controllerBar.text ==
                                          listaFiltrada[index].label
                                      ? overlayListSettings
                                              ?.selectedItemTextStyle ??
                                          const TextStyle(color: Colors.black)
                                      : overlayListSettings
                                              ?.unselectedItemTextStyle ??
                                          const TextStyle(
                                              color: Colors.black45)),
                                ),
                              ),
                      ),
                    ),
                    deleteMode
                        ? overlayListSettings?.dialogActionWidget ??
                            IconButton(
                              onPressed: () {
                                onClear(listaFiltrada[index]);
                              },
                              icon: overlayListSettings?.dialogActionIcon ??
                                  Icon(
                                    Icons.delete,
                                    color: Colors.red.shade900,
                                    size: 20,
                                  ),
                            )
                        : const SizedBox.shrink()
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
