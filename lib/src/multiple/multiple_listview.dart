import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

/// The open list of a [MultipleSearchDropDown]: a search field and the items.
class MultipleListView<T> extends StatefulWidget {
  /// Creates the list for [controller].
  const MultipleListView({
    super.key,
    required this.controller,
    required this.overlayListSettings,
    required this.searchBarSettings,
    this.addAdditionalWidget,
    this.defaultAdditionalWidget,
    this.strings,
  });

  /// Source of items, selection and filtering.
  final MultipleSearchDropDownController<T> controller;

  /// The settings for the overlay list of items.
  final SimpleOverlaySettings overlayListSettings;

  /// The settings of the search bar.
  final SimpleSearchbarSettings searchBarSettings;

  /// Widget shown on the add-item row.
  final Widget? addAdditionalWidget;

  /// Widget shown on every item row.
  final Widget? defaultAdditionalWidget;

  /// Source of the default texts; `null` uses [SearchDropDownStringsScope]
  /// (Portuguese without one).
  final SearchDropDownStrings? strings;

  @override
  State<MultipleListView<T>> createState() => _MultipleListViewState<T>();
}

class _MultipleListViewState<T> extends State<MultipleListView<T>> {
  final TextEditingController _search = TextEditingController();
  final ItemScrollController _scroll = ItemScrollController();
  // The overlay lives outside any route, so the list brings its own storage.
  final PageStorageBucket _bucket = PageStorageBucket();

  MultipleSearchDropDownController<T> get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _controller.refresh();
    WidgetsBinding.instance.addPostFrameCallback((_) => _goToSelected());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Scrolls to the first selected item when the list (re)opens.
  void _goToSelected() {
    if (!mounted || _controller.selectedItems.isEmpty || !_scroll.isAttached) {
      return;
    }
    final int index = _controller.filteredItems.indexOf(
      _controller.selectedItems.first,
    );
    if (index > 1) {
      _scroll.scrollTo(
        index: index,
        duration: widget.overlayListSettings.reOpenedScrollDuration,
        curve: Curves.ease,
      );
    }
  }

  Future<void> _add(String text) async {
    // Clear right away: a rejected item must not linger in the field (#13).
    _search.clear();
    await _controller.addItem(text, context, strings: widget.strings);
  }

  @override
  Widget build(BuildContext context) {
    final SimpleSearchbarSettings bar = widget.searchBarSettings;
    final SimpleOverlaySettings list = widget.overlayListSettings;
    final Color background = list.dialogBackgroundColor ?? bar.backgroundColor;
    final SearchDropDownStrings texts =
        widget.strings ?? SearchDropDownStrings.of(context);
    return Card(
      surfaceTintColor: background,
      color: background,
      elevation: bar.elevation,
      child: AnimatedContainer(
        duration: list.animationDuration,
        height: list.dialogHeight,
        width: bar.dropdownWidth,
        child: Column(
          children: <Widget>[
            SearchBar(
              controller: _search,
              backgroundColor: WidgetStatePropertyAll<Color>(
                bar.backgroundColor,
              ),
              overlayColor: WidgetStatePropertyAll<Color>(
                list.unselectedItemHoverColor,
              ),
              constraints: BoxConstraints(
                minHeight: bar.dropdownHeight,
                maxWidth: bar.dropdownWidth,
              ),
              surfaceTintColor: WidgetStatePropertyAll<Color>(
                bar.backgroundColor,
              ),
              shape: WidgetStatePropertyAll<OutlinedBorder>(bar.border),
              hintText: bar.customHint ?? texts.searchHint,
              hintStyle: WidgetStatePropertyAll<TextStyle?>(bar.hintStyle),
              textStyle: WidgetStatePropertyAll<TextStyle?>(
                bar.searchBarTextStyle ?? bar.hintStyle,
              ),
              side: const WidgetStatePropertyAll<BorderSide>(
                BorderSide(style: BorderStyle.none),
              ),
              onChanged: _controller.search,
              elevation: WidgetStatePropertyAll<double>(bar.elevation),
            ),
            const SizedBox(height: 5),
            Expanded(
              child: PageStorage(
                bucket: _bucket,
                child: ListenableBuilder(
                  listenable: _controller,
                  builder: (BuildContext context, _) {
                    final List<ValueItem<T>> items = _controller.filteredItems;
                    return ScrollablePositionedList.separated(
                      itemScrollController: _scroll,
                      padding: EdgeInsets.zero,
                      itemCount: items.length + (_controller.addMode ? 1 : 0),
                      separatorBuilder: (BuildContext context, int index) =>
                          SizedBox(height: list.separatorHeight),
                      itemBuilder: (BuildContext context, int index) {
                        if (index == items.length) {
                          return _controller.canAdd
                              ? DefaultAddListItem(
                                  itemAdded: _add,
                                  overlayListSettings: list,
                                  text: _controller.query,
                                  addAdditionalWidget:
                                      widget.addAdditionalWidget,
                                  strings: texts,
                                )
                              : const SizedBox.shrink();
                        }
                        final ValueItem<T> item = items[index];
                        return DefaultListTile<T>(
                          // The row state (its spinner) belongs to the
                          // item, not the index.
                          key: ValueKey<ValueItem<T>>(item),
                          deleteMode: _controller.deleteMode,
                          editMode: _controller.editMode,
                          item: item,
                          onDelete: (ValueItem<T> value) =>
                              _controller.deleteItem(
                                value,
                                context,
                                strings: widget.strings,
                              ),
                          onEdit: (ValueItem<T> value) => _controller.editItem(
                            value,
                            context,
                            strings: widget.strings,
                          ),
                          onPressed: _controller.toggle,
                          overlayListSettings: list,
                          selected: _controller.isSelected(item),
                          defaultAdditionalWidget:
                              widget.defaultAdditionalWidget,
                          strings: texts,
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
