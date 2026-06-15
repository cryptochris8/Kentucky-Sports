import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

/// Typography for Bluegrass Gameday.
///
/// Uses Google Fonts (Inter for body, Oswald for broadcast-style headers).
/// google_fonts gracefully falls back to a platform font when the CDN is
/// unreachable, so the app still runs offline.
abstract final class BgTypography {
  /// Builds a [TextTheme] layered on a base scheme color.
  static TextTheme textTheme(Color onSurface) {
    final TextTheme body = GoogleFonts.interTextTheme();
    final TextStyle Function({
      TextStyle? textStyle,
      Color? color,
      double? fontSize,
      FontWeight? fontWeight,
      double? letterSpacing,
      double? height,
    })
    display = GoogleFonts.oswald;

    return TextTheme(
      // Broadcast-style display headers (Oswald, condensed, uppercase-friendly).
      displayLarge: display(
        color: onSurface,
        fontSize: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        height: 1.05,
      ),
      displayMedium: display(
        color: onSurface,
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
      headlineMedium: display(
        color: onSurface,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
      titleLarge: GoogleFonts.inter(
        color: onSurface,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: GoogleFonts.inter(
        color: onSurface,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: body.bodyLarge?.copyWith(color: onSurface, fontSize: 15),
      bodyMedium: body.bodyMedium?.copyWith(
        color: onSurface,
        fontSize: 13.5,
        height: 1.35,
      ),
      bodySmall: body.bodySmall?.copyWith(color: BgColors.slate, fontSize: 12),
      labelLarge: GoogleFonts.inter(
        color: onSurface,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
      labelSmall: GoogleFonts.inter(
        color: BgColors.slate,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
      ),
    );
  }

  /// Eyebrow/overline style used above section content.
  static TextStyle eyebrow(Color color) => GoogleFonts.inter(
    color: color,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
  );

  /// Big numeric stat style (Oswald).
  static TextStyle statNumber(Color color, {double size = 26}) =>
      GoogleFonts.oswald(
        color: color,
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      );
}
