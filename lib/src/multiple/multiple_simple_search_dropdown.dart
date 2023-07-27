import 'package:flutter/material.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

class MultipleSearchDropDown extends StatefulWidget {
  const MultipleSearchDropDown({
    Key? key,
    required this.listItems,
    required this.addMode,
    this.action,
    this.activeHoverColor,
    this.animationDuration,
    this.backgroundColor,
    this.border,
    this.createHint,
    this.createHintStyle,
    required this.deleteMode,
    this.deactivateHoverColor,
    this.dialogActionIcon,
    this.dialogActionWidget,
    this.dialogBackgroundColor,
    this.dialogHeight = 300,
    this.dialogListviewWidgetBuilder,
    this.dialogSearchBarBorder,
    this.dialogSearchBarColor,
    this.dialogSearchBarElevation = 2,
    this.elevation = 1,
    this.hint,
    this.hintSearchBar,
    this.hintStyle,
    this.insideIconSize = 18,
    this.onAddItem,
    this.onDeleteItem,
    this.outsideIconSize = 20,
    this.selectedDialogColor,
    this.selectedDialogBoxColor,
    this.selectedInsideBoxTextStyle,
    required this.selectedItems,
    this.selectedItemsBoxTextStyle,
    this.seletedItemsBoxColor,
    this.sortSelecteds = true,
    this.unselectedInsideBoxTextStyle,
    required this.updateSelectedItems,
    this.widgetBuilder,
    this.width = 300,
  }) : super(key: key);

  final Widget? action;
  final bool addMode;
  final Color? activeHoverColor;
  final Duration? animationDuration;
  final Color? backgroundColor;
  final String? createHint;
  final TextStyle? createHintStyle;
  final OutlinedBorder? border;
  final bool deleteMode;
  final Color? deactivateHoverColor;
  final Icon? dialogActionIcon;
  final Widget? dialogActionWidget;
  final Color? dialogBackgroundColor;
  final double dialogHeight;
  final Widget? dialogListviewWidgetBuilder;
  final OutlinedBorder? dialogSearchBarBorder;
  final Color? dialogSearchBarColor;
  final double dialogSearchBarElevation;
  final double elevation;
  final String? hint;
  final String? hintSearchBar;
  final TextStyle? hintStyle;
  final double insideIconSize;
  final Function(String)? onAddItem;
  final Function(String)? onDeleteItem;
  final double outsideIconSize;
  final Color? selectedDialogBoxColor;
  final Color? selectedDialogColor;
  final TextStyle? selectedInsideBoxTextStyle;
  final List<String> selectedItems;
  final TextStyle? selectedItemsBoxTextStyle;
  final Color? seletedItemsBoxColor;
  final bool sortSelecteds;
  final TextStyle? unselectedInsideBoxTextStyle;
  final Function(List<String>) updateSelectedItems;
  final List<String> listItems;
  final Widget? widgetBuilder;
  final double width;

  @override
  State<MultipleSearchDropDown> createState() => _MultipleSearchDropDownState();
}

class _MultipleSearchDropDownState extends State<MultipleSearchDropDown> {
  late double altura = 0;
  late bool aberto = false;
  OverlayEntry? overlayEntry;
  final GlobalKey overlayKey = GlobalKey();

  void onItemSelected(String val) {
    setState(() {
      if (widget.selectedItems.contains(val)) {
        widget.selectedItems.remove(val);
      } else {
        widget.selectedItems.add(val);
        widget.updateSelectedItems(widget.selectedItems);
      }
    });
  }

  void handleAddItem(String item, BuildContext context){
    if(widget.addMode){
      widget.onAddItem!(item);
      onItemSelected(item);
      setState(() {});
    }
  }

  void handleDeleteItem(String item, BuildContext context) {
    if(widget.deleteMode){
      widget.onDeleteItem!(item); 
      hideOverlay();
      showOverlay(context);
    }
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
                addMode: widget.addMode,
                activeHoverColor: widget.activeHoverColor, 
                animationDuration: widget.animationDuration, 
                backgroundColor: widget.backgroundColor, 
                border: widget.border, 
                createHint: widget.createHint,
                createHintStyle: widget.createHintStyle,
                deleteMode: widget.deleteMode,
                deactivateHoverColor: widget.deactivateHoverColor, 
                dialogActionIcon: widget.dialogActionIcon,
                dialogActionWidget: widget.dialogActionWidget,
                dialogBackgroundColor: widget.dialogBackgroundColor, 
                dialogHeight: widget.dialogHeight, 
                dialogListviewWidgetBuilder: widget.dialogListviewWidgetBuilder, 
                dialogSearchBarBorder: widget.dialogSearchBarBorder, 
                dialogSearchBarColor: widget.dialogSearchBarColor, 
                dialogSearchBarElevation: widget.dialogSearchBarElevation, 
                elevation: widget.elevation, 
                hintSearchBar: widget.hintSearchBar, 
                hintStyle: widget.hintStyle, 
                listItens: widget.listItems, 
                onAddItem: (val) => handleAddItem(val,context),
                onDeleteItem: (val) => handleDeleteItem(val,context),
                onItemSelected: (val) => onItemSelected(val), 
                selectedDialogBoxColor: widget.selectedDialogBoxColor, 
                selectedDialogColor: widget.selectedDialogColor, 
                selectedInsideBoxTextStyle: widget.selectedInsideBoxTextStyle, 
                selectedItens: widget.selectedItems, 
                sortSelecteds: widget.sortSelecteds,
                unselectedInsideBoxTextStyle: widget.unselectedInsideBoxTextStyle, 
                updateSelectedItems: (val) => widget.updateSelectedItems(val),
                width: widget.width
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
                      child: widget.selectedItems.isNotEmpty 
                      ?ScrollConfiguration(
                        behavior: MyCustomScrollBehavior(),
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          separatorBuilder: (context, index) => const SizedBox(width: 5),
                          itemCount: widget.selectedItems.length,
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
                                      Text(widget.selectedItems[index],style:widget.selectedInsideBoxTextStyle),
                                      InkWell(
                                        onTap: () =>
                                            onItemSelected(widget.selectedItems[index]),
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
                              widget.selectedItems.clear();
                            });
                          }, 
                          child: Icon(
                            widget.selectedItems.isNotEmpty 
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