import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';
import 'package:simple_search_dropdown/src/core/theme_colors.dart';

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
    _open();
  }

  /// Opens the list fresh on [_controller] (re-reads its items) and scrolls
  /// to the selection after the frame.
  void _open() {
    _controller
      ..refresh()
      ..addListener(_syncField);
    WidgetsBinding.instance.addPostFrameCallback((_) => _goToSelected());
  }

  @override
  void didUpdateWidget(covariant MultipleListView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final MultipleSearchDropDownController<T> old = oldWidget.controller;
    if (identical(old, _controller)) {
      return;
    }
    // The parent may have disposed the old controller already.
    if (!old.isDisposed) {
      old.removeListener(_syncField);
    }
    // A swapped-in controller opens fresh but keeps what the user typed, so
    // field and list agree.
    _open();
    if (_search.text.isNotEmpty) {
      _controller.search(_search.text);
    }
  }

  @override
  void dispose() {
    if (!_controller.isDisposed) {
      _controller.removeListener(_syncField);
    }
    _search.dispose();
    super.dispose();
  }

  /// Shows the controller's query in the field: an add clears both once it
  /// is done (a rejected item at once, #13), a failed one keeps both.
  /// Assigning the value does not fire `onChanged`, and typing already makes
  /// them equal, so this never loops nor touches an IME composition.
  void _syncField() {
    final String query = _controller.query;
    if (_search.text != query) {
      _search.value = TextEditingValue(
        text: query,
        selection: TextSelection.collapsed(offset: query.length),
      );
    }
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

  Future<void> _add(String text) =>
      _controller.addItem(text, context, strings: widget.strings);

  @override
  Widget build(BuildContext context) {
    final SimpleSearchbarSettings bar = widget.searchBarSettings;
    final SimpleOverlaySettings list = widget.overlayListSettings;
    final ThemeData theme = Theme.of(context);
    final BarColors colors = BarColors.of(bar, theme);
    final Color background = list.dialogBackgroundColor ?? colors.background;
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
              backgroundColor: WidgetStatePropertyAll<Color>(colors.background),
              overlayColor: WidgetStatePropertyAll<Color>(
                ListColors.of(list, theme).unselectedHover,
              ),
              constraints: BoxConstraints(
                minHeight: bar.dropdownHeight,
                maxWidth: bar.dropdownWidth,
              ),
              surfaceTintColor: WidgetStatePropertyAll<Color>(
                colors.background,
              ),
              shape: WidgetStatePropertyAll<OutlinedBorder>(bar.border),
              hintText: bar.customHint ?? texts.searchHint,
              hintStyle: WidgetStatePropertyAll<TextStyle?>(colors.hintStyle),
              textStyle: WidgetStatePropertyAll<TextStyle?>(
                bar.searchBarTextStyle ?? colors.hintStyle,
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
