import 'package:flutter/material.dart';

class NovoListView extends StatelessWidget {
  final Duration? animationDuration;
  final Color? backgroundColor;
  final TextEditingController controllerBar;
  final Color? dialogBackgroundColor;
  final double dialogHeight;
  final double elevation;
  final Color? hoverColor;
  final List<String> listaFiltrada;
  final Function(String) onClear;
  final Function(String) onPressed;
  final Color? selectedDialogColor;
  final TextStyle? selectedInsideBoxTextStyle;
  final TextStyle? unselectedInsideBoxTextStyle;
  final Widget? widgetBuilder;
  final double width;

  const NovoListView({
      required this.animationDuration,
      required this.backgroundColor,
      required this.controllerBar,
      required this.dialogBackgroundColor,
      required this.dialogHeight,
      required this.elevation,
      required this.hoverColor,
      required this.listaFiltrada,
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
          itemCount: listaFiltrada.length,
          itemBuilder: (context, index) {
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
                IconButton(
                  onPressed: (){
                    onClear(listaFiltrada[index]);
                  }, 
                  icon: Icon(Icons.delete,color: Colors.red.shade900,)
                )
              ],
            );
          },
        ),
      ),
    );
  }
}
