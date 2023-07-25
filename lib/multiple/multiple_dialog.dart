import 'package:flutter/material.dart';
import 'package:searchdialog/extensions.dart';
import 'package:searchdialog/multiple/content_dialog_multiple.dart';

class MultipleDialog extends StatefulWidget {
  const MultipleDialog({super.key,required this.listItems});

  final List<String> listItems;

  @override
  State<MultipleDialog> createState() => _MultipleDialogState();
}

class _MultipleDialogState extends State<MultipleDialog> {
  late double altura = 0;
  late bool aberto = false;
  final List<String> selectedItems = [];
  OverlayEntry? overlayEntry;
  final GlobalKey overlayKey = GlobalKey();

  void onItemSelected(String val) {
    setState(() {
      if (selectedItems.contains(val)) {
        selectedItems.remove(val);
      } else {
        selectedItems.add(val);
      }
    });
  }

  void showOverlay(
    BuildContext context,
  ) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RenderBox widgetPosition =
        overlayKey.currentContext!.findRenderObject() as RenderBox;
    final Offset offset =
        widgetPosition.localToGlobal(Offset.zero, ancestor: overlay);

    overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: hideOverlay,
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
          Positioned(
            top: offset.dy + widgetPosition.size.height,
            left: offset.dx - 4,
            child: Material(
              color: Colors.transparent,
              child: ContentMultiple(
                onItemSelected: (value) => onItemSelected(value),
                listItens: widget.listItems,
                selectedItens: selectedItems,
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(overlayEntry!);
    setState(() {
      aberto = !aberto;
    });

  }

  void hideOverlay() {
    overlayEntry?.remove();
    overlayEntry = null;
    setState(() {
      aberto = !aberto;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      width: 300,
      child: InkWell(
        key: overlayKey,
        onTap: () {
          if (overlayEntry == null) {
            showOverlay(context);
          } else {
            hideOverlay();
          }
        },
        child: Stack(
          children: [
            Container(
              constraints: const BoxConstraints(
                maxHeight: 50,
                maxWidth: 300,
                minHeight: 50,
                minWidth: 300,
              ),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 5,
                    blurRadius: 10,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: selectedItems.isNotEmpty 
                      ?ScrollConfiguration(
                        behavior: MyCustomScrollBehavior(),
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          separatorBuilder: (context, index) => const SizedBox(width: 5),
                          itemCount: selectedItems.length,
                          itemBuilder: (context, index) {
                            return Card(
                              color: Colors.grey.shade300,
                              elevation: 10,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 5),
                                child: Row(
                                  children: [
                                    Text(selectedItems[index]),
                                    InkWell(
                                      onTap: () =>
                                          onItemSelected(selectedItems[index]),
                                      child: const Icon(Icons.close),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ): const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Selecione',textAlign: TextAlign.start,),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 5),
                        InkWell(
                          onTap:  () {
                            setState(() {
                              selectedItems.clear();
                            });
                          }, 
                          child: Icon(
                            selectedItems.isNotEmpty 
                              ? Icons.clear 
                              : aberto  
                                ? Icons.arrow_drop_up
                                : Icons.arrow_drop_down),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
