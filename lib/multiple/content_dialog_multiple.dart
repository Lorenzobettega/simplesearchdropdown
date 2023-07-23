import 'package:flutter/material.dart';

class ContentMultiple extends StatefulWidget {
  const ContentMultiple({super.key,
    required this.listItens,
  });

  final List<String> listItens;

  @override
  State<ContentMultiple> createState() => _ContentMultipleState();
}

class _ContentMultipleState extends State<ContentMultiple> {

  List<String> listafiltrada = [];
  TextEditingController controllerBar = TextEditingController();

  void _filtrarLista(String? text,) {
    if(text != null && text != ''){
      listafiltrada = widget.listItens.where((element) => element.toLowerCase().contains(text.toLowerCase())).toList();
    } else {
      listafiltrada = widget.listItens;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
      const SizedBox(height: 55,),
      Card(
        surfaceTintColor:  Colors.white,
        color: Colors.white,
        elevation: 10,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100), 
          height: 300,
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
                hintText: 'Selecione',
                side: MaterialStateProperty.all<BorderSide>(const BorderSide(style: BorderStyle.none,),),
                onChanged: (a){
                  _filtrarLista(a);
                },
                elevation: MaterialStateProperty.all<double>(10),
              ),
              const SizedBox(height: 10,),
              ListView.builder(
                itemCount: listafiltrada.length,
                itemBuilder: (context, index) {
                  return TextButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.resolveWith<Color>(
                        (Set<MaterialState> states) {
                          if (controllerBar.text == listafiltrada[index]) {
                            return Colors.black38;
                          }
                          return Colors.transparent;
                        },
                      ),
                      shape: MaterialStateProperty.all<OutlinedBorder>(const RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
                      overlayColor: MaterialStatePropertyAll( Colors.grey.shade100),
                    ),
                    onPressed: (){
                      // SearchDialogState searchDialogState = context.findAncestorStateOfType<SearchDialogState>()!;
                      // searchDialogState.definir(listaFiltrada[index]);
                    }, 
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        listafiltrada[index],
                        style: (controllerBar.text == listafiltrada[index] 
                          ? const TextStyle(color: Colors.black)
                          : const TextStyle(color: Colors.black45)),
                      )
                    )
                  );
                },
              ),
            ],
          )
        ),
      ),
      ],
    );
  }
}