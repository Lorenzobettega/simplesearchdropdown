import 'package:flutter/material.dart';

class MultipleSearchDialog extends StatefulWidget {
  const MultipleSearchDialog({super.key,});


  @override
  State<MultipleSearchDialog> createState() => _MultipleSearchDialogState();
}

class _MultipleSearchDialogState extends State<MultipleSearchDialog> {

  final List<String> selectedsItens = [
    'Abelha','Leão','Abelha','Leão','Abelha','Leão','Abelha','Leão','Abelha','Leão',
  ];
  double altura = 0;
  bool aberto = false;

  Widget buildItem(String value) {
    return Card(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(value),
            const SizedBox(width: 5,),
            InkWell(
              onTap: (){},
              child: const Icon(
                Icons.close_outlined,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final LayerLink layerLink = LayerLink();
    return CompositedTransformTarget(
      link: layerLink,
      child: SizedBox(
        height: 60,
        width: 400,
        child: InkWell(
          splashColor: null,
          splashFactory: null,
          onTap: () {
          },
          child: Card(
            elevation: 10,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
            child: Row(
              children: [
                Expanded(
                  child: selectedsItens.isEmpty 
                    ? const Text('Selecione')
                    : ListView.separated(
                      separatorBuilder: (context, index) => const Spacer(),
                      scrollDirection: Axis.horizontal,
                      itemCount: selectedsItens.length,
                      itemBuilder: (context, index) {
                        return buildItem(selectedsItens[index]);
                      },
                    )
                ),
                selectedsItens.isNotEmpty
                  ? InkWell(
                    onTap: (){},
                    child: const Icon(
                      Icons.close_outlined,
                      size: 18,
                    ),
                  )
                  : aberto ? const Icon(Icons.keyboard_arrow_up) : const Icon(Icons.keyboard_arrow_down),
              ],
            ),
          ),
        ),
      ),
    );
  }
}