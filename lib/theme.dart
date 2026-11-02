import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Colours from the Figma prototype.
const Color background = Color(0xFFF5F6FA);
const Color cardBorder = Color(0xFFE4E6EF);
const Color primary = Color(0xFF3446E0);
const Color primarySoft = Color(0xFFE9ECFD);
const Color recordingRed = Color(0xFFE5484D);
const Color success = Color(0xFF1F9D63);
const Color textGrey = Color(0xFF6B7080);

// Course tiles take turns using these (background, letters).
const List<Color> tileBackgrounds = [
  Color(0xFFE9ECFD),
  Color(0xFFE3F5EC),
  Color(0xFFFDF1D8),
  Color(0xFFFDE7E8),
];
const List<Color> tileLetters = [
  Color(0xFF3446E0),
  Color(0xFF1F9D63),
  Color(0xFFA06A00),
  Color(0xFFE5484D),
];

ThemeData appTheme() {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      error: recordingRed,
    ),
    scaffoldBackgroundColor: background,
    textTheme: GoogleFonts.interTextTheme(),
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: cardBorder),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: cardBorder),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        side: const BorderSide(color: cardBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
  );
}
