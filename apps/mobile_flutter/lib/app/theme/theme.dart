import 'package:flutter/material.dart';

import 'colors.dart';
import 'typography.dart';

/// Central [ThemeData] for Bluegrass Gameday.
///
/// A cohesive light theme with rounded cards, deep blue brand surfaces, and
/// gold accents. Built for accessible contrast and a modern broadcast feel.
abstract final class BgTheme {
  /// Standard card corner radius used across the app.
  static const double cardRadius = 18;
  static const double pillRadius = 999;

  static ThemeData light() {
    const ColorScheme scheme = ColorScheme(
      brightness: Brightness.light,
      primary: BgColors.deepBlue,
      onPrimary: Colors.white,
      secondary: BgColors.bluegrassGold,
      onSecondary: BgColors.ink,
      tertiary: BgColors.blueBright,
      onTertiary: Colors.white,
      error: BgColors.negative,
      onError: Colors.white,
      surface: BgColors.surface,
      onSurface: BgColors.ink,
      surfaceContainerHighest: BgColors.blueTint,
      outline: BgColors.hairline,
    );

    final TextTheme text = BgTypography.textTheme(scheme.onSurface);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: BgColors.canvas,
      textTheme: text,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: BgColors.canvas,
        surfaceTintColor: Colors.transparent,
        foregroundColor: BgColors.ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: text.headlineMedium,
      ),
      cardTheme: CardThemeData(
        color: BgColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: const BorderSide(color: BgColors.hairline),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: BgColors.blueTint,
        side: BorderSide.none,
        labelStyle: text.labelSmall,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(pillRadius),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: BgColors.hairline,
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: BgColors.deepBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 48),
          textStyle: text.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: BgColors.deepBlue,
          minimumSize: const Size(0, 48),
          side: const BorderSide(color: BgColors.deepBlue, width: 1.4),
          textStyle: text.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: BgColors.surface,
        indicatorColor: BgColors.blueTint,
        elevation: 0,
        height: 66,
        labelTextStyle: WidgetStatePropertyAll<TextStyle>(
          text.labelSmall!.copyWith(letterSpacing: 0.2),
        ),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((
          Set<WidgetState> states,
        ) {
          final bool selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? BgColors.deepBlue : BgColors.mist,
            size: 24,
          );
        }),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: BgColors.deepBlue,
        linearTrackColor: BgColors.hairline,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: BgColors.blueDark,
        contentTextStyle: text.bodyMedium?.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: BgColors.deepBlue,
        unselectedLabelColor: BgColors.mist,
        labelStyle: text.labelLarge,
        unselectedLabelStyle: text.labelLarge,
        indicatorColor: BgColors.bluegrassGold,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: BgColors.hairline,
      ),
    );
  }
}
