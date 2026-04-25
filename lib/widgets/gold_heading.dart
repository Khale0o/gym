import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Cinzel heading widget for titles across the app.
class GoldHeading extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color color;

  const GoldHeading(
    this.text, {
    super.key,
    this.fontSize = 14,
    this.color = const Color(0xFFE8E8E8),
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.cinzel(
        fontSize: fontSize,
        color: color,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}