import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // Primary swatch - Green for financial theme
  static const MaterialColor primarySwatch = MaterialColor(
    0xFF4CAF50,
    <int, Color>{
      50: Color(0xFFE8F5E9),
      100: Color(0xFFC8E6C9),
      200: Color(0xFFA5D6A7),
      300: Color(0xFF81C784),
      400: Color(0xFF66BB6A),
      500: Color(0xFF4CAF50), // Primary color
      600: Color(0xFF43A047),
      700: Color(0xFF388E3C),
      800: Color(0xFF2E7D32),
      900: Color(0xFF1B5E20),
    },
  );

  // Secondary color - Blue for contrast and call to actions
  static const MaterialColor secondarySwatch = MaterialColor(
    0xFF2196F3,
    <int, Color>{
      50: Color(0xFFE3F2FD),
      100: Color(0xFFBBDEFB),
      200: Color(0xFF90CAF9),
      300: Color(0xFF64B5F6),
      400: Color(0xFF42A5F5),
      500: Color(0xFF2196F3), // Secondary color
      600: Color(0xFF1E88E5),
      700: Color(0xFF1976D2),
      800: Color(0xFF1565C0),
      900: Color(0xFF0D47A1),
    },
  );

  // Accent color - Amber for highlighting important elements
  static const MaterialColor accentSwatch = MaterialColor(
    0xFFFFC107,
    <int, Color>{
      50: Color(0xFFFFF8E1),
      100: Color(0xFFFFECB3),
      200: Color(0xFFFFE082),
      300: Color(0xFFFFD54F),
      400: Color(0xFFFFCA28),
      500: Color(0xFFFFC107), // Accent color
      600: Color(0xFFFFB300),
      700: Color(0xFFFFA000),
      800: Color(0xFFFF8F00),
      900: Color(0xFFFF6F00),
    },
  );

  // Error color - Red for error states
  static const Color errorColor = Color(0xFFD32F2F);

  // Success color - Green for success states
  static const Color successColor = Color(0xFF388E3C);

  // Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primarySwatch: primarySwatch,
    colorScheme: ColorScheme.light(
      primary: primarySwatch.shade500,
      onPrimary: Colors.white,
      secondary: secondarySwatch.shade500,
      onSecondary: Colors.white,
      tertiary: accentSwatch.shade500,
      error: errorColor,
      surface: const Color(0xFFF5F5F5),
      onSurface: const Color(0xFF212121),
    ),
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF212121),
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primarySwatch.shade500,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primarySwatch.shade500,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primarySwatch.shade500,
        side: BorderSide(color: primarySwatch.shade500),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: primarySwatch.shade500, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: errorColor, width: 2),
      ),
      floatingLabelBehavior: FloatingLabelBehavior.never,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primarySwatch.shade500,
      unselectedItemColor: const Color(0xFF757575),
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
      showUnselectedLabels: true,
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE0E0E0),
      thickness: 1,
      space: 1,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Color(0xFF212121),
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Color(0xFF212121),
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Color(0xFF212121),
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Color(0xFF212121),
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: Color(0xFF212121),
      ),
      titleSmall: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Color(0xFF212121),
      ),
      bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF424242)),
      bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF424242)),
      bodySmall: TextStyle(fontSize: 12, color: Color(0xFF757575)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF333333),
      contentTextStyle: const TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primarySwatch: primarySwatch,
    colorScheme: ColorScheme.dark(
      primary: primarySwatch.shade400, // Slightly lighter green for dark mode
      onPrimary: Colors.black,
      secondary: secondarySwatch.shade400,
      onSecondary: Colors.black,
      tertiary: accentSwatch.shade400,
      error: Color(0xFFEF5350), // Lighter red for dark mode
      surface: const Color(0xFF121212),
      onSurface: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    ),
    cardTheme: CardTheme(
      color: const Color(0xFF2C2C2C),
      elevation: 2,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primarySwatch.shade400,
        foregroundColor: Colors.black,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primarySwatch.shade300,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primarySwatch.shade300,
        side: BorderSide(color: primarySwatch.shade300),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2C2C2C),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF3E3E3E)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: primarySwatch.shade300, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFEF5350), width: 2),
      ),
      floatingLabelBehavior: FloatingLabelBehavior.never,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: const Color(0xFF1E1E1E),
      selectedItemColor: primarySwatch.shade300,
      unselectedItemColor: const Color(0xFFB0B0B0),
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
      showUnselectedLabels: true,
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF3E3E3E),
      thickness: 1,
      space: 1,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      titleSmall: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: Color(0xFFEEEEEE)),
      bodyMedium: TextStyle(fontSize: 14, color: Color(0xFFEEEEEE)),
      bodySmall: TextStyle(fontSize: 12, color: Color(0xFFB0B0B0)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF333333),
      contentTextStyle: const TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}
