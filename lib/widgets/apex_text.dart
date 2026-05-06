import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymsaas/core/theme.dart';

/// Universal text widget using DM Sans. Every text in the app should use this.
class ApexText extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color color;
  final FontWeight fontWeight;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final double? letterSpacing;

  const ApexText(
    this.text, {
    super.key,
    this.fontSize = 13,
    this.color = ApexColors.textSecondary,
    this.fontWeight = FontWeight.w400,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.letterSpacing,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: GoogleFonts.dmSans(
        fontSize: fontSize,
        color: color,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
      ),
    );
  }
}
