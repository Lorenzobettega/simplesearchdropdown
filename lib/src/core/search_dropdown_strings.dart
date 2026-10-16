import 'package:flutter/widgets.dart';

/// Every user-facing text used by the dropdowns and their dialogs.
///
/// Defaults are Portuguese (the 7.x texts). Use [SearchDropDownStrings.en] for
/// English, or pass any field to override it. Provide one for the whole app
/// with [SearchDropDownStringsScope], or per widget with its `strings`
/// parameter. A text set explicitly in a settings object (for example
/// `SimpleSearchbarSettings.hint`) still wins over these.
@immutable
class SearchDropDownStrings {
  /// Portuguese texts (default).
  const SearchDropDownStrings({
    this.searchHint = 'Pesquisar',
    this.addItem = 'Criar',
    this.editTitle = 'Editar o item:',
    this.editHint = 'Novo valor',
    this.confirmDeleteTitle = 'Tem certeza?',
    this.confirmDeleteContent = 'Essa ação não poderá ser desfeita.',
    this.invalidItemTitle = 'Erro!',
    this.invalidItemContent = 'O valor adicionado não é válido.',
    this.deleteButton = 'Apagar',
    this.cancelButton = 'Cancelar',
    this.okButton = 'OK',
    this.editButton = 'Editar',
    this.openTooltip = 'Abrir lista',
    this.closeTooltip = 'Fechar lista',
    this.clearTooltip = 'Limpar seleção',
    this.editItemTooltip = 'Editar item',
    this.deleteItemTooltip = 'Apagar item',
    this.removeChipTooltip = 'Remover',
    this.loadingLabel = 'Carregando',
  });

  /// English texts.
  const SearchDropDownStrings.en({
    this.searchHint = 'Search',
    this.addItem = 'Create',
    this.editTitle = 'Edit item:',
    this.editHint = 'New value',
    this.confirmDeleteTitle = 'Are you sure?',
    this.confirmDeleteContent = 'This action cannot be undone.',
    this.invalidItemTitle = 'Error!',
    this.invalidItemContent = 'The value is not valid.',
    this.deleteButton = 'Delete',
    this.cancelButton = 'Cancel',
    this.okButton = 'OK',
    this.editButton = 'Edit',
    this.openTooltip = 'Open list',
    this.closeTooltip = 'Close list',
    this.clearTooltip = 'Clear selection',
    this.editItemTooltip = 'Edit item',
    this.deleteItemTooltip = 'Delete item',
    this.removeChipTooltip = 'Remove',
    this.loadingLabel = 'Loading',
  });

  /// Search bar hint.
  final String searchHint;

  /// Label of the button that creates a new item from the typed text.
  final String addItem;

  /// Title of the edit dialog.
  final String editTitle;

  /// Hint of the edit dialog text field.
  final String editHint;

  /// Title of the delete confirmation dialog.
  final String confirmDeleteTitle;

  /// Body of the delete confirmation dialog.
  final String confirmDeleteContent;

  /// Title of the dialog shown when `verifyInputItem` rejects an item.
  final String invalidItemTitle;

  /// Body of the dialog shown when `verifyInputItem` rejects an item.
  final String invalidItemContent;

  /// Confirm button of the delete dialog.
  final String deleteButton;

  /// Cancel button of the dialogs.
  final String cancelButton;

  /// OK button of the invalid-item dialog.
  final String okButton;

  /// Confirm button of the edit dialog.
  final String editButton;

  /// Tooltip / semantics label of the arrow when the list is closed.
  final String openTooltip;

  /// Tooltip / semantics label of the arrow when the list is open.
  final String closeTooltip;

  /// Tooltip / semantics label of the clear button.
  final String clearTooltip;

  /// Tooltip / semantics label of a row's edit button.
  final String editItemTooltip;

  /// Tooltip / semantics label of a row's delete button.
  final String deleteItemTooltip;

  /// Tooltip / semantics label of a selected chip's remove button.
  final String removeChipTooltip;

  /// Semantics label of the loading indicators.
  final String loadingLabel;

  /// The strings in scope for [context], or the Portuguese defaults.
  // Flutter idiom for inherited lookups.
  // ignore: prefer_constructors_over_static_methods
  static SearchDropDownStrings of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<SearchDropDownStringsScope>()
          ?.strings ??
      const SearchDropDownStrings();
}

/// Provides [SearchDropDownStrings] to every dropdown, controller
/// add/edit/delete dialog and exported dialog or row below it. Put it in
/// `MaterialApp.builder` so dialogs, which open above the pages, see it too.
///
/// ```dart
/// MaterialApp(
///   builder: (context, child) => SearchDropDownStringsScope(
///     strings: const SearchDropDownStrings.en(),
///     child: child!,
///   ),
/// )
/// ```
class SearchDropDownStringsScope extends InheritedWidget {
  /// Provides [strings] to [child].
  const SearchDropDownStringsScope({
    super.key,
    required this.strings,
    required super.child,
  });

  /// The strings provided to the subtree.
  final SearchDropDownStrings strings;

  @override
  bool updateShouldNotify(SearchDropDownStringsScope oldWidget) =>
      strings != oldWidget.strings;
}
