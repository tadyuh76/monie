import 'package:flutter/material.dart';

/// A class that defines all category color constants for consistent use throughout the app
class CategoryColors {
  // Color constants
  static const Color blue = Color(0xFF2196F3);
  static const Color green = Color(0xFF4CAF50);
  static const Color coolGrey = Color(0xFF607D8B);
  static const Color warmGrey = Color(0xFF867365);
  static const Color teal = Color(0xFF009688);
  static const Color darkBlue = Color(0xFF0D47A1);
  static const Color red = Color(0xFFE53935);
  static const Color gold = Color(0xFFFFD700);
  static const Color orange = Color(0xFFFF9800);
  static const Color plum = Color(0xFF9C27B0);
  static const Color purple = Color(0xFF673AB7);
  static const Color indigo = Color(0xFF3F51B5);

  // Helper method to convert a Color to its hex representation (for database storage)
  static String toHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  // Helper method to convert a hex string to a Color
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
