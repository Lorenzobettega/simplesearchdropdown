import 'package:flutter/material.dart';
import 'package:searchdialog/multiple/content_dialog_multiple.dart';

class MultipleDialog extends StatefulWidget {
  const MultipleDialog({super.key});

  @override
  State<MultipleDialog> createState() => _MultipleDialogState();
}

class _MultipleDialogState extends State<MultipleDialog> {

  late double altura = 0;
  late bool aberto = false;
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

  void onItemSelected(String val){
    setState(() {
      if (selectedItems.contains(val)) {
        selectedItems.remove(val);
      } else {
        selectedItems.add(val);
      }
    });
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
                color: Colors.grey
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        separatorBuilder: (context, index) => const SizedBox(width: 5),
                        itemCount: selectedItems.length,
                        itemBuilder: (context, index) {
                          return Card(
                            elevation: 10,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20,vertical: 5),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(selectedItems[index]),
                                  InkWell(onTap: () => onItemSelected(selectedItems[index]),child: const Icon(Icons.close),)
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Icon(aberto ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down)
                  ],
                ),
              ),
            ),
          ),
          ContentMultiple(
            onItemSelected: (value) => onItemSelected(value),
            listItens: const ['A','B','C','D',],
            altura: altura,
            selectedItens: selectedItems,
          )
        ],
      ),
    );
  }
}