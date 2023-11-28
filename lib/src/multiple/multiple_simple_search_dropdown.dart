import 'package:flutter/material.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

///This creates a multiple selection dropdown widget.
class MultipleSearchDropDown<T> extends StatefulWidget {
  const MultipleSearchDropDown({
    super.key,
    required this.listItems,
    this.addMode = true,
    this.onAddItem,
    this.newValueItem,
    this.deleteMode = true,
    this.onDeleteItem,
    required this.updateSelectedItems,
    this.sortType = 0,
    this.confirmDelete = false,
    this.elevation = 2,
    this.dropdownWidth = 300,
    this.dropdownHeight = 50,
    this.arrowIconSize = 20,
    this.boxSelectedIconSize = 20,
    this.dialogSearchBarElevation = 2,
    this.actionWidget,
    this.animationDuration,
    this.backgroundColor,
    this.border,
    this.createHint,
    this.createHintStyle,
    this.dialogActionIcon,
    this.dialogActionWidget,
    this.dialogBackgroundColor,
    this.dialogHeight,
    this.dialogListviewWidgetBuilder,
    this.dialogSearchBarBorder,
    this.dialogSearchBarColor,
    this.dropdownClosedArrowIcon,
    this.dropdownOpenedArrowIcon,
    this.hint,
    this.hintSearchBar,
    this.hintStyle,
    this.boxSelectedIconColor,
    this.itemsPadding,
    this.selectedItemsColor,
    this.boxSelectedTextStyle,
    required this.selectedItems,
    this.selectedItemsTextStyle,
    this.boxSelectedColor,
    this.selectedItemHoverColor,
    this.separatorHeight,
    this.unselectedItemsTextStyle,
    this.unselectedItemHoverColor,
    this.dropdownWidgetBuilder,
    this.arrowIconColor,
    this.deleteDialogSettings,
    this.verifyInputItem,
    this.verifyDialogSettings,
  })  : assert(
            (addMode && (newValueItem != null && onAddItem != null)) ||
                !addMode,
            'addMode can only be used with newValueItem != null && onAddItem != null'),
        assert((deleteMode && onDeleteItem != null) || !deleteMode,
            'deleteMode can only be used with onDeleteItem != null');

  ///List of the items to be presented on the dropdown.
  final List<ValueItem<T>> listItems;
  ///List of the items already selected on the dropdown.
  final List<ValueItem<T>> selectedItems;
  ///Function to update the list of selected items on change
  final Function(List<ValueItem<T>>) updateSelectedItems;
  ///Allow the user to add items to the list.
  final bool addMode;
  ///Function to be executed after the item was added.
  final Function(ValueItem<T>)? onAddItem;
  ///Function that defines how the user input transforms into a new ValueItem on the list.
  ///
  ///Ex:`newValueItem: (input) => ValueItem(label: input, value: input)`
  final ValueItem<T> Function(String input)? newValueItem;
  ///Allow the user to delete items of the list.
  final bool deleteMode;
  ///Function to be executed after the item was deleted.
  final Function(ValueItem<T>)? onDeleteItem;
  ///Force the user to confirm delete
  final bool confirmDelete;
  ///Visual delete dialog settings
  final DialogSettings? deleteDialogSettings;
  ///The action widget on dropdown
  final Widget? actionWidget;
  ///The duration of the dropdown opening animation.
  final Duration? animationDuration;
  ///The background color of the searchbar and overlay.
  final Color? backgroundColor;
  ///Border of dropdown
  final OutlinedBorder? border;
  ///Outside/horizontal list of selecteds items Widget builder
  final Widget? dropdownWidgetBuilder;
  ///Outside/horizontal list of selecteds clear icon size(default:20)
  final double boxSelectedIconSize;
  ///Outside/horizontal list of selecteds clear icon Color(default:20)
  final Color? boxSelectedIconColor;
  ///Outside/horizontal list of selecteds box color
  final Color? boxSelectedColor;
  ///Outside/horizontal list of selecteds box Text Style
  final TextStyle? boxSelectedTextStyle;
  ///Dropdown height(default:50)
  final double dropdownHeight;
  ///Dropdown Width(default:300)
  final double dropdownWidth;
  //Dropdown elevation
  final double elevation;
  //Dropdown hint(default:'Selecione')
  final String? hint;
  ///Action Icon showed when dropdown is closed
  final IconData? dropdownClosedArrowIcon;
  ///Action Icon showed when dropdown is opened
  final IconData? dropdownOpenedArrowIcon;
  ///Action Icon size
  final double arrowIconSize;
  ///Action Icon color
  final Color? arrowIconColor;
  ///Dropdown Container color
  final Color? dialogBackgroundColor;
  ///Dropdown Container heigth
  final double? dialogHeight;
  ///The way the items should be sorted.
  ///
  ///If `0`(default), no sort will be applied
  ///
  ///If `1`, the items will be sorted on alphabetical order.
  ///
  ///If `2`, the items will be sorted on reverse alphabetical order.
  ///
  ///If `3`, the selected item will be put on first position.
  final int sortType;
  ///Custom droplist item widget.
  final Widget? dialogListviewWidgetBuilder;
  ///Custom droplist action icon.
  final Icon? dialogActionIcon;
  ///Custom droplist action Widget.
  final Widget? dialogActionWidget;
  ///Droplist separator height.
  final double? separatorHeight;
  ///Droplist item padding(default: EdgeInsets.symmetric(horizontal: 4))
  final EdgeInsets? itemsPadding;
  ///Searchbar border
  final OutlinedBorder? dialogSearchBarBorder;
  ///Searchbar color
  final Color? dialogSearchBarColor;
  ///Searchbar elevation
  final double dialogSearchBarElevation;
  ///Searchbar hint
  final String? hintSearchBar;
  ///Searchbar hint TextStyle
  final TextStyle? hintStyle;
  ///Create button text
  final String? createHint;
  ///Create button TextStyle
  final TextStyle? createHintStyle;
  ///Function to check if the item added is valid or not.
  final bool Function(ValueItem<T>)? verifyInputItem;
  ///Visual verify dialog settings
  final DialogSettings? verifyDialogSettings;
  ///Selected droplist items background color
  final Color? selectedItemsColor;
  ///Selected droplist items Text Style
  final TextStyle? selectedItemsTextStyle;
  ///Unselected droplist items Text Style
  final TextStyle? unselectedItemsTextStyle;
  ///Selected droplist items hover color
  final Color? selectedItemHoverColor;
  ///Unselected droplist items hover color
  final Color? unselectedItemHoverColor;
  

  @override
  State<MultipleSearchDropDown<T>> createState() =>
      MultipleSearchDropDownState<T>();
}

class MultipleSearchDropDownState<T> extends State<MultipleSearchDropDown<T>> {
  bool aberto = false;
  late OverlayScreen overlayScreen;
  final LayerLink _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    overlayScreen = OverlayScreen.of(context);
  }

  void onItemSelected(ValueItem<T> val) {
    setState(() {
      if (widget.selectedItems.contains(val)) {
        widget.selectedItems.remove(val);
      } else {
        widget.selectedItems.add(val);
      }
      widget.updateSelectedItems(widget.selectedItems);
    });
  }

  void resetSelection() {
    setState(() {
      widget.selectedItems.clear();
    });
  }

  void handleAddItem(ValueItem<T> item, BuildContext context) {
    if (widget.addMode) {
      if (widget.verifyInputItem != null) {
        if (!widget.verifyInputItem!(item)) {
          //TODO arrumar pra não parecer que o item foi adicionado
          //TODO na pratica o item é visualmente adicionado e depois removido. Ajustar pra nem adicionar.
          return overlayScreen.show(
            OverlayEntry(
              builder: (context) => WarningDialog(
                confirmDialog: false,
                returnFunction: (result) {
                  overlayScreen.closeLast();
                },
                settings: widget.verifyDialogSettings,
              ),
            ),
          );
        }
      }
      widget.onAddItem!(item);
      onItemSelected(item);
      setState(() {});
    }
  }

  void handleDeleteItem(ValueItem<T> item, BuildContext context) {
    if (widget.deleteMode) {
      if (widget.confirmDelete) {
        overlayScreen.show(
          OverlayEntry(
            builder: (context) => WarningDialog(
              returnFunction: (result) {
                if (result) {
                  widget.onDeleteItem!(item);
                  resetSelection();
                }
                overlayScreen.closeLast();
              },
              settings: widget.deleteDialogSettings,
            ),
          ),
        );
      } else {
        setState(() {
          widget.onDeleteItem!(item);
          hideOverlay();
          _showOverlay(context);
        });
      }
    }
  }

  void _showOverlay(
    BuildContext context,
  ) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    overlayScreen.show(
      OverlayEntry(
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
              width: size.width,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: Offset(0.0, size.height + 3.0),
                child: Material(
                  color: Colors.transparent,
                  child: MultipleListView(
                    addMode: widget.addMode,
                    animationDuration: widget.animationDuration,
                    backgroundColor: widget.backgroundColor,
                    border: widget.border,
                    createHint: widget.createHint,
                    createHintStyle: widget.createHintStyle,
                    deleteMode: widget.deleteMode,
                    dialogActionIcon: widget.dialogActionIcon,
                    dialogActionWidget: widget.dialogActionWidget,
                    dialogBackgroundColor: widget.dialogBackgroundColor,
                    dialogHeight: widget.dialogHeight ?? 200,
                    dialogListviewWidgetBuilder:
                        widget.dialogListviewWidgetBuilder,
                    dialogSearchBarBorder: widget.dialogSearchBarBorder,
                    dialogSearchBarColor: widget.dialogSearchBarColor,
                    dialogSearchBarElevation: widget.dialogSearchBarElevation,
                    elevation: widget.elevation,
                    hintSearchBar: widget.hintSearchBar,
                    hintStyle: widget.hintStyle,
                    listItens: widget.listItems,
                    onAddItem: (val) => handleAddItem(val, context),
                    onDeleteItem: (val) => handleDeleteItem(val, context),
                    onItemSelected: (val) => onItemSelected(val),
                    itemsPadding: widget.itemsPadding,
                    selectedDialogColor: widget.selectedItemsColor,
                    selectedInsideBoxTextStyle:
                        widget.selectedItemsTextStyle,
                    selectedItemHoverColor: widget.selectedItemHoverColor,
                    selectedItens: widget.selectedItems,
                    separatorHeight: widget.separatorHeight,
                    sortType: widget.sortType,
                    unselectedInsideBoxTextStyle:
                        widget.unselectedItemsTextStyle,
                    unselectedItemHoverColor: widget.unselectedItemHoverColor,
                    width: widget.dropdownWidth,
                    minHeight: widget.dropdownHeight,
                    newValueItem: widget.newValueItem,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void hideOverlay() {
    setState(() {
      aberto = !aberto;
    });
    overlayScreen.closeAll();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: SizedBox(
        height: widget.dropdownHeight,
        width: widget.dropdownWidth,
        child: InkWell(
          onTap: () {
            if (overlayScreen.overlayEntrys.isEmpty) {
              setState(() {
                aberto = !aberto;
              });
              _showOverlay(context);
            } else {
              hideOverlay();
            }
          },
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  color: widget.backgroundColor ?? Colors.white,
                  border: Border.all(style: BorderStyle.none),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey
                          .withOpacity(widget.elevation != 0 ? 0.5 : 0),
                      spreadRadius: 0.5,
                      blurRadius: widget.elevation,
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
                            ? ScrollConfiguration(
                                behavior: MyCustomScrollBehavior(),
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(width: 5),
                                  itemCount: widget.selectedItems.length,
                                  itemBuilder: (context, index) {
                                    return widget.dropdownWidgetBuilder ?? Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 5),
                                      child: Card(
                                        color: widget.boxSelectedColor ??
                                            Colors.grey.shade300,
                                        elevation: widget.elevation,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                  widget.selectedItems[index]
                                                      .label,
                                                  style: widget
                                                      .boxSelectedTextStyle),
                                              InkWell(
                                                onTap: () => onItemSelected(
                                                    widget
                                                        .selectedItems[index]),
                                                child: Icon(
                                                  Icons.close,
                                                  size: widget.boxSelectedIconSize,
                                                  color:
                                                      widget.boxSelectedIconColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.hint ?? 'Selecione',
                                    textAlign: TextAlign.start,
                                    style: widget.hintStyle,
                                  ),
                                ],
                              ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 5),
                          widget.actionWidget ??
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    widget.selectedItems.clear();
                                    widget.updateSelectedItems(
                                        widget.selectedItems);
                                  });
                                },
                                child: Icon(
                                  widget.selectedItems.isNotEmpty
                                      ? Icons.clear
                                      : aberto
                                          ? widget.dropdownOpenedArrowIcon ??
                                              Icons.arrow_drop_up
                                          : widget.dropdownClosedArrowIcon ??
                                              Icons.arrow_drop_down,
                                  size: widget.arrowIconSize,
                                  color: widget.arrowIconColor,
                                ),
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
      ),
    );
  }
}
