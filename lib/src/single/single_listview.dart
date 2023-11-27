import 'package:flutter/material.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';
import 'package:stringr/stringr.dart';

///This creates the list that contains the items to be selected.
class SingleListView<T> extends StatelessWidget {
  const SingleListView({
    required this.addMode,
    required this.onAddItem,
    required this.newValueItem,
    required this.animationDuration,
    required this.backgroundColor,
    required this.controllerBar,
    required this.addItemHint,
    required this.addItemHintStyle,
    required this.deleteMode,
    required this.dialogActionIcon,
    required this.dialogActionWidget,
    required this.dialogBackgroundColor,
    required this.dialogHeight,
    required this.elevation,
    required this.hoverColor,
    required this.listaFiltrada,
    required this.onClear,
    required this.onPressed,
    required this.itemsPadding,
    required this.selectedDialogColor,
    required this.selectedInsideBoxTextStyle,
    required this.selectedItemHoverColor,
    required this.separatorHeight,
    required this.sortType,
    required this.unselectedItemHoverColor,
    required this.unselectedInsideBoxTextStyle,
    required this.widgetBuilder,
    required this.width,
    required this.selectedItem,
    super.key,
  });
  ///Allow the user to add items to the list.
  final bool addMode;
  ///Function to be executed after the item was added.
  final Function(ValueItem<T> value) onAddItem;
  ///Function that defines how the user input transforms into a new ValueItem on the list.
  final ValueItem<T> Function(String input)? newValueItem;
  final Duration? animationDuration;
  final Color? backgroundColor;
  final TextEditingController controllerBar;
  final String? addItemHint;
  final TextStyle? addItemHintStyle;
  final bool deleteMode;
  final Icon? dialogActionIcon;
  final Widget? dialogActionWidget;
  final Color? dialogBackgroundColor;
  final double dialogHeight;
  final double elevation;
  final Color? hoverColor;
  final List<ValueItem<T>> listaFiltrada;
  final Function(ValueItem<T> value) onClear;
  final Function(ValueItem<T> value) onPressed;
  final EdgeInsets? itemsPadding;
  final Color? selectedDialogColor;
  final TextStyle? selectedInsideBoxTextStyle;
  final Color? selectedItemHoverColor;
  final double? separatorHeight;
  final int sortType;
  final Color? unselectedItemHoverColor;
  final TextStyle? unselectedInsideBoxTextStyle;
  final Widget? widgetBuilder;
  final double width;
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

  void goToSelectedItem(ScrollController controller, ValueItem<T> item) {
    final index = listaFiltrada.indexOf(item);
    if (index > 0) {
      final contentSize = controller.position.viewportDimension +
          controller.position.maxScrollExtent;

      final target = contentSize * index / listaFiltrada.length;
      controller.position.animateTo(
        target,
        duration: const Duration(milliseconds: 200),
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
          dialogBackgroundColor ?? backgroundColor ?? Colors.white,
      color: dialogBackgroundColor ?? backgroundColor ?? Colors.white,
      elevation: elevation,
      child: AnimatedContainer(
        duration: animationDuration ?? const Duration(milliseconds: 100),
        height: dialogHeight,
        width: width,
        child: ListView.separated(
          controller: controller,
          padding: EdgeInsets.zero,
          itemCount: listaFiltrada.length + (addMode ? 1 : 0),
          separatorBuilder: (context, index) => SizedBox(
            height: separatorHeight ?? 1,
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
                            addItemHint ?? 'Criar',
                            style: addItemHintStyle,
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
                padding: itemsPadding ?? const EdgeInsets.symmetric(horizontal: 4),
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
                                return selectedDialogColor ?? Colors.black38;
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
                                return selectedItemHoverColor ??
                                    Colors.grey.shade300;
                              }
                              return unselectedItemHoverColor ??
                                  Colors.grey.shade100;
                            },
                          ),
                        ),
                        onPressed: () => onPressed(listaFiltrada[index]),
                        child: widgetBuilder ??
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                listaFiltrada[index].label,
                                style: (controllerBar.text ==
                                        listaFiltrada[index].label
                                    ? selectedInsideBoxTextStyle ??
                                        const TextStyle(color: Colors.black)
                                    : unselectedInsideBoxTextStyle ??
                                        const TextStyle(color: Colors.black45)),
                              ),
                            ),
                      ),
                    ),
                    deleteMode
                        ? dialogActionWidget ??
                            IconButton(
                              onPressed: () {
                                onClear(listaFiltrada[index]);
                              },
                              icon: dialogActionIcon ??
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
