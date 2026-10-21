import 'package:flutter/material.dart';

/// A square progress indicator used while async callbacks run.
class Loading extends StatelessWidget {
  /// Creates the indicator with color [cor].
  const Loading({
    super.key,
    required this.cor,
    this.semanticsLabel,
    this.strokeWidth,
  });

  /// Indicator color.
  final Color cor;

  /// Label announced by screen readers.
  final String? semanticsLabel;

  /// Ring stroke width, or `null` for [CircularProgressIndicator]'s own.
  final double? strokeWidth;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: CircularProgressIndicator(
        color: cor,
        semanticsLabel: semanticsLabel,
        strokeWidth: strokeWidth,
      ),
    );
  }
}
