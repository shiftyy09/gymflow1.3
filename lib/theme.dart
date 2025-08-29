import 'package:flutter/material.dart';

const Color primaryPurple = Color(0xFF6C5CE7);
const Color gradientStart = Color(0xFF74B9FF);
const Color gradientEnd = Color(0xFDA854FF);
const Color accentPink = Color(0xFFFF6B9D);
const Color lightPurple = Color(0xFFA29BFE);
const Color darkGray = Color(0xFF2D3748);
const Color cardBackground = Color(0xFFFFFFFF);
const Color lightGray = Color(0xFFF8F9FA);

ThemeData appTheme() {
  return ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryPurple,
    scaffoldBackgroundColor: lightGray,
    colorScheme: const ColorScheme.light(
      primary: primaryPurple,
      secondary: accentPink,
    ),
    cardTheme: const CardThemeData(
  color: cardBackground,
  elevation: 8,
  shadowColor: Colors.black12,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: darkGray,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: darkGray),
    ),
  );
}
