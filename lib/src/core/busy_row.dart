import 'package:flutter/widgets.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';
import 'package:simple_search_dropdown/src/core/package_dialog.dart';

/// The spinner state of a list row whose buttons run user callbacks.
mixin BusyRow<W extends StatefulWidget> on State<W> {
  /// Whether a callback is running; the row then shows [spinner].
  bool busy = false;

  /// Shows the spinner while [action] runs. An error it throws is reported
  /// and the row stays as it was.
  Future<void> runBusy(dynamic Function() action) async {
    setState(() => busy = true);
    try {
      await action();
    } catch (exception, stack) {
      reportCallbackError(exception, stack);
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  /// The spinner sized and coloured by [settings].
  Widget spinner(SimpleOverlaySettings settings, SearchDropDownStrings texts) =>
      SizedBox(
        height: settings.loadingSize,
        child: Loading(
          cor: settings.loadingColor,
          semanticsLabel: texts.loadingLabel,
        ),
      );
}
