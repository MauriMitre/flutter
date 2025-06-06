import 'package:flutter/material.dart';

const Color _customColor = Color(0xFF6200EE);

const List<Color> _colorThemes = [
  _customColor,
  Color(0xFF03DAC6),
  Color(0xFFFFC107),
  Color(0xFFB00020),
  Color(0xFF03A9F4),
  Color(0xFF8BC34A),
  Color(0xFFFF5722),
  Color(0xFF9C27B0),
  Color(0xFF795548),
  Color(0xFF607D8B),
];

class AppTheme {
  final int selectedColor;

  AppTheme({this.selectedColor = 0})
    : assert(
        selectedColor >= 0 && selectedColor < _colorThemes.length,
        'selectedColor must be between 0 and ${_colorThemes.length - 1}',
      );

  ThemeData theme() {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: _colorThemes[selectedColor],
    );
  }
}
