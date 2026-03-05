import 'dart:ui';
import 'package:flutter/material.dart';

/// ──────────────────────────────────────────────────────────────────────────
/// App-wide colour palette
/// ──────────────────────────────────────────────────────────────────────────
class AppColors {
  AppColors._();

  // Background gradient
  static const Color bgStart = Color(0xFF0D1B2A);
  static const Color bgMid = Color(0xFF1B2838);
  static const Color bgEnd = Color(0xFF162447);

  // Accent
  static const Color accent = Color(0xFF00E5FF);
  static const Color accentSoft = Color(0xFF00BCD4);
  static const Color accentPurple = Color(0xFF7C4DFF);
  static const Color accentPink = Color(0xFFFF4081);

  // Success / Error
  static const Color success = Color(0xFF00E676);
  static const Color error = Color(0xFFFF5252);
  static const Color warning = Color(0xFFFFAB40);

  // Surface
  static const Color cardBg = Color(0x22FFFFFF);
  static const Color cardBorder = Color(0x33FFFFFF);

  // Text
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xAAFFFFFF);
  static const Color textMuted = Color(0x66FFFFFF);
}

/// ──────────────────────────────────────────────────────────────────────────
/// Gradient presets
/// ──────────────────────────────────────────────────────────────────────────
class AppGradients {
  AppGradients._();

  static const LinearGradient background = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.bgStart, AppColors.bgMid, AppColors.bgEnd],
  );

  static const LinearGradient accentButton = LinearGradient(
    colors: [AppColors.accent, AppColors.accentPurple],
  );

  static const LinearGradient warmButton = LinearGradient(
    colors: [Color(0xFFFF6F00), Color(0xFFFF4081)],
  );

  static LinearGradient levelGradient(int level) {
    const palettes = [
      [Color(0xFF00E676), Color(0xFF00BFA5)],
      [Color(0xFF448AFF), Color(0xFF2962FF)],
      [Color(0xFFFFAB40), Color(0xFFFF6D00)],
      [Color(0xFF7C4DFF), Color(0xFF651FFF)],
      [Color(0xFF00E5FF), Color(0xFF00B8D4)],
    ];
    final i = (level - 1).clamp(0, palettes.length - 1);
    return LinearGradient(colors: palettes[i]);
  }
}

/// ──────────────────────────────────────────────────────────────────────────
/// Glassmorphism decoration
/// ──────────────────────────────────────────────────────────────────────────
class GlassDecoration {
  GlassDecoration._();

  static BoxDecoration card({
    double borderRadius = 20,
    Color? color,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: color ?? AppColors.cardBg,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: borderColor ?? AppColors.cardBorder, width: 1),
    );
  }
}

/// Wrap a child with a blur + glass effect.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double blur;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.padding,
    this.margin,
    this.blur = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(20),
            decoration: GlassDecoration.card(borderRadius: borderRadius),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// ──────────────────────────────────────────────────────────────────────────
/// ThemeData builder
/// ──────────────────────────────────────────────────────────────────────────
ThemeData buildAppTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bgStart,
    useMaterial3: true,
    colorSchemeSeed: AppColors.accent,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      foregroundColor: AppColors.textPrimary,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
