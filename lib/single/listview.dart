import 'package:flutter/material.dart';
import 'package:stringr/stringr.dart';

class NovoListView extends StatelessWidget {
  final bool addMode;
  final Duration? animationDuration;
  final Color? backgroundColor;
  final TextEditingController controllerBar;
  final bool deleteMode;
  final Icon? dialogActionIcon;
  final Widget? dialogActionWidget;
  final Color? dialogBackgroundColor;
  final double dialogHeight;
  final double elevation;
  final Color? hoverColor;
  final List<String> listaFiltrada;
  final Function(String) onAddItem;
  final Function(String) onClear;
  final Function(String) onPressed;
  final Color? selectedDialogColor;
  final TextStyle? selectedInsideBoxTextStyle;
  final TextStyle? unselectedInsideBoxTextStyle;
  final Widget? widgetBuilder;
  final double width;

  const NovoListView({
      required this.addMode,
      required this.animationDuration,
      required this.backgroundColor,
      required this.controllerBar,
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
      required this.selectedDialogColor,
      required this.selectedInsideBoxTextStyle,
      required this.unselectedInsideBoxTextStyle,
      required this.widgetBuilder,
      required this.width,
      Key? key,
    })
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      surfaceTintColor: dialogBackgroundColor ?? backgroundColor ?? Colors.white,
      color: dialogBackgroundColor ?? backgroundColor ??Colors.white,
      elevation: elevation,
      child: AnimatedContainer(
        duration: animationDuration ?? const Duration(milliseconds: 100),
        height: dialogHeight,
        width: width,
        child: ListView.builder(
          itemCount: listaFiltrada.length + (addMode ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == listaFiltrada.length && addMode) {
              if(controllerBar.text != ''){
                final list = listaFiltrada.where((element) =>
                  element.toLowerCase().latinize().contains(controllerBar.text.toLowerCase().latinize())).toList();
                if (list.isEmpty) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(controllerBar.text),
                      ),
                      TextButton(
                        onPressed: (){
                          onAddItem(controllerBar.text); 
                          listaFiltrada.add(controllerBar.text);
                        }, 
                        child: const Text('Criar'),
                      ),
                    ],
                  );
                }
              } 
              return const SizedBox.shrink();
            }else{
              return Row(
                children: [
                  Expanded(
                    child: TextButton(
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.resolveWith<Color>(
                            (Set<MaterialState> states) {
                              if (controllerBar.text == listaFiltrada[index]) {
                                return selectedDialogColor ?? Colors.black38;
                              }
                              return Colors.transparent;
                            },
                          ),
                          shape: MaterialStateProperty.all<OutlinedBorder>(
                              const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero)),
                          overlayColor:
                              MaterialStatePropertyAll(hoverColor ?? Colors.grey.shade100),
                        ),
                        onPressed: () => onPressed(listaFiltrada[index]),
                        child: widgetBuilder ??
                            Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  listaFiltrada[index],
                                  style: (controllerBar.text == listaFiltrada[index]
                                      ? selectedInsideBoxTextStyle ??
                                          const TextStyle(color: Colors.black)
                                      : unselectedInsideBoxTextStyle ??
                                          const TextStyle(color: Colors.black45)),
                                ))),
                  ),
                  deleteMode ? dialogActionWidget ?? IconButton(
                    onPressed: (){
                      onClear(listaFiltrada[index]);
                    }, 
                    icon: dialogActionIcon ?? Icon(Icons.delete,color: Colors.red.shade900,size: 20,)
                  ) : const SizedBox.shrink()
                ],
              );
            }
          },
        ),
      ),
    );
  }
}
