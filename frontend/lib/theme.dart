import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color purpleDark = Color(0xFF2E0854);
  static const Color purple = Color(0xFF6A0DAD);
  static const Color gold = Color(0xFFFFD700);
  static const Color lilac = Color(0xFFC8A2C8);
  static const Color bg = Color(0xFFF7F5FB);
}

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: false,
    primaryColor: AppColors.purple,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: ColorScheme.fromSwatch().copyWith(
      primary: AppColors.purple,
      secondary: AppColors.gold,
    ),
    textTheme: GoogleFonts.poppinsTextTheme().apply(
      bodyColor: Colors.black87,
      displayColor: Colors.black87,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.purpleDark,
      foregroundColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.gold,
      foregroundColor: Colors.black87,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    )),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}
