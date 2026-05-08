import 'package:flutter/material.dart';

@immutable
class CakeThemePalette extends ThemeExtension<CakeThemePalette> {
  const CakeThemePalette({
    required this.pageBackground,
    required this.surface,
    required this.softSurface,
    required this.border,
    required this.mutedText,
    required this.heroGradient,
    required this.heroShadow,
    required this.success,
    required this.warning,
    required this.danger,
  });

  final Color pageBackground;
  final Color surface;
  final Color softSurface;
  final Color border;
  final Color mutedText;
  final LinearGradient heroGradient;
  final Color heroShadow;
  final Color success;
  final Color warning;
  final Color danger;

  @override
  CakeThemePalette copyWith({
    Color? pageBackground,
    Color? surface,
    Color? softSurface,
    Color? border,
    Color? mutedText,
    LinearGradient? heroGradient,
    Color? heroShadow,
    Color? success,
    Color? warning,
    Color? danger,
  }) {
    return CakeThemePalette(
      pageBackground: pageBackground ?? this.pageBackground,
      surface: surface ?? this.surface,
      softSurface: softSurface ?? this.softSurface,
      border: border ?? this.border,
      mutedText: mutedText ?? this.mutedText,
      heroGradient: heroGradient ?? this.heroGradient,
      heroShadow: heroShadow ?? this.heroShadow,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
    );
  }

  @override
  ThemeExtension<CakeThemePalette> lerp(
    covariant ThemeExtension<CakeThemePalette>? other,
    double t,
  ) {
    if (other is! CakeThemePalette) return this;

    return CakeThemePalette(
      pageBackground: Color.lerp(pageBackground, other.pageBackground, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      softSurface: Color.lerp(softSurface, other.softSurface, t)!,
      border: Color.lerp(border, other.border, t)!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
      heroGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(heroGradient.colors.first, other.heroGradient.colors.first, t)!,
          Color.lerp(heroGradient.colors.last, other.heroGradient.colors.last, t)!,
        ],
      ),
      heroShadow: Color.lerp(heroShadow, other.heroShadow, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}

class AppTheme {
  const AppTheme._();

  static const Color brandPink = Color(0xFFE754A8);
  static const Color brandPurple = Color(0xFF845EF7);

  static ThemeData light() {
    const palette = CakeThemePalette(
      pageBackground: Color(0xFFF7F3F8),
      surface: Colors.white,
      softSurface: Color(0xFFFFF2FA),
      border: Color(0xFFE8DDE9),
      mutedText: Color(0xFF6F6979),
      heroGradient: LinearGradient(
        colors: [brandPink, brandPurple],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      heroShadow: Color(0x1FB043A6),
      success: Color(0xFF39B980),
      warning: Color(0xFFFFA63D),
      danger: Color(0xFFE06A74),
    );

    return _buildTheme(Brightness.light, palette);
  }

  static ThemeData dark() {
    const palette = CakeThemePalette(
      pageBackground: Color(0xFF131118),
      surface: Color(0xFF201A29),
      softSurface: Color(0xFF2C2436),
      border: Color(0xFF433751),
      mutedText: Color(0xFFBCB4CB),
      heroGradient: LinearGradient(
        colors: [Color(0xFFFF69B9), Color(0xFF8D75FF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      heroShadow: Color(0x66000000),
      success: Color(0xFF67D9A5),
      warning: Color(0xFFFFBE73),
      danger: Color(0xFFFF8B94),
    );

    return _buildTheme(Brightness.dark, palette);
  }

  static ThemeData _buildTheme(
    Brightness brightness,
    CakeThemePalette palette,
  ) {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: brandPink,
      brightness: brightness,
    );

    final scheme = baseScheme.copyWith(
      primary: brandPink,
      secondary: brandPurple,
      tertiary: const Color(0xFFFFA86C),
      surface: palette.surface,
      error: palette.danger,
    );

    final textTheme = ThemeData(brightness: brightness).textTheme.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );

    OutlineInputBorder inputBorder(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: palette.pageBackground,
      canvasColor: palette.pageBackground,
      cardColor: palette.surface,
      dividerColor: palette.border,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: palette.pageBackground,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: palette.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: palette.surface,
        selectedItemColor: scheme.primary,
        unselectedItemColor: palette.mutedText,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
        type: BottomNavigationBarType.fixed,
        elevation: 10,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: palette.border),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.softSurface,
        hintStyle: TextStyle(color: palette.mutedText),
        prefixIconColor: palette.mutedText,
        suffixIconColor: palette.mutedText,
        border: inputBorder(palette.border),
        enabledBorder: inputBorder(palette.border),
        focusedBorder: inputBorder(scheme.primary, 1.4),
        disabledBorder: inputBorder(palette.border),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.surface,
        contentTextStyle: TextStyle(color: scheme.onSurface),
        actionTextColor: scheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary;
          }
          return Colors.transparent;
        }),
        side: BorderSide(color: palette.border),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary;
          }
          return palette.mutedText;
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary;
          }
          return palette.surface;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary.withValues(alpha: 0.42);
          }
          return palette.border;
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: palette.surface,
        selectedColor: scheme.primary,
        secondarySelectedColor: scheme.primary,
        side: BorderSide(color: palette.border),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        labelStyle: TextStyle(color: scheme.onSurface),
        secondaryLabelStyle: TextStyle(color: scheme.onPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      extensions: [palette],
    );
  }
}

extension CakeThemeContext on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => theme.colorScheme;
  CakeThemePalette get cakeTheme => theme.extension<CakeThemePalette>()!;
}
