import 'package:flutter/material.dart';

class ThemeController with ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeData get themeData {
    return _isDarkMode ? _darkTheme : _lightTheme;
  }

  static final _lightTheme = ThemeData(
    primaryColor: const Color(0xFFF97316),
    scaffoldBackgroundColor: const Color(0xFFFFFFFF),
    brightness: Brightness.light,
    textTheme: const TextTheme(
      headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
      bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
      bodySmall: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
    ),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFFF97316),
      surface: Color(0xFFF3F4F6),
      secondary: Colors.green, // Added secondary color for loader
    ),
    fontFamily: 'Roboto',
  );

  static final _darkTheme = ThemeData(
    primaryColor: const Color(0xFFF97316),
    scaffoldBackgroundColor: const Color(0xFF121212),
    brightness: Brightness.dark,
    textTheme: const TextTheme(
      headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFE5E7EB)),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFE5E7EB)),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFFE5E7EB)),
      bodyMedium: TextStyle(fontSize: 14, color: Color(0xFFE5E7EB)),
      bodySmall: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
    ),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFF97316),
      surface: Color(0xFF1E1E1E),
      secondary: Colors.green, // Added secondary color for loader
    ),
    fontFamily: 'Roboto',
  );

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}