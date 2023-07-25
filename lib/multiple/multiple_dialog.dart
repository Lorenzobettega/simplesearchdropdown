import 'package:flutter/material.dart';
import 'package:searchdialog/extensions.dart';
import 'package:searchdialog/multiple/content_dialog_multiple.dart';

class MultipleDialog extends StatefulWidget {
  const MultipleDialog({super.key,
    required this.listItems,
    this.dialogHeight = 300,
    this.animationDuration,
    this.hint,
    this.border,
    this.width = 300,
    this.widgetBuilder,
    this.elevation = 1,
    this.backgroundColor,
    this.insideIconSize = 18,
    this.outsideIconSize = 20,
    this.selectedItemsBoxTextStyle,
    this.seletedItemsBoxColor,
    this.dialogBackgroundColor,
    this.hintStyle,
    this.hoverColor,
    this.selectedDialogColor,
    this.selectedInsideBoxTextStyle,
    this.unselectedInsideBoxTextStyle,
    this.action,
  });

  final List<String> listItems;
  final double dialogHeight;
  final Duration? animationDuration;
  final String? hint;
  final OutlinedBorder? border;
  final double width;
  final Widget? widgetBuilder;
  final double elevation;
  final double insideIconSize;
  final double outsideIconSize;
  final TextStyle? selectedItemsBoxTextStyle;
  final Color? seletedItemsBoxColor;
  final Color? backgroundColor;
  final Color? dialogBackgroundColor;
  final Color? hoverColor;
  final TextStyle? hintStyle;
  final Color? selectedDialogColor;
  final TextStyle? selectedInsideBoxTextStyle;
  final TextStyle? unselectedInsideBoxTextStyle;
  final Widget? action;

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
      width: widget.width,
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
              constraints: BoxConstraints(
                maxHeight: 50,
                maxWidth: widget.width,
                minHeight: 50,
                minWidth: widget.width,
              ),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                color: widget.backgroundColor ?? Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 0.5,
                    blurRadius: 1 * widget.elevation,
                    offset: Offset(0, 0.5 * widget.elevation),
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
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: Card(
                                color: widget.seletedItemsBoxColor ?? Colors.grey.shade300,
                                elevation: widget.elevation,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(selectedItems[index],style:widget.selectedInsideBoxTextStyle),
                                      InkWell(
                                        onTap: () =>
                                            onItemSelected(selectedItems[index]),
                                        child: Icon(Icons.close,size: widget.insideIconSize,),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ): Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.hint ?? 'Selecione',textAlign: TextAlign.start,style: widget.hintStyle,),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 5),
                        widget.action ?? InkWell(
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
                                : Icons.arrow_drop_down,size: widget.outsideIconSize,),
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
