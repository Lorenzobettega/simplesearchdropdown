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
    this.editMode = false,
    this.onEditItem,
    required this.updateSelectedItems,
    this.sortType = 0,
    this.confirmDelete = false,
    required this.selectedItems,
    this.deleteDialogSettings,
    this.verifyInputItem,
    this.verifyDialogSettings,
    this.searchBarSettings = defaultSearchBarSettings,
    this.overlayListSettings = defaultOverlaySettings,
    this.addAditionalWidget,
    this.defaultAditionalWidget,
    this.enabled = true,
  })  : assert(
            (addMode && (newValueItem != null && onAddItem != null)) ||
                !addMode,
            'addMode can only be used with newValueItem != null && onAddItem != null'),
        assert((deleteMode && onDeleteItem != null) || !deleteMode,
            'deleteMode can only be used with onDeleteItem != null'),
        assert((editMode && onEditItem != null) || !editMode,
            'editMode can only be used with onEditItem != null');

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

  ///Allow the user to edit items to the list.
  final bool editMode;

  ///Function to be executed after the item was added.
  final Function(ValueItem<T>)? onEditItem;

  ///Force the user to confirm delete
  final bool confirmDelete;

  ///Visual delete dialog settings
  final DialogSettings? deleteDialogSettings;

  ///The SearchBarSettings.
  final SimpleSearchbarSettings searchBarSettings;

  ///The settings for the overlay list of items.
  final SimpleOverlaySettings overlayListSettings;

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

  ///Function to check if the item added is valid or not.
  final bool Function(ValueItem<T>)? verifyInputItem;

  ///Visual verify dialog settings
  final DialogSettings? verifyDialogSettings;

  ///A custom aditional widget to be inserted on the add item cell.
  final Widget? addAditionalWidget;

  ///A custom aditional widget to be inserted on the default item cell.
  final Widget? defaultAditionalWidget;

  ///A parameter to define if the widget is enabled or disabled (default: `true`).
  final bool enabled;

  @override
  State<MultipleSearchDropDown<T>> createState() =>
      MultipleSearchDropDownState<T>();
}

class MultipleSearchDropDownState<T> extends State<MultipleSearchDropDown<T>> {
  bool aberto = false;
  late bool enabled;
  late OverlayScreen overlayScreen;
  final LayerLink _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    enabled = widget.enabled;
    overlayScreen = OverlayScreen.of(context);
  }

  void onItemSelected(ValueItem<T> val, {bool forced = false}) {
    setState(() {
      if (widget.selectedItems.contains(val)) {
        if (!forced) {
          widget.selectedItems.remove(val);
        }
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

  void forceSelection(String label) {
    final ValueItem<T>? val =
        widget.listItems.where((element) => element.label == label).firstOrNull;
    if (val != null) {
      onItemSelected(val, forced: true);
    }
  }

  void enableDisable() {
    setState(() {
      enabled = !enabled;
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
    }
  }

  void handleDeleteItem(ValueItem<T> item, BuildContext context) {
    if (widget.deleteMode) {
      if (widget.confirmDelete) {
        return overlayScreen.show(
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
        widget.onDeleteItem!(item);
        resetSelection();
        overlayScreen.updateLast();
      }
    }
  }

  // TODO verificar como vai ser feito
  // void handleEditItem(ValueItem<T> item, BuildContext context) {
  //   if (widget.editMode) {
  //     widget.onEditItem!(item);
  //     resetSelection();
  //     overlayScreen.updateLast();
  //   }
  // }

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
                offset: Offset(widget.overlayListSettings.offsetWidth,
                    size.height + widget.overlayListSettings.offsetHeight),
                child: Material(
                  color: Colors.transparent,
                  child: MultipleListView(
                    addMode: widget.addMode,
                    deleteMode: widget.deleteMode,
                    editMode: widget.editMode,
                    listItens: widget.listItems,
                    onAddItem: (val) => handleAddItem(val, context),
                    onDeleteItem: (val) => handleDeleteItem(val, context),
                    onEditItem: (val) => (), // TODO colocar função
                    onItemSelected: (val) => onItemSelected(val),
                    selectedItens: widget.selectedItems,
                    sortType: widget.sortType,
                    newValueItem: widget.newValueItem,
                    overlayListSettings: widget.overlayListSettings,
                    searchBarSettings: widget.searchBarSettings,
                    addAditionalWidget: widget.addAditionalWidget,
                    defaultAditionalWidget: widget.defaultAditionalWidget,
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
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.38,
      child: IgnorePointer(
        ignoring: !enabled,
        child: CompositedTransformTarget(
          link: _layerLink,
          child: SizedBox(
            height: widget.searchBarSettings.dropdownHeight,
            width: widget.searchBarSettings.dropdownWidth,
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
                      color: widget.searchBarSettings.backgroundColor,
                      border: Border.all(style: BorderStyle.none),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(
                              widget.searchBarSettings.elevation != 0
                                  ? 0.5
                                  : 0),
                          spreadRadius: 0.5,
                          blurRadius: widget.searchBarSettings.elevation,
                          offset: Offset(
                              0, 0.5 * widget.searchBarSettings.elevation),
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
                                        return widget.searchBarSettings
                                                    .boxMultiItemWidgetBuilder !=
                                                null
                                            ? widget.searchBarSettings
                                                    .boxMultiItemWidgetBuilder!(
                                                widget.selectedItems[index])
                                            : Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 5),
                                                child: Card(
                                                  color: widget
                                                      .searchBarSettings
                                                      .boxMultiSelectedBackgroundColor,
                                                  elevation: widget
                                                      .searchBarSettings
                                                      .elevation,
                                                  child: Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Text(
                                                            widget
                                                                .selectedItems[
                                                                    index]
                                                                .label,
                                                            style: widget
                                                                .searchBarSettings
                                                                .boxMultiSelectedTextStyle),
                                                        InkWell(
                                                          onTap: () =>
                                                              onItemSelected(
                                                                  widget.selectedItems[
                                                                      index]),
                                                          child: Icon(
                                                            Icons.close,
                                                            size: widget
                                                                .searchBarSettings
                                                                .boxMultiSelectedClearIconSize,
                                                            color: widget
                                                                .searchBarSettings
                                                                .boxMultiSelectedClearIconColor,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.searchBarSettings.hint,
                                        textAlign: TextAlign.start,
                                        style:
                                            widget.searchBarSettings.hintStyle,
                                      ),
                                    ],
                                  ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(width: 5),
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
                                      : widget.searchBarSettings.showArrow
                                          ? aberto
                                              ? widget.searchBarSettings
                                                  .dropdownOpenedArrowIcon
                                              : widget.searchBarSettings
                                                  .dropdownClosedArrowIcon
                                          : null,
                                  size:
                                      widget.searchBarSettings.outsideIconSize,
                                  color:
                                      widget.searchBarSettings.outsideIconColor,
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
        ),
      ),
    );
  }
}
