import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// الألوان الأساسية
const Color gold = Color(0xFFC9A84C);
const Color goldLight = Color(0xFFE8C97A);
const Color goldDark = Color(0xFF7A5C1E);

const Color bgDark = Color(0xFF070707);
const Color cardDark = Color(0xFF0E0E0E);
const Color card2Dark = Color(0xFF131313);
const Color borderDark = Color(0xFF1E1E1E);

const Color redAlert = Color(0xFFE05252);
const Color greenSuccess = Color(0xFF3DBA7E);
const Color blueInfo = Color(0xFF4C7CE0);
const Color orangeWarning = Color(0xFFE07A4C);

// السعة القصوى للجيم
const int gymCapacity = 60;

// دوال مساعدة للألوان والنصوص
Color ocColor(double pct) {
  if (pct < 40) return greenSuccess;
  if (pct < 70) return gold;
  if (pct < 90) return orangeWarning;
  return redAlert;
}

String ocLabel(double pct) {
  if (pct < 40) return 'Quiet';
  if (pct < 70) return 'Moderate';
  if (pct < 90) return 'Busy';
  return 'Full';
}

// ثيم التطبيق الكامل
final apexTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: bgDark,
  primaryColor: gold,
  cardColor: cardDark,
  dividerColor: borderDark,
  textTheme: GoogleFonts.dmSansTextTheme(
    ThemeData.dark().textTheme,
  ).copyWith(
    headlineMedium: GoogleFonts.cinzel(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: const Color(0xFFE8E8E8),
    ),
    headlineSmall: GoogleFonts.cinzel(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: const Color(0xFFE8E8E8),
    ),
    bodyLarge: const TextStyle(
      fontSize: 13,
      color: Color(0xFF888888),
      fontWeight: FontWeight.w400,
    ),
    bodyMedium: const TextStyle(
      fontSize: 12,
      color: Color(0xFF555555),
    ),
    labelSmall: const TextStyle(
      fontSize: 9,
      color: Color(0xFF3A3A3A),
      letterSpacing: 1.2,
    ),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF0A0A0A),
    elevation: 0,
    centerTitle: true,
    iconTheme: IconThemeData(color: gold),
  ),
);