import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.accent,
        onSecondary: Colors.white,
        background: AppColors.background,
        onBackground: AppColors.textPrimary,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.background,
      
      // Typography
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: AppColors.navyTitle,
          fontSize: 42,
          fontWeight: FontWeight.w900,
          letterSpacing: -1.0,
          fontFamily: GoogleFonts.sourGummy().fontFamily
        ),
        headlineMedium: TextStyle(
          color: AppColors.navyTitle,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          fontFamily: GoogleFonts.sourGummy().fontFamily
        ),
        titleLarge: TextStyle(
          color: AppColors.subtitle,
          fontSize: 18,
          fontWeight: FontWeight.w500,
          fontFamily: GoogleFonts.sourGummy().fontFamily
        ),
        bodyLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: GoogleFonts.sourGummy().fontFamily
        ),
        bodyMedium: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontFamily: GoogleFonts.sourGummy().fontFamily
        ),
        labelLarge: TextStyle(
          color: AppColors.navyTitle,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: GoogleFonts.sourGummy().fontFamily
        ),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 64),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          shadowColor: AppColors.primary.withOpacity(0.5),
          textStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            fontFamily: GoogleFonts.sourGummy().fontFamily
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.secondaryButton,
          foregroundColor: AppColors.navyTitle,
          side: BorderSide.none,
          minimumSize: const Size(double.infinity, 64),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            fontFamily: GoogleFonts.sourGummy().fontFamily
          ),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blueGrey.shade50, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        hintStyle: TextStyle(color: AppColors.subtitle.withOpacity(0.5)),
        prefixIconColor: AppColors.subtitle,
        suffixIconColor: AppColors.subtitle,
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
          side: const BorderSide(color: AppColors.primaryLight, width: 3),
        ),
      ),
    );
  }
}
