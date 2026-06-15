import 'package:flutter/material.dart';

/// Bluegrass Gameday color system.
///
/// ORIGINAL bluegrass-inspired palette — NOT official University of Kentucky
/// marks. Deep blue + bluegrass gold with abstract supporting tones.
abstract final class BgColors {
  // Brand core (locked).
  static const Color deepBlue = Color(0xFF1E5AA8);
  static const Color bluegrassGold = Color(0xFFC8B273);

  // Blue ramp for surfaces, gradients, and depth.
  static const Color blueDark = Color(0xFF0E2C54);
  static const Color blueMid = Color(0xFF174277);
  static const Color blueBright = Color(0xFF2F73C9);
  static const Color blueTint = Color(0xFFE8F0FA);

  // Gold ramp.
  static const Color goldDark = Color(0xFFA8924F);
  static const Color goldBright = Color(0xFFE0CB92);

  // Neutrals (light scheme).
  static const Color ink = Color(0xFF14181F);
  static const Color slate = Color(0xFF5A6473);
  static const Color mist = Color(0xFF8B95A5);
  static const Color hairline = Color(0xFFE2E6EC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color canvas = Color(0xFFF4F6FA);

  // Semantic.
  static const Color positive = Color(0xFF2E9E6B);
  static const Color negative = Color(0xFFD1544B);
  static const Color warning = Color(0xFFE0A042);
  static const Color info = blueBright;

  // Rarity (badges / collectible cards).
  static const Color rarityCommon = Color(0xFF8B95A5);
  static const Color rarityRare = Color(0xFF2F73C9);
  static const Color rarityEpic = Color(0xFF8B5CD6);
  static const Color rarityLegendary = Color(0xFFC8B273);

  /// Hero gradient used on matchup cards and the top bar.
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[blueDark, deepBlue, blueBright],
  );

  /// Subtle gold accent gradient for badges/CTAs.
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[goldBright, bluegrassGold, goldDark],
  );

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
