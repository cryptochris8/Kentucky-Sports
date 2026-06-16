import 'package:flutter/material.dart';

import 'colors.dart';
import 'typography.dart';

/// Central [ThemeData] + design tokens for Bluegrass Gameday — Pass 1 redesign.
///
/// A cohesive Kentucky-blue + white system with soft tinted-shadow depth, a
/// premium expressive type scale, and a polished tinted-navy dark mode. The old
/// flat, border-only look is replaced by a soft elevation ladder.
abstract final class BgTheme {
  // ---------------------------------------------------------------------------
  // Spacing scale (4pt grid).
  // ---------------------------------------------------------------------------
  static const double xs4 = 4;
  static const double sm8 = 8;
  static const double md12 = 12;
  static const double lg16 = 16;
  static const double xl24 = 24;
  static const double xxl32 = 32;
  static const double xxxl48 = 48;

  // ---------------------------------------------------------------------------
  // Radius scale.
  // ---------------------------------------------------------------------------
  static const double radiusChip = 999;
  static const double radiusButton = 16;
  static const double radiusCard = 20;
  static const double radiusHero = 28;
  static const double radiusSheet = 28;
  static const double radiusInput = 14;

  /// Legacy aliases (kept for existing callers).
  static const double cardRadius = radiusCard;
  static const double pillRadius = radiusChip;

  // ---------------------------------------------------------------------------
  // Motion tokens.
  // ---------------------------------------------------------------------------
  static const Duration motionMicro = Duration(milliseconds: 120);
  static const Duration motionStandard = Duration(milliseconds: 220);
  static const Duration motionEmphasized = Duration(milliseconds: 380);

  static const Curve curveStandard = Curves.easeOutCubic;
  static const Curve curveMicro = Curves.easeOutCubic;
  static const Curve curveEmphasized = Curves.easeOutQuint;

  /// Springy press-scale target for tappable surfaces.
  static const double pressScale = 0.97;

  // ---------------------------------------------------------------------------
  // Elevation — soft TINTED shadows (the signature upgrade).
  // In dark mode we rely on the surface ladder + a top-highlight hairline
  // instead of shadows, so these return an empty list when [dark] is true.
  // ---------------------------------------------------------------------------

  /// Resting card elevation.
  static List<BoxShadow> e1({bool dark = false}) => dark
      ? const <BoxShadow>[]
      : <BoxShadow>[
          BoxShadow(
            color: BgColors.primary.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: -6,
          ),
        ];

  /// Raised / floating elevation (CTAs, nav bar, popovers).
  static List<BoxShadow> e2({bool dark = false}) => dark
      ? const <BoxShadow>[]
      : <BoxShadow>[
          BoxShadow(
            color: BgColors.primary.withValues(alpha: 0.10),
            blurRadius: 28,
            offset: const Offset(0, 10),
            spreadRadius: -8,
          ),
        ];

  // ---------------------------------------------------------------------------
  // Theme mode — default to following the system.
  // ---------------------------------------------------------------------------
  static const ThemeMode themeMode = ThemeMode.system;

  // ---------------------------------------------------------------------------
  // LIGHT
  // ---------------------------------------------------------------------------
  static ThemeData light() {
    const ColorScheme scheme = ColorScheme(
      brightness: Brightness.light,
      primary: BgColors.primary,
      onPrimary: BgColors.onPrimary,
      primaryContainer: BgColors.surfaceAlt,
      onPrimaryContainer: BgColors.primary,
      secondary: BgColors.primaryBright,
      onSecondary: BgColors.onPrimary,
      tertiary: BgColors.accentGold,
      onTertiary: BgColors.ink,
      error: BgColors.negative,
      onError: BgColors.onPrimary,
      surface: BgColors.surface,
      onSurface: BgColors.ink,
      onSurfaceVariant: BgColors.slate,
      surfaceContainerHighest: BgColors.surfaceAlt,
      outline: BgColors.hairline,
      outlineVariant: BgColors.hairline,
    );

    return _build(
      scheme: scheme,
      dark: false,
      canvas: BgColors.canvas,
      surface: BgColors.surface,
      onSurface: BgColors.ink,
      secondaryText: BgColors.slate,
      hairline: BgColors.hairline,
      chipBg: BgColors.surfaceAlt,
      navBg: BgColors.surface,
      navSelected: BgColors.primary,
      navUnselected: BgColors.mist,
      snackBg: BgColors.ink,
    );
  }

  // ---------------------------------------------------------------------------
  // DARK — tinted navy. Depth comes from the surface ladder, not shadows.
  // ---------------------------------------------------------------------------
  static ThemeData dark() {
    const ColorScheme scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: BgColors.darkPrimary,
      onPrimary: BgColors.darkBg,
      primaryContainer: BgColors.darkSurfaceElevated,
      onPrimaryContainer: BgColors.darkOnPrimaryContainer,
      secondary: BgColors.darkPrimary,
      onSecondary: BgColors.darkBg,
      tertiary: BgColors.darkAccentGold,
      onTertiary: BgColors.darkBg,
      error: BgColors.negative,
      onError: BgColors.darkTextPrimary,
      surface: BgColors.darkSurface,
      onSurface: BgColors.darkTextPrimary,
      onSurfaceVariant: BgColors.darkTextSecondary,
      surfaceContainerHighest: BgColors.darkSurfaceElevated,
      outline: BgColors.darkHairline,
      outlineVariant: BgColors.darkHairline,
    );

    return _build(
      scheme: scheme,
      dark: true,
      canvas: BgColors.darkBg,
      surface: BgColors.darkSurface,
      onSurface: BgColors.darkTextPrimary,
      secondaryText: BgColors.darkTextSecondary,
      hairline: BgColors.darkHairline,
      chipBg: BgColors.darkSurfaceElevated,
      navBg: BgColors.darkSurface,
      navSelected: BgColors.darkPrimary,
      navUnselected: BgColors.darkTextSecondary,
      snackBg: BgColors.darkSurfaceElevated,
    );
  }

  // ---------------------------------------------------------------------------
  // Shared builder so light & dark stay perfectly in sync.
  // ---------------------------------------------------------------------------
  static ThemeData _build({
    required ColorScheme scheme,
    required bool dark,
    required Color canvas,
    required Color surface,
    required Color onSurface,
    required Color secondaryText,
    required Color hairline,
    required Color chipBg,
    required Color navBg,
    required Color navSelected,
    required Color navUnselected,
    required Color snackBg,
  }) {
    final TextTheme text = BgTypography.textTheme(
      onSurface,
      secondary: secondaryText,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: scheme.brightness,
      scaffoldBackgroundColor: canvas,
      textTheme: text,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: canvas,
        surfaceTintColor: Colors.transparent,
        foregroundColor: onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: text.headlineMedium,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: BorderSide(color: hairline),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: chipBg,
        selectedColor: scheme.primary,
        side: BorderSide.none,
        labelStyle: text.labelSmall,
        secondaryLabelStyle: text.labelSmall?.copyWith(color: scheme.onPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusChip),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: hairline,
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(0, 48),
          textStyle: text.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
        ).copyWith(
          // Springy press feedback via a subtle overlay.
          overlayColor: WidgetStatePropertyAll<Color>(
            Colors.white.withValues(alpha: 0.12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(0, 48),
          side: BorderSide(color: scheme.primary, width: 1.4),
          textStyle: text.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: text.labelLarge,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: navBg,
        indicatorColor: dark
            ? scheme.primary.withValues(alpha: 0.20)
            : BgColors.surfaceAlt,
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
            color: selected ? navSelected : navUnselected,
            size: 24,
          );
        }),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: hairline,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? BgColors.darkSurfaceElevated : BgColors.surfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: BorderSide(color: hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: snackBg,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: dark ? BgColors.darkTextPrimary : Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusInput),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.primary,
        unselectedLabelColor: navUnselected,
        labelStyle: text.labelLarge,
        unselectedLabelStyle: text.labelLarge,
        indicatorColor: scheme.primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: hairline,
      ),
    );
  }
}
