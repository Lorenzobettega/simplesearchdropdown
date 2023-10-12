import 'package:flutter/material.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';
import 'package:stringr/stringr.dart';

class NovoListView<T> extends StatelessWidget {
  final bool addMode;
  final Duration? animationDuration;
  final Color? backgroundColor;
  final TextEditingController controllerBar;
  final String? createHint;
  final TextStyle? createHintStyle;
  final bool deleteMode;
  final Icon? dialogActionIcon;
  final Widget? dialogActionWidget;
  final Color? dialogBackgroundColor;
  final double dialogHeight;
  final double elevation;
  final Color? hoverColor;
  final List<ValueItem<T>> listaFiltrada;
  final Function(ValueItem<T> value) onAddItem;
  final Function(ValueItem<T> value) onClear;
  final Function(ValueItem<T> value) onPressed;
  final EdgeInsets? padding;
  final Color? selectedDialogColor;
  final TextStyle? selectedInsideBoxTextStyle;
  final Color? selectedItemHoverColor;
  final double? separatorHeight;
  final bool sortSelecteds;
  final Color? unselectedItemHoverColor;
  final TextStyle? unselectedInsideBoxTextStyle;
  final Widget? widgetBuilder;
  final double width;
  final ValueItem<T> Function(String input)? newValueItem;

  const NovoListView({
    required this.addMode,
    required this.animationDuration,
    required this.backgroundColor,
    required this.controllerBar,
    required this.createHint,
    required this.createHintStyle,
    required this.deleteMode,
    required this.dialogActionIcon,
    required this.dialogActionWidget,
    required this.dialogBackgroundColor,
    required this.dialogHeight,
    required this.elevation,
    required this.hoverColor,
    required this.listaFiltrada,
    required this.onAddItem,
    required this.onClear,
    required this.onPressed,
    required this.padding,
    required this.selectedDialogColor,
    required this.selectedInsideBoxTextStyle,
    required this.selectedItemHoverColor,
    required this.separatorHeight,
    required this.sortSelecteds,
    required this.unselectedItemHoverColor,
    required this.unselectedInsideBoxTextStyle,
    required this.widgetBuilder,
    required this.width,
    required this.newValueItem,
    Key? key,
  }) : super(key: key);

  void organizarLista() {
    List<ValueItem<T>> selecionado = listaFiltrada
        .where((item) => item.label == controllerBar.text)
        .toList();
    if (selecionado.isNotEmpty) {
      listaFiltrada.removeWhere((item) => item.label == controllerBar.text);
      listaFiltrada.insert(0, selecionado[0]);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          padding: EdgeInsets.zero,
          itemCount: listaFiltrada.length + (addMode ? 1 : 0),
          separatorBuilder: (context, index) => SizedBox(
            height: separatorHeight ?? 1,
          ),
          itemBuilder: (context, index) {
            sortSelecteds ? organizarLista() : null;
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
                            createHint ?? 'Criar',
                            style: createHintStyle,
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
                padding: padding ?? const EdgeInsets.symmetric(horizontal: 4),
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
