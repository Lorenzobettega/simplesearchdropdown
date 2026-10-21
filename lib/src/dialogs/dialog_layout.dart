import 'package:flutter/material.dart';
import 'package:simple_search_dropdown/src/helpers/dialog_button.dart';
import 'package:simple_search_dropdown/src/helpers/dialog_settings.dart';

/// Horizontal gap between two dialog buttons.
const double dialogButtonGap = 12;

/// One button of a package dialog.
typedef DialogAction = ({
  DialogButtonSettings settings,
  VoidCallback onPressed,
});

/// The layout the edit, delete and invalid-item dialogs share: an
/// [AlertDialog] (Material 3 paddings: 24 around, 16 title to content, 24
/// content to actions) with a centred title, the content, and one row of
/// buttons. Every [DialogSettings] layout field is forwarded to it.
class PackageDialogLayout extends StatelessWidget {
  /// Lays out [title], [content] and [actions] as [settings] says;
  /// `settings.title` / `settings.content` replace [title] / [content].
  const PackageDialogLayout({
    super.key,
    required this.settings,
    required this.title,
    required this.actions,
    this.content,
  });

  /// Layout and replacement title/content.
  final DialogSettings settings;

  /// The default title.
  final Widget title;

  /// The default content.
  final Widget? content;

  /// The buttons, left to right.
  final List<DialogAction> actions;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: settings.title ?? title,
    content: settings.content ?? content,
    contentPadding: settings.contentPadding,
    titlePadding: settings.titlePadding,
    actionsPadding: settings.actionsPadding,
    actionsAlignment: settings.actionsAlignment,
    backgroundColor: settings.backgroundColor,
    elevation: settings.elevation,
    shape: settings.shape,
    insetPadding: settings.insetPadding,
    actions: [
      DialogActionsRow(
        actions: actions,
        alignment: settings.actionsAlignment ?? MainAxisAlignment.end,
      ),
    ],
  );
}

/// The dialog buttons on one row: a button without `customWidth` shares the
/// free width equally with the others, so labels never wrap to a second row.
class DialogActionsRow extends StatelessWidget {
  /// Creates the row of [actions].
  const DialogActionsRow({
    super.key,
    required this.actions,
    this.alignment = MainAxisAlignment.end,
  });

  /// The buttons, left to right.
  final List<DialogAction> actions;

  /// Where buttons with a fixed `customWidth` sit.
  final MainAxisAlignment alignment;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: alignment,
    children: [
      for (int i = 0; i < actions.length; i++) ...[
        if (i > 0) const SizedBox(width: dialogButtonGap),
        _slot(actions[i]),
      ],
    ],
  );

  Widget _slot(DialogAction action) {
    final Widget button = DialogButton(
      function: action.onPressed,
      buttonSettings: action.settings,
    );
    return action.settings.customWidth == null
        ? Expanded(child: button)
        : button;
  }
}

/// A dialog title: the theme's titleLarge at 20, semibold, centred.
class DialogTitleText extends StatelessWidget {
  /// Creates the title [text].
  const DialogTitleText(this.text, {super.key});

  /// The title.
  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Text(
      text,
      style: (theme.textTheme.titleLarge ?? const TextStyle()).copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
      ),
      textAlign: TextAlign.center,
    );
  }
}

/// Supporting text of a dialog: bodyMedium in onSurfaceVariant, centred.
class DialogSupportingText extends StatelessWidget {
  /// Creates the supporting [text].
  const DialogSupportingText(this.text, {super.key}) : item = null;

  /// [template] with its first `{item}` replaced by [item] in bold
  /// (onSurface).
  const DialogSupportingText.withItem(
    String template,
    String this.item, {
    super.key,
  }) : text = template;

  /// The text, or the template when [item] is set.
  final String text;

  /// The item label put in place of `{item}`.
  final String? item;

  static const String _placeholder = '{item}';

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle style = (theme.textTheme.bodyMedium ?? const TextStyle())
        .copyWith(color: theme.colorScheme.onSurfaceVariant);
    final String? label = item;
    final int at = text.indexOf(_placeholder);
    if (label == null || at < 0) {
      return Text(text, style: style, textAlign: TextAlign.center);
    }
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: text.substring(0, at)),
          TextSpan(
            text: label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          TextSpan(text: text.substring(at + _placeholder.length)),
        ],
      ),
      style: style,
      textAlign: TextAlign.center,
    );
  }
}
