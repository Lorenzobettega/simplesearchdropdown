import 'package:flutter/material.dart';

class Loading extends StatelessWidget {
  const Loading({super.key, required this.cor});
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: CircularProgressIndicator(color: cor),
    );
  }
}
