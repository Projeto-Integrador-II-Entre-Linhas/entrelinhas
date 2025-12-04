import 'package:flutter/material.dart';

class BrandColors {
  static const Color background = Color(0xFFDCCEE6);
  static const Color card = Color(0xFFEDE3F4);

  static const Color primaryButton = Color(0xFF6E4A8E);
  static const Color secondaryButton = Color(0xFF8A68B1);

  static const Color titleText = Color(0xFF4F2A75);
  static const Color icons = Color(0xFF6E4A8E);

  // Sombras com alpha 0.08
  static const Color shadow = Color(0x14000000);
}

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: false,
    brightness: Brightness.light,

    // Fundo principal
    scaffoldBackgroundColor: BrandColors.background,

    primaryColor: BrandColors.primaryButton,
    cardColor: BrandColors.card,

    iconTheme: const IconThemeData(
      color: BrandColors.icons,
    ),

    colorScheme: const ColorScheme.light(
      primary: BrandColors.primaryButton,
      secondary: BrandColors.secondaryButton,
      surface: BrandColors.card,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      error: Colors.redAccent,
    ),

    textTheme: ThemeData.light().textTheme.apply(
      fontFamily: 'Poppins',
      bodyColor: BrandColors.titleText,
      displayColor: const Color.fromARGB(255, 245, 243, 247),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: BrandColors.background,
      foregroundColor: BrandColors.titleText,
      elevation: 2,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w700,
        fontSize: 20,
        color: Color(0xFFFFFFFF),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: BrandColors.primaryButton,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        elevation: 3,
        shadowColor: BrandColors.shadow,
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: BrandColors.secondaryButton,
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: BrandColors.card,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: BrandColors.primaryButton.withValues(alpha: .4),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: BrandColors.primaryButton.withValues(alpha: .35),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: BrandColors.primaryButton,
          width: 1.4,
        ),
      ),

      labelStyle: TextStyle(
        fontFamily: 'Poppins',
        color: BrandColors.titleText.withValues(alpha: .85),
        fontWeight: FontWeight.w500,
      ),
      hintStyle: TextStyle(
        fontFamily: 'Poppins',
        color: BrandColors.titleText.withValues(alpha: .55),
      ),
    ),

    cardTheme: CardThemeData(
      color: BrandColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 3,
      shadowColor: BrandColors.shadow,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: BrandColors.primaryButton,
      contentTextStyle: const TextStyle(
        fontFamily: 'Poppins',
        color: Colors.white,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: BrandColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      titleTextStyle: const TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w700,
        color: BrandColors.titleText,
        fontSize: 18,
      ),
      contentTextStyle: TextStyle(
        fontFamily: 'Poppins',
        color: BrandColors.titleText.withValues(alpha: .95),
      ),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: BrandColors.card,
      labelStyle: const TextStyle(
        fontFamily: 'Poppins',
        color: BrandColors.titleText,
      ),
      selectedColor: BrandColors.primaryButton,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      side: BorderSide(
        color: BrandColors.primaryButton.withValues(alpha: .45),
        width: 0.6,
      ),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: BrandColors.primaryButton,
      foregroundColor: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),

    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
