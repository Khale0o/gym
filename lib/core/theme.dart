import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ApexColors {
  const ApexColors._();

  static const Color background = Color(0xFF08090B);
  static const Color surface = Color(0xFF101216);
  static const Color surfaceAlt = Color(0xFF161A20);
  static const Color card = Color(0xFF12151A);
  static const Color border = Color(0xFF262B33);

  static const Color primary = Color(0xFFD6B75F);
  static const Color primaryLight = Color(0xFFE8CF83);
  static const Color primaryDark = Color(0xFF8B6B25);
  static const Color secondary = Color(0xFF7C8EA6);
  static const Color accent = Color(0xFFD6B75F);

  static const Color success = Color(0xFF53C68C);
  static const Color warning = Color(0xFFE29C52);
  static const Color error = Color(0xFFE35D66);
  static const Color info = Color(0xFF6E93F0);

  static const Color textPrimary = Color(0xFFF3F4F6);
  static const Color textSecondary = Color(0xFFB8C0CC);
  static const Color textMuted = Color(0xFF7A8492);
  static const Color textDisabled = Color(0xFF56606D);
}

class ApexSpacing {
  const ApexSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  static const EdgeInsets page = EdgeInsets.all(xl);
  static const EdgeInsets pageCompact = EdgeInsets.all(lg);
  static const EdgeInsets card = EdgeInsets.all(lg);
  static const EdgeInsets cardComfortable = EdgeInsets.all(xl);
  static const EdgeInsets formFieldGap = EdgeInsets.only(bottom: lg);
  static const EdgeInsets emptyState = EdgeInsets.symmetric(
    horizontal: xl,
    vertical: xxl,
  );
}

class ApexRadius {
  const ApexRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double pill = 999;

  static BorderRadius get card => BorderRadius.circular(lg);
  static BorderRadius get input => BorderRadius.circular(md);
  static BorderRadius get button => BorderRadius.circular(md);
  static BorderRadius get badge => BorderRadius.circular(pill);
}

class ApexShadows {
  const ApexShadows._();

  static List<BoxShadow> get card => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.26),
          blurRadius: 18,
          offset: const Offset(0, 10),
        ),
      ];

  static List<BoxShadow> get glow => [
        BoxShadow(
          color: ApexColors.primary.withValues(alpha: 0.14),
          blurRadius: 24,
          spreadRadius: 1,
        ),
      ];
}

class ApexTextStyles {
  const ApexTextStyles._();

  static TextStyle get display => GoogleFonts.cinzel(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: ApexColors.textPrimary,
        height: 1.15,
      );

  static TextStyle get pageTitle => GoogleFonts.cinzel(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: ApexColors.textPrimary,
        height: 1.2,
      );

  static TextStyle get sectionTitle => GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: ApexColors.textPrimary,
        height: 1.25,
      );

  static TextStyle get cardTitle => GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: ApexColors.textPrimary,
        height: 1.3,
      );

  static TextStyle get body => GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: ApexColors.textSecondary,
        height: 1.45,
      );

  static TextStyle get bodySmall => GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: ApexColors.textSecondary,
        height: 1.4,
      );

  static TextStyle get caption => GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: ApexColors.textMuted,
        height: 1.35,
      );

  static TextStyle get label => GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: ApexColors.textSecondary,
        height: 1.2,
      );

  static TextStyle get button => GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Colors.black,
        height: 1.2,
      );
}

class ApexDecorations {
  const ApexDecorations._();

  static BoxDecoration card({
    Color color = ApexColors.card,
    Color borderColor = ApexColors.border,
    double radius = ApexRadius.lg,
    bool glow = false,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor),
      boxShadow: glow ? ApexShadows.glow : ApexShadows.card,
    );
  }

  static BoxDecoration badge(Color color) {
    return BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: ApexRadius.badge,
      border: Border.all(color: color.withValues(alpha: 0.28)),
    );
  }

  static OutlineInputBorder inputBorder([
    Color color = ApexColors.border,
  ]) {
    return OutlineInputBorder(
      borderRadius: ApexRadius.input,
      borderSide: BorderSide(color: color),
    );
  }
}

class ApexIcons {
  const ApexIcons._();

  static const double xs = 14;
  static const double sm = 18;
  static const double md = 22;
  static const double lg = 28;
}

// Backwards-compatible aliases used across the existing app.
const Color gold = ApexColors.primary;
const Color goldLight = ApexColors.primaryLight;
const Color goldDark = ApexColors.primaryDark;

const Color bgDark = ApexColors.background;
const Color cardDark = ApexColors.card;
const Color card2Dark = ApexColors.surfaceAlt;
const Color borderDark = ApexColors.border;

const Color redAlert = ApexColors.error;
const Color greenSuccess = ApexColors.success;
const Color blueInfo = ApexColors.info;
const Color orangeWarning = ApexColors.warning;

const int gymCapacity = 60;

Color ocColor(double pct) {
  if (pct < 40) return ApexColors.success;
  if (pct < 70) return ApexColors.primary;
  if (pct < 90) return ApexColors.warning;
  return ApexColors.error;
}

String ocLabel(double pct) {
  if (pct < 40) return 'Quiet';
  if (pct < 70) return 'Moderate';
  if (pct < 90) return 'Busy';
  return 'Full';
}

final apexTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: ApexColors.background,
  primaryColor: ApexColors.primary,
  cardColor: ApexColors.card,
  dividerColor: ApexColors.border,
  colorScheme: const ColorScheme.dark(
    primary: ApexColors.primary,
    onPrimary: Colors.black,
    secondary: ApexColors.secondary,
    onSecondary: ApexColors.textPrimary,
    surface: ApexColors.surface,
    onSurface: ApexColors.textPrimary,
    error: ApexColors.error,
    onError: Colors.black,
  ),
  textTheme: GoogleFonts.dmSansTextTheme(
    ThemeData.dark().textTheme,
  ).copyWith(
    displaySmall: ApexTextStyles.display,
    headlineMedium: ApexTextStyles.pageTitle,
    headlineSmall: ApexTextStyles.sectionTitle,
    titleMedium: ApexTextStyles.cardTitle,
    bodyLarge: ApexTextStyles.body,
    bodyMedium: ApexTextStyles.bodySmall,
    bodySmall: ApexTextStyles.caption,
    labelLarge: ApexTextStyles.button,
    labelMedium: ApexTextStyles.label,
    labelSmall: ApexTextStyles.caption,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: ApexColors.surface,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    centerTitle: true,
    iconTheme: const IconThemeData(color: ApexColors.primary),
    titleTextStyle: ApexTextStyles.sectionTitle,
  ),
  cardTheme: CardThemeData(
    color: ApexColors.card,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: ApexRadius.card,
      side: const BorderSide(color: ApexColors.border),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: ApexColors.card,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: ApexSpacing.lg,
      vertical: ApexSpacing.md,
    ),
    labelStyle: ApexTextStyles.bodySmall.copyWith(color: ApexColors.textMuted),
    hintStyle: ApexTextStyles.bodySmall.copyWith(color: ApexColors.textMuted),
    errorStyle: ApexTextStyles.caption.copyWith(color: ApexColors.error),
    prefixIconColor: ApexColors.textMuted,
    suffixIconColor: ApexColors.textMuted,
    enabledBorder: ApexDecorations.inputBorder(),
    focusedBorder: ApexDecorations.inputBorder(ApexColors.primary),
    errorBorder: ApexDecorations.inputBorder(ApexColors.error),
    focusedErrorBorder: ApexDecorations.inputBorder(ApexColors.error),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: ApexColors.primary,
      foregroundColor: Colors.black,
      disabledBackgroundColor: ApexColors.border,
      disabledForegroundColor: ApexColors.textDisabled,
      elevation: 0,
      padding: const EdgeInsets.symmetric(
        horizontal: ApexSpacing.xl,
        vertical: ApexSpacing.md,
      ),
      textStyle: ApexTextStyles.button,
      shape: RoundedRectangleBorder(borderRadius: ApexRadius.button),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: ApexColors.primary,
      foregroundColor: Colors.black,
      disabledBackgroundColor: ApexColors.border,
      disabledForegroundColor: ApexColors.textDisabled,
      padding: const EdgeInsets.symmetric(
        horizontal: ApexSpacing.xl,
        vertical: ApexSpacing.md,
      ),
      textStyle: ApexTextStyles.button,
      shape: RoundedRectangleBorder(borderRadius: ApexRadius.button),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: ApexColors.primary,
      side: const BorderSide(color: ApexColors.border),
      padding: const EdgeInsets.symmetric(
        horizontal: ApexSpacing.xl,
        vertical: ApexSpacing.md,
      ),
      textStyle: ApexTextStyles.button.copyWith(color: ApexColors.primary),
      shape: RoundedRectangleBorder(borderRadius: ApexRadius.button),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: ApexColors.primary,
      textStyle: ApexTextStyles.button.copyWith(color: ApexColors.primary),
      shape: RoundedRectangleBorder(borderRadius: ApexRadius.button),
    ),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: ApexColors.surfaceAlt,
    selectedColor: ApexColors.primary.withValues(alpha: 0.18),
    disabledColor: ApexColors.border,
    side: const BorderSide(color: ApexColors.border),
    shape: RoundedRectangleBorder(borderRadius: ApexRadius.badge),
    labelStyle: ApexTextStyles.caption.copyWith(color: ApexColors.textSecondary),
    secondaryLabelStyle: ApexTextStyles.caption.copyWith(
      color: ApexColors.primary,
      fontWeight: FontWeight.w700,
    ),
    checkmarkColor: ApexColors.primary,
  ),
  dividerTheme: const DividerThemeData(
    color: ApexColors.border,
    thickness: 1,
    space: 1,
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: ApexColors.surfaceAlt,
    contentTextStyle: ApexTextStyles.bodySmall.copyWith(
      color: ApexColors.textPrimary,
    ),
    behavior: SnackBarBehavior.floating,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(ApexRadius.md),
      side: const BorderSide(color: ApexColors.border),
    ),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: ApexColors.surface,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: ApexRadius.card),
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: ApexColors.surface,
    surfaceTintColor: Colors.transparent,
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: ApexColors.primary,
    linearTrackColor: ApexColors.border,
    circularTrackColor: ApexColors.border,
  ),
  tabBarTheme: TabBarThemeData(
    indicatorColor: ApexColors.primary,
    labelColor: ApexColors.primary,
    unselectedLabelColor: ApexColors.textMuted,
    labelStyle: ApexTextStyles.label,
    unselectedLabelStyle: ApexTextStyles.label,
  ),
);
