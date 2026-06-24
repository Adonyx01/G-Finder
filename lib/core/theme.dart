import 'package:flutter/material.dart';

@immutable
class ChezMoiColors extends ThemeExtension<ChezMoiColors> {
  const ChezMoiColors({
    required this.navy,
    required this.primaryBlue,
    required this.lightBlueAccent,
    required this.background,
    required this.surface,
    required this.elevatedSurface,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.accent,
    required this.danger,
  });

  final Color navy;
  final Color primaryBlue;
  final Color lightBlueAccent;
  final Color background;
  final Color surface;
  final Color elevatedSurface;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color accent;
  final Color danger;

  static const light = ChezMoiColors(
    navy: Color(0xFF0B2447),
    primaryBlue: Color(0xFF1677E8),
    lightBlueAccent: Color(0xFFE7F2FF),
    background: Color(0xFFF3F6FA),
    surface: Color(0xFFFFFFFF),
    elevatedSurface: Color(0xFFF7FBFF),
    textPrimary: Color(0xFF111827),
    textSecondary: Color(0xFF6B7280),
    border: Color(0xFFD8E0EA),
    accent: Color(0xFF1677E8),
    danger: Color(0xFFEF4444),
  );

  static const dark = ChezMoiColors(
    navy: Color(0xFF0B2447),
    primaryBlue: Color(0xFF1677E8),
    lightBlueAccent: Color(0xFFE7F2FF),
    background: Color(0xFFF3F6FA),
    surface: Color(0xFFFFFFFF),
    elevatedSurface: Color(0xFFF7FBFF),
    textPrimary: Color(0xFF111827),
    textSecondary: Color(0xFF6B7280),
    border: Color(0xFFD8E0EA),
    accent: Color(0xFF1677E8),
    danger: Color(0xFFEF4444),
  );

  @override
  ChezMoiColors copyWith({
    Color? navy,
    Color? primaryBlue,
    Color? lightBlueAccent,
    Color? background,
    Color? surface,
    Color? elevatedSurface,
    Color? textPrimary,
    Color? textSecondary,
    Color? border,
    Color? accent,
    Color? danger,
  }) {
    return ChezMoiColors(
      navy: navy ?? this.navy,
      primaryBlue: primaryBlue ?? this.primaryBlue,
      lightBlueAccent: lightBlueAccent ?? this.lightBlueAccent,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      elevatedSurface: elevatedSurface ?? this.elevatedSurface,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      border: border ?? this.border,
      accent: accent ?? this.accent,
      danger: danger ?? this.danger,
    );
  }

  @override
  ChezMoiColors lerp(ThemeExtension<ChezMoiColors>? other, double t) {
    if (other is! ChezMoiColors) return this;
    return ChezMoiColors(
      navy: Color.lerp(navy, other.navy, t)!,
      primaryBlue: Color.lerp(primaryBlue, other.primaryBlue, t)!,
      lightBlueAccent: Color.lerp(lightBlueAccent, other.lightBlueAccent, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      elevatedSurface: Color.lerp(elevatedSurface, other.elevatedSurface, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      border: Color.lerp(border, other.border, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}

extension ChezMoiColorsContext on BuildContext {
  ChezMoiColors get chezMoiColors =>
      Theme.of(this).extension<ChezMoiColors>() ?? ChezMoiColors.light;
}

ThemeData _buildTheme({
  required ChezMoiColors colors,
  required Brightness brightness,
}) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: colors.primaryBlue,
    brightness: brightness,
    surface: colors.surface,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colors.background,
    extensions: [colors],
    appBarTheme: AppBarTheme(
      backgroundColor: colors.background,
      foregroundColor: colors.textPrimary,
      elevation: 0,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: colors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: colors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: colors.primaryBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: colors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: colors.danger, width: 1.5),
      ),
      labelStyle: TextStyle(color: colors.textSecondary),
      hintStyle: TextStyle(color: colors.textSecondary.withValues(alpha: 0.7)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colors.primaryBlue,
        foregroundColor: Colors.white,
        disabledBackgroundColor: colors.border,
        disabledForegroundColor: colors.textSecondary,
        minimumSize: const Size.fromHeight(48),
        elevation: 1,
        shadowColor: colors.primaryBlue.withValues(alpha: 0.16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.textPrimary,
        backgroundColor: colors.surface.withValues(alpha: 0.72),
        minimumSize: const Size.fromHeight(48),
        side: BorderSide(color: colors.primaryBlue.withValues(alpha: 0.48)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colors.primaryBlue,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: colors.navy,
      contentTextStyle: TextStyle(color: colors.surface),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      titleTextStyle: TextStyle(
        color: colors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      contentTextStyle: TextStyle(color: colors.textSecondary, fontSize: 15),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return colors.primaryBlue;
        return Colors.transparent;
      }),
      side: BorderSide(color: colors.border),
    ),
    dividerTheme: DividerThemeData(color: colors.border, thickness: 1),
  );
}

final ThemeData lightTheme = _buildTheme(
  colors: ChezMoiColors.light,
  brightness: Brightness.light,
);

final ThemeData darkTheme = _buildTheme(
  colors: ChezMoiColors.dark,
  brightness: Brightness.dark,
);
