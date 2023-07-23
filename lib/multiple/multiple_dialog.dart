import 'package:flutter/material.dart';
import 'package:searchdialog/multiple/content_dialog_multiple.dart';

class MultipleDialog extends StatefulWidget {
  const MultipleDialog({super.key});

  @override
  State<MultipleDialog> createState() => _MultipleDialogState();
}

class _MultipleDialogState extends State<MultipleDialog> {

  double altura = 0;
  bool aberto = false;
  final List<String> selectedItems = [];

  void definir(){
    setState(() {
      if(aberto){
        altura = 0;
      }else{
        altura = 300;
      }
    });
    aberto = !aberto;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 360,
      width: 300,
      child: Stack(
        children: [
          InkWell(
            onTap: () => definir(),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 50,maxWidth: 300,minHeight: 50,minWidth: 300),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                color: Colors.red
              ),
            ),
          ),
          ContentMultiple(
            onItemSelected: (value) {
              setState(() {
                if (selectedItems.contains(value)) {
                  selectedItems.remove(value);
                } else {
                  selectedItems.add(value);
                }
              });
            },
            listItens: const ['A','B','C','D',],
            altura: altura,
            selectedItens: selectedItems,
          )
        ],
      ),
    );
  }
}