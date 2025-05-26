import 'package:flutter/material.dart';

void showSnackBar(BuildContext context, String message, {bool error = false}) {
  final snackBar = SnackBar(
    content: Text(message),
    backgroundColor:
        error
            ? Colors.red
            : Theme.of(context).snackBarTheme.backgroundColor ??
                Theme.of(context).colorScheme.primary,
    behavior: SnackBarBehavior.floating,
    duration: const Duration(seconds: 3),
  );
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
