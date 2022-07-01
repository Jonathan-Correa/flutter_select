import 'package:flutter/material.dart';

enum FSelectLabelAlignment { left, center, right }

class FSelectLabel {
  final Icon? icon;
  final String text;
  TextStyle? textStyle = const TextStyle();
  FSelectLabelAlignment? alignment = FSelectLabelAlignment.left;

  FSelectLabel({
    required this.text,
    this.textStyle,
    this.alignment,
    this.icon,
  });
}
