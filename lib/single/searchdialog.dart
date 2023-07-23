import 'package:flutter/material.dart';
import 'package:searchdialog/single/listview.dart';

class SearchDialog extends StatefulWidget {
  const SearchDialog({super.key,
    required this.controllerBar,
    required this.listItens,
    this.dialogHeight = 300,
    this.animationDuration,
    this.hint,
    this.border,
    this.width = 300,
    this.widgetBuilder,
    this.elevation = 10,
    this.backgroundColor,
    this.dialogBackgroundColor,
    this.hintStyle,
    this.hoverColor,
    this.selectedDialogColor,
    this.selectedInsideBoxTextStyle,
    this.unselectedInsideBoxTextStyle,
    this.actions,
  });

  final TextEditingController controllerBar;
  final List<String> listItens;
  final double dialogHeight;
  final Duration? animationDuration;
  final String? hint;
  final OutlinedBorder? border;
  final double width;
  final Widget? widgetBuilder;
  final double elevation;
  final Color? backgroundColor;
  final Color? dialogBackgroundColor;
  final Color? hoverColor;
  final TextStyle? hintStyle;
  final Color? selectedDialogColor;
  final TextStyle? selectedInsideBoxTextStyle;
  final TextStyle? unselectedInsideBoxTextStyle;
  final List<Widget>? actions;

  @override
  State<SearchDialog> createState() => SearchDialogState();
}

class SearchDialogState extends State<SearchDialog> {

  @override
  void initState() {
    super.initState();
    _filtrarLista('',start: true);
  }

  double altura = 0;
  bool aberto = false;
  List<String> listafiltrada = [];

  void _filtrarLista(String? text,{bool start = false}) {
    if (start) {
      listafiltrada = widget.listItens;
      setState(() {
        altura = 0;
      });
    }else{
      if(text != null && text != ''){
        listafiltrada = widget.listItens.where((element) => element.toLowerCase().contains(text.toLowerCase())).toList();
        setState(() {
          altura = widget.dialogHeight;
        });
      } else {
        listafiltrada = widget.listItens;
        setState(() {
          altura = widget.dialogHeight;
        });
      }
    }
  }

  void definir(String val){
    aberto = !aberto;
    widget.controllerBar.text = val;
    setState(() {
      altura = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.dialogHeight + 63,
      child: Stack(
        children: [
          SearchBar(
            trailing: widget.actions ?? [
              aberto ? const Icon(Icons.keyboard_arrow_up) : const Icon(Icons.keyboard_arrow_down)
            ],
            controller: widget.controllerBar,
            backgroundColor: MaterialStatePropertyAll(widget.backgroundColor ?? Colors.white),
            hintStyle: MaterialStatePropertyAll(widget.hintStyle),
            overlayColor: MaterialStatePropertyAll(widget.hoverColor ?? Colors.grey.shade100),
            constraints: BoxConstraints(maxHeight: 50,maxWidth: widget.width),
            surfaceTintColor: MaterialStatePropertyAll(widget.backgroundColor ?? Colors.white),
            shape: MaterialStateProperty.all<OutlinedBorder>(widget.border ?? const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0)))),
            hintText: widget.hint ?? 'Selecione',
            side: MaterialStateProperty.all<BorderSide>(
              const BorderSide(style: BorderStyle.none,),
            ),
            onTap: (){
              setState(() {
                if(aberto){
                  altura = 0;
                }else{
                  altura = widget.dialogHeight;
                }
                aberto = !aberto;
              });
            },
            onChanged: (a){
              _filtrarLista(a);
            },
            elevation: MaterialStateProperty.all<double>(
              widget.elevation,
            ),
          ),
          Column(
            children: [
            const SizedBox(height: 55,),
            Card(
              surfaceTintColor: widget.dialogBackgroundColor ?? widget.backgroundColor ?? Colors.white,
              color: widget.dialogBackgroundColor ?? widget.backgroundColor ?? Colors.white,
              elevation: widget.elevation,
              child: AnimatedContainer(
                duration: widget.animationDuration ?? const Duration(milliseconds: 100), 
                height: altura,
                width: widget.width,
                child: NovoListView(
                  listaFiltrada: listafiltrada,
                  controllerBar: widget.controllerBar,
                  widgetBuilder: widget.widgetBuilder,
                  hoverColor: widget.hoverColor,
                  selectedDialogColor: widget.selectedDialogColor,
                  selectedInsideBoxTextStyle: widget.selectedInsideBoxTextStyle,
                  unselectedInsideBoxTextStyle: widget.unselectedInsideBoxTextStyle,
                ),
              ),
            ),
            ],
          ),
        ],
      ),
    );
  }
}