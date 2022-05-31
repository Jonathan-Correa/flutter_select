import 'package:flutter/material.dart';

class EmptyOptions extends StatelessWidget {
  const EmptyOptions({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('No hay datos para mostrar'),
    );
  }
}

InputDecoration buildInputBasicDecoration(BuildContext context) {
  final theme = Theme.of(context);

  return InputDecoration(
    fillColor: Theme.of(context).scaffoldBackgroundColor,
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: theme.primaryColor),
      borderRadius: BorderRadius.circular(42.0),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(
        color: theme.colorScheme.primary,
        width: 2,
      ),
      borderRadius: BorderRadius.circular(42.0),
    ),
    errorBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.red, width: 2),
      borderRadius: BorderRadius.circular(42.0),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.red, width: 2),
      borderRadius: BorderRadius.circular(42.0),
    ),
    border: InputBorder.none,
  );
}
