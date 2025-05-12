import 'package:flutter/material.dart';

/// A set of fixed colors for categories based on Microsoft Fluent UI color palette
class CategoryColors {
  // Primary category colors
  static const Color red = Color(0xFFA4262C);
  static const Color orange = Color(0xFFCA5010);
  static const Color gold = Color(0xFF8F7034);
  static const Color green = Color(0xFF407855);
  static const Color teal = Color(0xFF038387);
  static const Color blue = Color(0xFF0078D4);
  static const Color darkBlue = Color(0xFF40587C);
  static const Color indigo = Color(0xFF4052AB);
  static const Color plum = Color(0xFF854085);
  static const Color purple = Color(0xFF8764B8);
  static const Color coolGrey = Color(0xFF737373);
  static const Color warmGrey = Color(0xFF867365);

  // Get a color by name
  static Color getByName(String name) {
    switch (name.toLowerCase()) {
      case 'red':
        return red;
      case 'orange':
        return orange;
      case 'gold':
        return gold;
      case 'green':
        return green;
      case 'teal':
        return teal;
      case 'blue':
        return blue;
      case 'darkblue':
        return darkBlue;
      case 'indigo':
        return indigo;
      case 'plum':
        return plum;
      case 'purple':
        return purple;
      case 'coolgrey':
        return coolGrey;
      case 'warmgrey':
        return warmGrey;
      default:
        return coolGrey;
    }
  }

  // Get a color by index (for cycling through colors)
  static Color getByIndex(int index) {
    final colors = [
      red,
      orange,
      gold,
      green,
      teal,
      blue,
      darkBlue,
      indigo,
      plum,
      purple,
      coolGrey,
      warmGrey,
    ];
    return colors[index % colors.length];
  }

  // Convert Color to hex string (without using deprecated accessors)
  static String toHex(Color color) {
    return '${color.a.round().toRadixString(16).padLeft(2, '0')}'
        '${color.r.round().toRadixString(16).padLeft(2, '0')}'
        '${color.g.round().toRadixString(16).padLeft(2, '0')}'
        '${color.b.round().toRadixString(16).padLeft(2, '0')}';
  }

  // Parse hex string to color
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
