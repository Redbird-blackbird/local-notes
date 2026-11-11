import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Art-directed Notion design system for Local Notes.
/// Mimics the subtle warm paper tones, precision typography, and airy minimalism of Notion.
class AppTheme {
  // Light Palette
  static const Color lightBg = Color(0xFFFFFFFF);
  static const Color lightSidebarBg = Color(0xFFF7F6F3);
  static const Color lightSidebarHover = Color(0x0F37352F);
  static const Color lightSidebarActive = Color(0x1837352F);
  static const Color lightTextPrimary = Color(0xFF37352F);
  static const Color lightTextSecondary = Color(0xFF787774);
  static const Color lightTextTertiary = Color(0xFF9B9A97);
  static const Color lightBorder = Color(0xFFE9E9E8);
  static const Color lightDivider = Color(0xFFEEEEEC);
  static const Color lightCardBg = Color(0xFFFAF9F6);

  // Dark Palette
  static const Color darkBg = Color(0xFF191919);
  static const Color darkSidebarBg = Color(0xFF202020);
  static const Color darkSidebarHover = Color(0x14FFFFFF);
  static const Color darkSidebarActive = Color(0x22FFFFFF);
  static const Color darkTextPrimary = Color(0xFFE6E6E6);
  static const Color darkTextSecondary = Color(0xFF9B9A97);
  static const Color darkTextTertiary = Color(0xFF6A6A6A);
  static const Color darkBorder = Color(0xFF2E2E2E);
  static const Color darkDivider = Color(0xFF282828);
  static const Color darkCardBg = Color(0xFF252525);

  // Accent Colors
  static const Color accentBlue = Color(0xFF2383E2);
  static const Color accentGreen = Color(0xFF0F7B6C);
  static const Color accentOrange = Color(0xFFD9730D);
  static const Color accentRed = Color(0xFFEB5757);
  static const Color accentPurple = Color(0xFF6940A5);

  // Callout Colors (Light & Dark friendly)
  static const Map<String, CalloutColorStyle> calloutColors = {
    'gray': CalloutColorStyle(
      lightBg: Color(0xFFF1F1EF),
      lightBorder: Color(0xFFE2E2DF),
      darkBg: Color(0xFF2B2B2A),
      darkBorder: Color(0xFF3B3B39),
    ),
    'blue': CalloutColorStyle(
      lightBg: Color(0xFFEBF3F5),
      lightBorder: Color(0xFFD4E7EA),
      darkBg: Color(0xFF1F2C33),
      darkBorder: Color(0xFF2B3F4A),
    ),
    'green': CalloutColorStyle(
      lightBg: Color(0xFFEDF3EC),
      lightBorder: Color(0xFFD6E5D4),
      darkBg: Color(0xFF202E23),
      darkBorder: Color(0xFF2B4130),
    ),
    'yellow': CalloutColorStyle(
      lightBg: Color(0xFFFBF3DB),
      lightBorder: Color(0xFFF3E7C1),
      darkBg: Color(0xFF332D1C),
      darkBorder: Color(0xFF4A4228),
    ),
    'orange': CalloutColorStyle(
      lightBg: Color(0xFFFAECE7),
      lightBorder: Color(0xFFF3D8CF),
      darkBg: Color(0xFF33221C),
      darkBorder: Color(0xFF4A3128),
    ),
    'pink': CalloutColorStyle(
      lightBg: Color(0xFFFAF1F5),
      lightBorder: Color(0xFFF3DFE9),
      darkBg: Color(0xFF331E29),
      darkBorder: Color(0xFF4A2B3C),
    ),
    'purple': CalloutColorStyle(
      lightBg: Color(0xFFF3F0F8),
      lightBorder: Color(0xFFE4DCF0),
      darkBg: Color(0xFF2A2038),
      darkBorder: Color(0xFF3C2E4F),
    ),
  };

  static ThemeData lightTheme() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: lightBg,
      primaryColor: accentBlue,
      colorScheme: ColorScheme.light(
        primary: accentBlue,
        surface: lightBg,
        onSurface: lightTextPrimary,
        outline: lightBorder,
      ),
      dividerColor: lightDivider,
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: lightTextPrimary,
          letterSpacing: -0.6,
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
          letterSpacing: -0.4,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 19,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
          letterSpacing: -0.3,
        ),
        headlineSmall: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
          letterSpacing: -0.2,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: lightTextPrimary,
          height: 1.65,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: lightTextPrimary,
          height: 1.6,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: lightTextSecondary,
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(4),
        ),
        textStyle: GoogleFonts.inter(fontSize: 11, color: Colors.white),
        waitDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  static ThemeData darkTheme() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: darkBg,
      primaryColor: accentBlue,
      colorScheme: ColorScheme.dark(
        primary: accentBlue,
        surface: darkBg,
        onSurface: darkTextPrimary,
        outline: darkBorder,
      ),
      dividerColor: darkDivider,
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: darkTextPrimary,
          letterSpacing: -0.6,
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
          letterSpacing: -0.4,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 19,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
          letterSpacing: -0.3,
        ),
        headlineSmall: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
          letterSpacing: -0.2,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: darkTextPrimary,
          height: 1.65,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: darkTextPrimary,
          height: 1.6,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: darkTextSecondary,
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: const Color(0xFF333333),
          borderRadius: BorderRadius.circular(4),
        ),
        textStyle: GoogleFonts.inter(fontSize: 11, color: Colors.white),
        waitDuration: const Duration(milliseconds: 400),
      ),
    );
  }
}

class CalloutColorStyle {
  final Color lightBg;
  final Color lightBorder;
  final Color darkBg;
  final Color darkBorder;

  const CalloutColorStyle({
    required this.lightBg,
    required this.lightBorder,
    required this.darkBg,
    required this.darkBorder,
  });

  Color bg(bool isDark) => isDark ? darkBg : lightBg;
  Color border(bool isDark) => isDark ? darkBorder : lightBorder;
}
