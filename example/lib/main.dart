// The "Print ..." buttons write to the console on purpose: they show what
// the app reads back from the controllers.
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';
import 'package:simple_search_dropdown_example/custom.dart';
import 'package:simple_search_dropdown_example/dialog_test.dart';
import 'package:simple_search_dropdown_example/listitems.dart';

void main() {
  runApp(const MyApp());
}

/// The app's Material 3 theme, seeded from the package's [darkGreen].
ThemeData exampleTheme(Brightness brightness) => ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: darkGreen,
        brightness: brightness,
      ),
      useMaterial3: true,
    );

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple Search Dropdown',
      debugShowCheckedModeBanner: false,
      theme: exampleTheme(Brightness.light),
      // Follows the system setting: the dropdowns and dialogs take their
      // surfaces from the theme.
      darkTheme: exampleTheme(Brightness.dark),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

/// Three dropdowns: a single and a multiple one over a list the app shares
/// between them, and a single one over a custom value type.
///
/// Each controller keeps its own copy of the items. The app owns [items]:
/// the add/edit/delete callbacks of one dropdown update it and hand it to
/// the other dropdown with `updateListItems`.
class _MyHomePageState extends State<MyHomePage> {
  final List<ValueItem> items = List.of(initialItems);

  late final SearchDropDownController singleController;
  late final MultipleSearchDropDownController multipleController;
  late final SearchDropDownController<Custom> customController;

  ValueItem? selectedSingleItem = initialItems[1];
  List<ValueItem> selectedMultipleItems = [];
  ValueItem<Custom>? selectedCustomItem = initialCustomItems.first;

  @override
  void initState() {
    super.initState();

    singleController = SearchDropDownController(
      items: items,
      initialSelectedItem: selectedSingleItem,
      newValueItem: (input) => ValueItem(label: input, value: input),
      // Slow callbacks: the row shows a spinner until they complete.
      onAddItem: (item) async {
        await Future<void>.delayed(const Duration(seconds: 2));
        items.add(item);
        syncMultiple();
      },
      onDeleteItem: (item) async {
        await Future<void>.delayed(const Duration(seconds: 2));
        items.remove(item);
        syncMultiple();
      },
      confirmDelete: true,
      editMode: true,
      onEditItem: (item, edited) {
        replaceItem(item, edited);
        syncMultiple(edited: item, by: edited);
      },
      updateSelectedItem: (item) => selectedSingleItem = item,
      verifyInputItem: (item) => item.label != 'name',
      sort: SortType.selectedFirst,
      enabled: false,
    );

    multipleController = MultipleSearchDropDownController(
      items: items,
      selectedItems: selectedMultipleItems,
      updateSelectedItems: (selected) => selectedMultipleItems = selected,
      newValueItem: (input) => ValueItem(label: input, value: input),
      onAddItem: (item) {
        items.add(item);
        syncSingle();
      },
      onDeleteItem: (item) {
        items.remove(item);
        syncSingle();
      },
      confirmDelete: true,
      editMode: true,
      onEditItem: (item, edited) {
        replaceItem(item, edited);
        syncSingle(edited: item, by: edited);
      },
      onClearList: () => showMessage('Selection cleared'),
      onClearItem: (item) => showMessage('Removed ${item.label}'),
    );

    customController = SearchDropDownController<Custom>(
      items: initialCustomItems,
      initialSelectedItem: selectedCustomItem,
      addMode: false,
      // Nothing else shows these items, so the controller's copy is enough.
      onDeleteItem: (item) => showMessage('Deleted ${item.label}'),
      confirmDelete: true,
      updateSelectedItem: (item) => selectedCustomItem = item,
      sort: SortType.selectedFirst,
    );
  }

  @override
  void dispose() {
    singleController.dispose();
    multipleController.dispose();
    customController.dispose();
    super.dispose();
  }

  /// Confirms a callback with a short floating SnackBar.
  void showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  void replaceItem(ValueItem item, ValueItem edited) {
    final int index = items.indexOf(item);
    if (index >= 0) {
      items[index] = edited;
    }
  }

  /// Hands [items] to the single dropdown, keeping its selection (following
  /// it when the selected item was [edited] into [by]).
  void syncSingle({ValueItem? edited, ValueItem? by}) {
    ValueItem? selected = singleController.selectedItem;
    if (edited != null && selected == edited) {
      selected = by;
    }
    // updateListItems resets a selection; select it again if it is still there.
    singleController.updateListItems(items, false);
    if (selected != null && items.contains(selected)) {
      singleController.selectItem(selected);
    }
  }

  /// Hands [items] to the multiple dropdown; a selected item that was
  /// [edited] stays selected as [by].
  void syncMultiple({ValueItem? edited, ValueItem? by}) {
    final bool wasSelected =
        edited != null && multipleController.isSelected(edited);
    multipleController.updateListItems(items, false);
    if (wasSelected && by != null) {
      multipleController.toggle(by, forced: true);
    }
  }

  void resetCustom() {
    customController.updateListItems(<ValueItem<Custom>>[
      ValueItem(label: 'Reset 1', value: Custom('Reset 1', 80)),
      ValueItem(label: 'Reset 2', value: Custom('Reset 2', 90)),
    ], true);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Simple Search Dropdown')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints box) {
                  final double width = box.maxWidth;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Section(
                        title: 'Single selection',
                        description: 'Add, edit and delete with slow (2 s) '
                            'callbacks. Starts disabled.',
                        dropdown: SearchDropDown(
                          controller: singleController,
                          // This State creates and disposes the controllers.
                          disposeController: false,
                          searchBarSettings: SimpleSearchbarSettings(
                            dropdownWidth: width,
                            showKeyboardOnTap: false,
                            // `actions` replaces the arrow and clear icons.
                            actions: const [
                              Padding(
                                padding: EdgeInsets.only(right: 8),
                                child: Icon(Icons.search),
                              ),
                            ],
                            showDivider: true,
                            clearOnClose: true,
                          ),
                        ),
                        actions: [
                          (
                            'Enable/Disable Single Selection',
                            singleController.toggleEnabled,
                          ),
                          (
                            'Force Single Selection',
                            () => singleController.forceSelection('one more'),
                          ),
                          (
                            'Clear Single Selection',
                            singleController.resetSelection,
                          ),
                          (
                            'Print Single Result',
                            () {
                              print(selectedSingleItem);
                              print(
                                singleController.localSearchController.text,
                              );
                              print(singleController.selectedItem);
                            },
                          ),
                          (
                            'Print new Single Selection',
                            () => print(singleController.selectedItem?.label),
                          ),
                        ],
                      ),
                      _Section(
                        title: 'Multiple selection',
                        description:
                            'Shares its list with the single dropdown.',
                        dropdown: MultipleSearchDropDown(
                          controller: multipleController,
                          searchBarSettings:
                              SimpleSearchbarSettings(dropdownWidth: width),
                        ),
                        actions: [
                          (
                            'Force Multiple Selection',
                            () => multipleController.forceSelection('one more'),
                          ),
                          (
                            'Clear Multiple Selection',
                            multipleController.resetSelection,
                          ),
                          (
                            'Print Multiple Result',
                            () => print(selectedMultipleItems),
                          ),
                        ],
                      ),
                      _Section(
                        title: 'Custom type and row',
                        description: 'SearchDropDown<Custom> with a custom '
                            'itemWidgetBuilder.',
                        dropdown: SearchDropDown<Custom>(
                          controller: customController,
                          disposeController: false,
                          searchBarSettings: SimpleSearchbarSettings(
                            dropdownWidth: width,
                            showArrow: false,
                          ),
                          overlayListSettings: SimpleOverlaySettings(
                            dialogHeight: 280,
                            // The row's own text colours need a selected
                            // fill they contrast with, light and dark.
                            selectedItemBackgroundColor:
                                scheme.secondaryContainer,
                            itemWidgetBuilder: (item) => PersonRow(
                              item: item,
                            ),
                          ),
                        ),
                        actions: [
                          (
                            'Print Custom Result',
                            () {
                              final ValueItem<Custom>? custom =
                                  selectedCustomItem;
                              print(custom);
                              if (custom != null) {
                                print('name: ${custom.value!.name}');
                                print(custom.runtimeType);
                              }
                            },
                          ),
                          (
                            'Clear Custom Selection',
                            customController.resetSelection,
                          ),
                          ('Reset custom list', resetCustom),
                        ],
                      ),
                      _Section(
                        title: 'Inside a dialog',
                        description: 'A read-only dropdown over the shared '
                            'list.',
                        actions: [
                          (
                            'Open Dialog',
                            () => showDialog<void>(
                                  context: context,
                                  builder: (BuildContext context) =>
                                      DialogTest(items: items),
                                ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A custom list row: an initial in a circle, the name and the id below it.
/// Its text colours come from the theme, so it reads in light and dark.
class PersonRow extends StatelessWidget {
  const PersonRow({required this.item, super.key});

  final ValueItem item;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Object? value = item.value;
    final String label = item.label;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: scheme.primaryContainer,
            foregroundColor: scheme.onPrimaryContainer,
            child: Text(
              label.isEmpty ? '?' : label.characters.first.toUpperCase(),
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
                if (value is Custom)
                  Text(
                    'ID ${value.id}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A titled block of the demo page: a description, the dropdown and its
/// demo buttons, with the page's standard spacing.
class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.description,
    required this.actions,
    this.dropdown,
  });

  final String title;
  final String description;
  final Widget? dropdown;
  final List<(String, VoidCallback)> actions;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (dropdown != null) ...[
            const SizedBox(height: 16),
            dropdown!,
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (String label, VoidCallback onPressed) in actions)
                OutlinedButton(onPressed: onPressed, child: Text(label)),
            ],
          ),
        ],
      ),
    );
  }
}
