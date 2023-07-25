import 'package:flutter/material.dart';

class NovoListView extends StatelessWidget {
  final TextEditingController controllerBar;
  final Color? hoverColor;
  final List<String> listaFiltrada;
  final Function(String) onPressed;
  final Color? selectedDialogColor;
  final TextStyle? selectedInsideBoxTextStyle;
  final TextStyle? unselectedInsideBoxTextStyle;
  final Widget? widgetBuilder;

  const NovoListView({
      required this.controllerBar,
      required this.hoverColor,
      required this.listaFiltrada,
      required this.onPressed,
      this.selectedDialogColor,
      this.selectedInsideBoxTextStyle,
      this.unselectedInsideBoxTextStyle,
      this.widgetBuilder,
      Key? key,
    })
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
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
              onPressed: (){}, 
              icon: Icon(Icons.delete,color: Colors.red.shade900,)
            )
          ],
        );
      },
    );
  }
}
