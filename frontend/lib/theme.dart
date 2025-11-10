import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BrandColors {
  static const Color eggplant = Color(0xFF4F3466);
  static const Color mauve = Color(0xFF947CAC);
  static const Color lilac = Color(0xFFA580A6);
  static const Color haze = Color(0xFFCABCD7);
  static const Color mist = Color(0xFFD2C9D4);

  static const Color bg = Color(0xFF2E2437);  
  static const Color surface = Color(0xFF3A2E49);
}

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: false,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: BrandColors.bg,
    primaryColor: BrandColors.eggplant,
    cardColor: BrandColors.surface,
    iconTheme: const IconThemeData(color: Colors.white70),

    colorScheme: const ColorScheme.dark(
      primary: BrandColors.eggplant,
      secondary: BrandColors.mist,
      surface: BrandColors.surface,
      background: BrandColors.bg,
      onPrimary: Colors.white,
      onSecondary: Colors.black87,
      error: Colors.redAccent,
    ),

    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme).apply(
      bodyColor: Colors.white.withOpacity(0.95),
      displayColor: Colors.white,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: BrandColors.eggplant,
      foregroundColor: Colors.white,
      elevation: 3,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 20,
        letterSpacing: .2,
        color: Colors.white,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: BrandColors.mist,
        foregroundColor: Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        elevation: 2,
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: BrandColors.haze,
        textStyle: const TextStyle(fontWeight: FontWeight.w500),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: BrandColors.surface,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: BrandColors.lilac.withOpacity(.5)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: BrandColors.lilac.withOpacity(.45)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: BrandColors.mist, width: 1.4),
      ),
      labelStyle: TextStyle(
        color: Colors.white.withOpacity(.85),
        fontWeight: FontWeight.w500,
      ),
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.65)),
    ),

    cardTheme: CardThemeData(
      color: BrandColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: BrandColors.surface,
      contentTextStyle: const TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: BrandColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      titleTextStyle: const TextStyle(
        fontWeight: FontWeight.w700,
        color: Colors.white,
        fontSize: 18,
      ),
      contentTextStyle: TextStyle(color: Colors.white.withOpacity(.95)),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: BrandColors.surface,
      labelStyle: const TextStyle(color: Colors.white),
      selectedColor: BrandColors.eggplant,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      side: BorderSide(color: BrandColors.lilac.withOpacity(.55), width: 0.5),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: BrandColors.eggplant,
      foregroundColor: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),

    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    }),
  );
}
