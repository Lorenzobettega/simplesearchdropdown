import 'package:flutter/material.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';
import 'package:simple_search_dropdown/src/dialogs/dialog_layout.dart';

/// Dialog that asks for a new label for an item (used by edit mode). The
/// field starts with [label], fully selected and focused; Enter confirms.
class EditDialog extends StatefulWidget {
  /// Creates an edit dialog for [label].
  const EditDialog({
    super.key,
    required this.label,
    this.settings,
    required this.returnFunction,
    this.strings,
  });

  /// Label of the item being edited.
  final String label;

  /// Visual customisation.
  final DialogSettings? settings;

  /// Called with `(true, newText)` on confirm or `(false, '')` on cancel.
  final void Function(bool, String) returnFunction;

  /// Source of the default texts; `null` uses [SearchDropDownStringsScope]
  /// (Portuguese without one).
  final SearchDropDownStrings? strings;

  @override
  State<EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<EditDialog> {
  late final TextEditingController controller;
  late final DialogSettings dialogSettings;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.label)
      ..selection = TextSelection(
        baseOffset: 0,
        extentOffset: widget.label.length,
      );
    dialogSettings = widget.settings ?? const DialogSettings();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _confirm() {
    if (controller.text.isNotEmpty) {
      widget.returnFunction(true, controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final SearchDropDownStrings texts =
        widget.strings ?? SearchDropDownStrings.of(context);
    final ThemeData theme = Theme.of(context);
    return PackageDialogLayout(
      settings: dialogSettings,
      title: DialogTitleText(texts.editTitle),
      content: TextField(
        controller: controller,
        autofocus: true,
        autocorrect: false,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _confirm(),
        style: theme.textTheme.bodyLarge,
        decoration: InputDecoration(
          labelText: dialogSettings.customEditHint ?? texts.editHint,
          // The app's own input border wins; otherwise an outlined field
          // with the buttons' corner radius.
          border: theme.inputDecorationTheme.border == null
              ? const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                )
              : null,
        ),
      ),
      actions: [
        (
          settings: dialogSettings.cancelButton(texts),
          onPressed: () => widget.returnFunction(false, ''),
        ),
        (settings: dialogSettings.editButton(texts), onPressed: _confirm),
      ],
    );
  }
}
