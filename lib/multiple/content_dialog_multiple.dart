import 'package:flutter/material.dart';

class ContentMultiple extends StatefulWidget {
  const ContentMultiple({super.key,
    required this.altura, 
    required this.selectedItens,
    required this.listItens,
    required this.onItemSelected,
  });

  final List<String> selectedItens;
  final List<String> listItens;
  final double altura;
   final Function(String value) onItemSelected;

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
        listafiltrada = widget.listItens.where((element) => element.toLowerCase().contains(text.toLowerCase())).toList();
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
        const SizedBox(height: 48,),
        Card(
          surfaceTintColor: Colors.white,
          color: Colors.white,
          elevation: 10,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100), 
            height: widget.altura,
            width: 300,
            child: Column(
              children: [
                SearchBar(
                  controller: controllerBar,
                  backgroundColor: const MaterialStatePropertyAll(Colors.white),
                  overlayColor: MaterialStatePropertyAll(Colors.grey.shade100),
                  constraints: const BoxConstraints(maxHeight: 50,maxWidth: 300),
                  surfaceTintColor: const MaterialStatePropertyAll(Colors.white),
                  shape: MaterialStateProperty.all<OutlinedBorder>(const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0)))),
                  hintText: 'Search',
                  side: MaterialStateProperty.all<BorderSide>(const BorderSide(style: BorderStyle.none,),),
                  onChanged: (a){
                    filtrarLista(a);
                  },
                ),
                const SizedBox(height: 5,),
                Expanded( 
                  child: ListView.builder( 
                    scrollDirection: Axis.vertical,
                    itemCount: listafiltrada.length,
                    itemBuilder: (context, index) {
                      return TextButton(
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.resolveWith<Color>(
                            (Set<MaterialState> states) {
                              if (widget.selectedItens.contains(listafiltrada[index])) {
                                return Colors.black38;
                              }
                              return Colors.transparent;
                            },
                          ),
                          shape: MaterialStateProperty.all<OutlinedBorder>(const RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
                          overlayColor: const MaterialStatePropertyAll(Colors.black45),
                        ),
                        onPressed: () => addItem(listafiltrada[index]),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            listafiltrada[index],
                            style: (widget.selectedItens.contains(listafiltrada[index])
                              ? TextStyle(color: Colors.grey.shade100)
                              : const TextStyle(color: Colors.black45)),
                          ),
                        ),
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