import 'package:flutter/material.dart';

/// Bluegrass Gameday color system — Pass 1 redesign.
///
/// ORIGINAL bluegrass-inspired palette — NOT official University of Kentucky
/// marks. A premium Kentucky blue + white system with a tinted-navy dark mode.
/// The old bluegrass gold is DEMOTED to a hairline / accent role only — never a
/// large fill or body text (the "championship banner" cue).
///
/// Legacy token names are preserved (remapped onto the new palette) so existing
/// screens that reference [BgColors] directly keep compiling and pick up the
/// new look automatically. Prefer the new semantic names ([primary],
/// [interactive], [ink], …) and `Theme.of(context).colorScheme` in new code.
abstract final class BgColors {
  // ---------------------------------------------------------------------------
  // LIGHT — brand core
  // ---------------------------------------------------------------------------

  /// Primary Kentucky blue (brand anchor, default filled buttons, selected nav).
  static const Color primary = Color(0xFF0033A0);

  /// Brighter interactive blue (links, focus, the one gradient CTA).
  static const Color primaryBright = Color(0xFF1E64E6);

  /// Pressed/active primary state.
  static const Color primaryPressed = Color(0xFF002A82);

  /// Foreground on primary fills.
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// Gold accent — HAIRLINE / RULE / small-accent ONLY. Never a large fill or
  /// body text. AA-safe only as a graphic accent, not as text on white.
  static const Color accentGold = Color(0xFFC8A24A);
  static const Color accentGoldBright = Color(0xFFE7CE86);

  // ---------------------------------------------------------------------------
  // LIGHT — surfaces & neutrals
  // ---------------------------------------------------------------------------

  static const Color surface = Color(0xFFFFFFFF);
  static const Color canvas = Color(0xFFF5F7FB);
  static const Color surfaceAlt = Color(0xFFEEF2FB);

  static const Color ink = Color(0xFF0E1726);
  static const Color slate = Color(0xFF56607A);
  static const Color mist = Color(0xFF9AA3B8);
  static const Color hairline = Color(0xFFE3E8F2);

  // ---------------------------------------------------------------------------
  // LIGHT — semantic
  // ---------------------------------------------------------------------------

  static const Color positive = Color(0xFF1F9D63);
  static const Color negative = Color(0xFFD24437);
  static const Color warning = Color(0xFFE0A02E);
  static const Color info = Color(0xFF1E64E6);

  // ---------------------------------------------------------------------------
  // DARK — tinted navy (never pure black/white)
  // ---------------------------------------------------------------------------

  static const Color darkBg = Color(0xFF0A1020);
  static const Color darkSurface = Color(0xFF111A2E);
  static const Color darkSurfaceElevated = Color(0xFF18243D);
  static const Color darkHairline = Color(0xFF27344F);
  static const Color darkPrimary = Color(0xFF5B8CFF);
  static const Color darkOnPrimaryContainer = Color(0xFFD6E2FF);
  static const Color darkTextPrimary = Color(0xFFF4F7FF);
  static const Color darkTextSecondary = Color(0xFFA7B2CC);
  static const Color darkAccentGold = Color(0xFFD8B45E);

  // ---------------------------------------------------------------------------
  // LEGACY ALIASES — kept so existing screens keep compiling & restyling.
  // These intentionally point at the NEW palette.
  // ---------------------------------------------------------------------------

  /// Legacy name for the brand anchor — now the new [primary].
  static const Color deepBlue = primary;

  /// Legacy bright blue — now [primaryBright].
  static const Color blueBright = primaryBright;

  /// Legacy gold core — DEMOTED to the [accentGold] hairline role.
  static const Color bluegrassGold = accentGold;
  static const Color goldBright = accentGoldBright;
  static const Color goldDark = primaryPressed; // gold no longer a "dark" fill

  /// Legacy deep-navy surface used for snackbars / brand mark depth.
  static const Color blueDark = Color(0xFF0A1B3D);

  /// Legacy mid blue (kept for gradients that referenced it).
  static const Color blueMid = Color(0xFF143A86);

  /// Legacy very-light blue tint — now [surfaceAlt].
  static const Color blueTint = surfaceAlt;

  // Rarity (badges / collectible cards). Tuned to the new palette.
  static const Color rarityCommon = mist;
  static const Color rarityRare = primaryBright;
  static const Color rarityEpic = Color(0xFF8B5CD6);
  static const Color rarityLegendary = accentGold;

  // ---------------------------------------------------------------------------
  // Gradients
  // ---------------------------------------------------------------------------

  /// Primary brand gradient: deep Kentucky blue -> interactive blue (135deg).
  static const LinearGradient skyGradient = LinearGradient(
    begin: Alignment.topLeft, // ~135deg
    end: Alignment.bottomRight,
    colors: <Color>[primary, primaryBright],
  );

  /// Dark-mode hero gradient (tinted navy, never black).
  static const LinearGradient nightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[darkBg, Color(0xFF14254A)],
  );

  /// Thin gold rule — used ONLY as a 24-40px underline / hairline accent
  /// (the "championship banner" cue). Never a large fill.
  static const LinearGradient goldRule = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: <Color>[accentGold, accentGoldBright],
  );

  /// Legacy alias — the hero gradient is now the [skyGradient].
  static const LinearGradient heroGradient = skyGradient;

  /// Legacy alias — the gold gradient is now the thin [goldRule].
  static const LinearGradient goldGradient = goldRule;

  /// Returns the rarity color for a badge rarity string.
  static Color rarity(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'rare':
        return rarityRare;
      case 'epic':
        return rarityEpic;
      case 'legendary':
        return rarityLegendary;
      case 'common':
      default:
        return rarityCommon;
    }
  }
}
