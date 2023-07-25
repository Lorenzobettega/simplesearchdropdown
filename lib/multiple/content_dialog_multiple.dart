import 'package:flutter/material.dart';
import 'package:stringr/stringr.dart';

class ContentMultiple extends StatefulWidget {
  const ContentMultiple({super.key,
    required this.animationDuration,
    required this.backgroundColor,
    required this.border,
    required this.dialogBackgroundColor,
    required this.dialogHeight,
    required this.dialogListviewWidgetBuilder,
    required this.dialogSearchBarBorder,
    required this.dialogSearchBarColor,
    required this.dialogSearchBarElevation,
    required this.elevation,
    required this.hoverColor,
    required this.hintSearchBar,
    required this.hintStyle,
    required this.listItens,
    required this.onItemSelected,
    required this.selectedDialogBoxColor,
    required this.selectedDialogColor,
    required this.selectedInsideBoxTextStyle,
    required this.selectedItens,
    required this.unselectedInsideBoxTextStyle,
    required this.width,
  });

  final Duration? animationDuration;
  final Color? backgroundColor;
  final OutlinedBorder? border;
  final Color? dialogBackgroundColor;
  final double dialogHeight;
  final OutlinedBorder? dialogSearchBarBorder;
  final Color? dialogSearchBarColor;
  final double dialogSearchBarElevation;
  final double elevation;
  final Color? hoverColor;
  final Function(String value) onItemSelected;
  final Widget? dialogListviewWidgetBuilder;
  final TextStyle? hintStyle;
  final String? hintSearchBar;
  final List<String> listItens;
  final List<String> selectedItens;
  final Color? selectedDialogBoxColor;
  final Color? selectedDialogColor;
  final TextStyle? selectedInsideBoxTextStyle;
  final TextStyle? unselectedInsideBoxTextStyle;
  final double width;
  
  @override
  State<ContentMultiple> createState() => _ContentMultipleState();
}

class _ContentMultipleState extends State<ContentMultiple> {

  List<String> listafiltrada = [];
  final TextEditingController controllerBar = TextEditingController();

  @override
  void initState() {
    super.initState();
    filtrarLista(null);
  }

 void filtrarLista(String? text,) {
    if(text != null && text != ''){
      setState(() {
        listafiltrada = widget.listItens.where((element) => element.toLowerCase().latinize().contains(text.toLowerCase())).toList();
      });
    } else {
      setState(() {
        listafiltrada = widget.listItens;
      });
    }
    
  }

  void addItem(String value){
    widget.onItemSelected.call(value);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          surfaceTintColor: widget.dialogBackgroundColor ?? widget.backgroundColor ?? Colors.white,
          color: widget.dialogBackgroundColor ?? widget.backgroundColor ?? Colors.white,
          elevation: widget.elevation,
          child: AnimatedContainer(
            duration: widget.animationDuration ?? const Duration(milliseconds: 100), 
            height: widget.dialogHeight,
            width: widget.width,
            child: Column(
              children: [
                SearchBar(
                  controller: controllerBar,
                  backgroundColor: MaterialStatePropertyAll(widget.dialogSearchBarColor ?? Colors.white),
                  overlayColor: MaterialStatePropertyAll(widget.hoverColor ?? Colors.grey.shade100),
                  constraints: BoxConstraints(maxHeight: 50,maxWidth: widget.width),
                  surfaceTintColor: MaterialStatePropertyAll(widget.dialogSearchBarColor ?? Colors.white),
                  shape: MaterialStateProperty.all<OutlinedBorder>(widget.dialogSearchBarBorder ?? const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0)))),
                  hintText: widget.hintSearchBar ?? 'Pesquisar',
                  hintStyle: MaterialStateProperty.all<TextStyle>(widget.hintStyle ?? const TextStyle(fontSize: 14)),
                  side: MaterialStateProperty.all<BorderSide>(const BorderSide(style: BorderStyle.none,),),
                  onChanged: (a){
                    filtrarLista(a);
                  },
                  elevation: MaterialStateProperty.all<double>(widget.dialogSearchBarElevation),
                ),
                const SizedBox(height: 5,),
                Expanded( 
                  child: ListView.builder( 
                    scrollDirection: Axis.vertical,
                    itemCount: listafiltrada.length,
                    itemBuilder: (context, index) {
                      return Row(
                        children: [
                          Expanded(
                            child: TextButton(
                                style: ButtonStyle(
                                  backgroundColor: MaterialStateProperty.resolveWith<Color>(
                                    (Set<MaterialState> states) {
                                      if (widget.selectedItens.contains(listafiltrada[index])) {
                                        return widget.selectedDialogBoxColor ?? Colors.black38;
                                      }
                                      return Colors.transparent;
                                    },
                                  ),
                                  shape: MaterialStateProperty.all<OutlinedBorder>(
                                      const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.zero)),
                                  overlayColor:
                                      MaterialStatePropertyAll(widget.hoverColor ?? Colors.black45),
                                ),
                                onPressed: () => addItem(listafiltrada[index]),
                                child: widget.dialogListviewWidgetBuilder ??
                                    Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          listafiltrada[index],
                                          style: (controllerBar.text == listafiltrada[index]
                                              ? widget.selectedInsideBoxTextStyle ??
                                                  const TextStyle(color: Colors.black)
                                              : widget.unselectedInsideBoxTextStyle ??
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
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}