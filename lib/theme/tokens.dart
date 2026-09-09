import 'package:flutter/material.dart';

class AppColors {
  // Near-black canvas in the spirit of the iOS Calculator / dark instrument
  // apps: the UI is carried by the amber accent and the key contrast, not by
  // a colored background.
  static const bg = Color(0xFF000000);
  static const surface = Color(0xFF141416);
  static const surfaceAlt = Color(0xFF1C1C1E);
  static const surfaceElevated = Color(0xFF2C2C2E);
  static const text = Color(0xFFFFFFFF);
  static const textMuted = Color(0x9EFFFFFF); // 62%
  // 50%, not 42%: at 42% this composites to a 4.11 contrast ratio on the
  // black background, under the 4.5 WCAG AA minimum for the 11px labels
  // in the tab bar. 50% measures 5.3 on black and 5.3 on `surface`.
  static const textDim = Color(0x80FFFFFF); // 50%
  static const border = Color(0x14FFFFFF); // 8%
  static const borderStrong = Color(0x24FFFFFF); // 14%
  static const accentPrimary = Color(0xFFFF9F0A); // amber — operators & CTAs
  static const accentSoft = Color(0x1FFF9F0A); // 12% amber wash
  static const danger = Color(0xFFFF5C7A);
  static const success = Color(0xFF5CE0A8);
  static const warning = Color(0xFFFFC85C);
}

/// Calculator keypad palette (iOS Calculator layout: gray functions, darker
/// digits, amber operators that invert while held/active).
class KeyColors {
  static const function = Color(0xFF3A3A3C); // AC, +/−, %, SWAP
  static const functionText = Color(0xFFFFFFFF);
  static const digit = Color(0xFF2C2C2E); // numbers & decimal
  static const digitText = Color(0xFFFFFFFF);
  static const secondary = Color(0xFF232325); // scientific function keys
  static const operator = AppColors.accentPrimary; // ÷ × − + =
  static const operatorText = Color(0xFFFFFFFF);
  static const operatorActive = Color(0xFFFFFFFF); // pressed/latched operator
}

/// Per-category tints. Kept inside one warm amber family so the app reads as
/// a single monochrome system (as in the reference design) while each
/// category still has its own shade.
class CategoryAccent {
  static const distance = Color(0xFFFFB13C); // amber
  static const volume = Color(0xFFFFC85C); // honey
  static const weight = Color(0xFFE0A44A); // bronze
  static const temperature = Color(0xFFFF8A4C); // ember
  static const speed = Color(0xFFFFD166); // sun
  static const area = Color(0xFFD9B168); // sand
  static const dataSize = Color(0xFFF2B33D); // marigold
  static const fuelEconomy = Color(0xFFFF9F0A); // signal orange
  static const pressure = Color(0xFFE8A15C); // clay
  static const energy = Color(0xFFFFD86B); // gold
}

class Radii {
  static const card = 20.0;
  static const cardThumb = 18.0;
  static const pill = 999.0;
  static const button = 14.0;
  static const input = 16.0;
  static const sheet = 24.0;
}

class Spacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;
}
