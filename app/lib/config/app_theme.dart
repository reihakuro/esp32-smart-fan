// lib/config/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Màu chủ đạo (dùng chung)
  static const Color primary = Color(0xFFEA580C);    // Cam đậm
  static const Color secondary = Color(0xFFFDBA74);  // Cam vừa
  static const Color success = Color(0xFF16A34A);    // Xanh lá
  static const Color error = Color(0xFFDC2626);      // Đỏ

  // 1. Cấu hình Light Theme (Cam - Be - Nâu)
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFFFF7ED), // Nền Be/Kem
    primaryColor: primary,
    cardColor: const Color(0xFFFFFFFF), // Card Trắng
    dividerColor: secondary.withOpacity(0.3),
    colorScheme: const ColorScheme.light(
      primary: primary,
      secondary: secondary,
      surface: Color(0xFFFFF7ED),
      onSurface: Color(0xFF431407), // Chữ Nâu đậm
    ),
    textTheme: GoogleFonts.nunitoTextTheme().apply(
      bodyColor: const Color(0xFF431407),
      displayColor: const Color(0xFF431407),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFFFFF7ED),
      foregroundColor: const Color(0xFF431407),
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.nunito(
        color: const Color(0xFF431407),
        fontSize: 24,
        fontWeight: FontWeight.w800,
      ),
      iconTheme: const IconThemeData(color: Color(0xFF431407)),
    ),
  );

  // 2. Cấu hình Dark Theme (Xám ấm - Cam)
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF1C1917), // Nền Xám đen ấm (Stone 900)
    primaryColor: primary,
    cardColor: const Color(0xFF292524), // Card Xám (Stone 800)
    dividerColor: Colors.grey.withOpacity(0.2),
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      surface: Color(0xFF1C1917),
      onSurface: Color(0xFFE7E5E4), // Chữ Trắng ngà (Stone 200)
    ),
    textTheme: GoogleFonts.nunitoTextTheme(ThemeData.dark().textTheme).apply(
      bodyColor: const Color(0xFFE7E5E4),
      displayColor: const Color(0xFFE7E5E4),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF1C1917),
      foregroundColor: const Color(0xFFE7E5E4),
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.nunito(
        color: const Color(0xFFE7E5E4),
        fontSize: 24,
        fontWeight: FontWeight.w800,
      ),
      iconTheme: const IconThemeData(color: Color(0xFFE7E5E4)),
    ),
  );
}