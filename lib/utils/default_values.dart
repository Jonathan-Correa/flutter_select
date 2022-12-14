import 'package:flutter/material.dart';

class EmptyOptions extends StatelessWidget {
  const EmptyOptions({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('No data to display!'),
    );
  }
}
