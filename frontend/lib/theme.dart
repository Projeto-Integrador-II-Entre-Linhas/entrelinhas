import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MagicColors {
  static const Color abyss = Color(0xFF1B1034); // fundo profundo
  static const Color purpleDark = Color(0xFF2E0E5E);
  static const Color purple = Color(0xFF6A0DAD);
  static const Color lilac = Color(0xFFC8A2C8);
  static const Color aurora = Color(0xFF9F7AEA);
  static const Color gold = Color(0xFFFFD700);
  static const Color bg = Color(0xFF150C26);
  static const Color card = Color(0xFF23113F);
  static const Color mist = Color(0xFFB39DDB);
  static const Color runeGlow = Color(0xFFBB86FC);
}

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: false,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: MagicColors.bg,
    primaryColor: MagicColors.purple,
    cardColor: MagicColors.card,
    hintColor: MagicColors.lilac,
    shadowColor: MagicColors.aurora.withOpacity(0.4),
    iconTheme: const IconThemeData(color: Colors.white70),

    colorScheme: ColorScheme.dark(
      primary: MagicColors.purple,
      secondary: MagicColors.gold,
      surface: MagicColors.card,
      background: MagicColors.bg,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      error: Colors.redAccent,
    ),

    // 🧙‍♀️ Tipografia encantada
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme).apply(
      bodyColor: Colors.white.withOpacity(0.92),
      displayColor: Colors.white,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: MagicColors.purpleDark,
      foregroundColor: Colors.white,
      elevation: 6,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 20,
        letterSpacing: 0.5,
        color: Colors.white,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: MagicColors.gold,
        foregroundColor: Colors.black87,
        shadowColor: MagicColors.aurora,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        elevation: 8,
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: MagicColors.lilac,
        textStyle: const TextStyle(fontWeight: FontWeight.w500),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: MagicColors.abyss,
      contentPadding:
          const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: MagicColors.lilac.withOpacity(.4)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: MagicColors.lilac.withOpacity(.35)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: MagicColors.gold, width: 1.4),
      ),
      labelStyle: TextStyle(
        color: MagicColors.lilac.withOpacity(.85),
        fontWeight: FontWeight.w500,
      ),
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
    ),

    cardTheme: CardThemeData(
      color: MagicColors.card,
      shadowColor: MagicColors.aurora.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: MagicColors.card,
      contentTextStyle: const TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 6,
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: MagicColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: const TextStyle(
        fontWeight: FontWeight.w700,
        color: Colors.white,
        fontSize: 18,
      ),
      contentTextStyle: TextStyle(color: Colors.white.withOpacity(.9)),
    ),

    //Chips e tags
    chipTheme: ChipThemeData(
      backgroundColor: MagicColors.abyss,
      labelStyle: const TextStyle(color: Colors.white),
      selectedColor: MagicColors.purple,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      side: const BorderSide(color: MagicColors.lilac, width: 0.5),
    ),

    //Action Button (com brilho)
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: MagicColors.purple,
      foregroundColor: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
    ),

    // Transições
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    }),
  );
}
