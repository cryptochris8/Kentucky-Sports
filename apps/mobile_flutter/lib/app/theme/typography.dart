import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

/// Typography for Bluegrass Gameday — Pass 1 redesign.
///
/// Pairing: **Space Grotesk** for display / headlines / stat numbers (the
/// default expressive display face) and **Inter** for body / UI. Oswald is kept
/// available as an opt-in "Broadcast" skin face for a later pass.
///
/// google_fonts gracefully falls back to a platform font when the CDN is
/// unreachable, so the app still runs fully offline.
abstract final class BgTypography {
  /// Default display face (expressive, slightly geometric).
  static TextStyle display(
    Color color, {
    double fontSize = 24,
    FontWeight fontWeight = FontWeight.w700,
    double letterSpacing = 0,
    double? height,
  }) => GoogleFonts.spaceGrotesk(
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
    letterSpacing: letterSpacing,
    height: height,
  );

  /// Opt-in condensed "Broadcast" face for a later skin. Kept available.
  static TextStyle broadcast(
    Color color, {
    double fontSize = 24,
    FontWeight fontWeight = FontWeight.w700,
    double letterSpacing = 0.5,
    double? height,
  }) => GoogleFonts.oswald(
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
    letterSpacing: letterSpacing,
    height: height,
  );

  /// Tabular figures — keeps stat numbers from shifting width as they animate.
  static const List<FontFeature> tabular = <FontFeature>[
    FontFeature.tabularFigures(),
  ];

  /// Builds a [TextTheme] layered on a base scheme color.
  ///
  /// [secondary] is used for low-emphasis copy (bodySmall / labelSmall) so the
  /// theme reads correctly in both light and dark schemes.
  static TextTheme textTheme(Color onSurface, {Color? secondary}) {
    final Color sub = secondary ?? BgColors.slate;
    final TextTheme body = GoogleFonts.interTextTheme();

    return TextTheme(
      // Expressive display (Space Grotesk).
      displayLarge: display(
        onSurface,
        fontSize: 44,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.02,
      ),
      displayMedium: display(
        onSurface,
        fontSize: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
        height: 1.05,
      ),
      headlineMedium: display(
        onSurface,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.1,
      ),
      // Titles (Space Grotesk for a touch of brand character).
      titleLarge: display(
        onSurface,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.15,
      ),
      titleMedium: display(
        onSurface,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.2,
      ),
      // Body / UI (Inter).
      bodyLarge: body.bodyLarge?.copyWith(
        color: onSurface,
        fontSize: 15,
        height: 1.45,
      ),
      bodyMedium: body.bodyMedium?.copyWith(
        color: onSurface,
        fontSize: 15,
        height: 1.45,
      ),
      bodySmall: body.bodySmall?.copyWith(
        color: sub,
        fontSize: 13,
        height: 1.4,
      ),
      labelLarge: GoogleFonts.inter(
        color: onSurface,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
      labelSmall: GoogleFonts.inter(
        color: sub,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    );
  }

  /// Eyebrow / overline style used above section content.
  static TextStyle eyebrow(Color color) => GoogleFonts.inter(
    color: color,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.4,
    height: 1.2,
  );

  /// Big numeric stat style (Space Grotesk, tabular figures).
  ///
  /// [size] spans ~26-44 across the app's stat surfaces.
  static TextStyle statNumber(Color color, {double size = 26}) =>
      GoogleFonts.spaceGrotesk(
        color: color,
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.0,
        fontFeatures: tabular,
      );
}
