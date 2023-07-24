import 'package:flutter/material.dart';

class NovoListView extends StatelessWidget {
  final List<String> listaFiltrada;
  final TextEditingController controllerBar;
  final Function(String) onPressed;
  final Widget? widgetBuilder;
  final TextStyle? unselectedInsideBoxTextStyle;
  final TextStyle? selectedInsideBoxTextStyle;
  final Color? selectedDialogColor;
  final Color? hoverColor;

  const NovoListView(
      {required this.listaFiltrada,
      required this.controllerBar,
      required this.onPressed,
      this.widgetBuilder,
      this.unselectedInsideBoxTextStyle,
      this.selectedInsideBoxTextStyle,
      this.selectedDialogColor,
      this.hoverColor,
      Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: listaFiltrada.length,
      itemBuilder: (context, index) {
        return TextButton(
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
                    )));
      },
    );
  }
}
