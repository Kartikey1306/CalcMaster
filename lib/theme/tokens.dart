import 'package:flutter/material.dart';

/// The "Ledger" palette: a ruled sheet of paper, bottle-green ink for
/// actions, copper for worked-out figures. "Night ledger" is the same sheet
/// after dark.
///
/// Every text pair here is at least 4.5:1 (WCAG AA); `test/identity_test.dart`
/// measures them. The hexes are this app's own — none of them appears in any
/// other app of the portfolio.
@immutable
class LedgerColors extends ThemeExtension<LedgerColors> {
  /// Scaffold / the sheet itself.
  final Color paper;

  /// Raised surfaces: inputs, the footer, bottom sheets.
  final Color surface;

  /// The 1 px rule under every sheet line, and every divider.
  final Color rule;

  /// Body text.
  final Color ink;

  /// Secondary text: captions, gutter numbers, hints.
  final Color inkSoft;

  /// Actions, the margin rule, the "=" mark.
  final Color primary;

  /// Text and icons on [primary].
  final Color onPrimary;

  /// Worked-out figures: line results and the total.
  final Color result;

  /// Error lines and destructive actions.
  final Color error;

  const LedgerColors({
    required this.paper,
    required this.surface,
    required this.rule,
    required this.ink,
    required this.inkSoft,
    required this.primary,
    required this.onPrimary,
    required this.result,
    required this.error,
  });

  /// Light, the default.
  static const ledger = LedgerColors(
    paper: Color(0xFFF4F0E6),
    surface: Color(0xFFF4F0E6),
    rule: Color(0xFFD9D2C1),
    ink: Color(0xFF22201C),
    inkSoft: Color(0xFF6B6457),
    primary: Color(0xFF2C5E4F),
    onPrimary: Color(0xFFFFFFFF),
    result: Color(0xFF9A4A14),
    error: Color(0xFFA8322A),
  );

  /// Dark.
  static const night = LedgerColors(
    paper: Color(0xFF161A17),
    surface: Color(0xFF1F2420),
    rule: Color(0xFF353C36),
    ink: Color(0xFFEAE5D7),
    inkSoft: Color(0xFFB3AC9C),
    primary: Color(0xFF7FB89F),
    onPrimary: Color(0xFF161A17),
    result: Color(0xFFE2A273),
    error: Color(0xFFEE8F84),
  );

  static LedgerColors of(BuildContext context) =>
      Theme.of(context).extension<LedgerColors>() ?? ledger;

  @override
  LedgerColors copyWith({
    Color? paper,
    Color? surface,
    Color? rule,
    Color? ink,
    Color? inkSoft,
    Color? primary,
    Color? onPrimary,
    Color? result,
    Color? error,
  }) =>
      LedgerColors(
        paper: paper ?? this.paper,
        surface: surface ?? this.surface,
        rule: rule ?? this.rule,
        ink: ink ?? this.ink,
        inkSoft: inkSoft ?? this.inkSoft,
        primary: primary ?? this.primary,
        onPrimary: onPrimary ?? this.onPrimary,
        result: result ?? this.result,
        error: error ?? this.error,
      );

  @override
  LedgerColors lerp(ThemeExtension<LedgerColors>? other, double t) {
    if (other is! LedgerColors) return this;
    return LedgerColors(
      paper: Color.lerp(paper, other.paper, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      rule: Color.lerp(rule, other.rule, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkSoft: Color.lerp(inkSoft, other.inkSoft, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      result: Color.lerp(result, other.result, t)!,
      error: Color.lerp(error, other.error, t)!,
    );
  }
}

extension LedgerContext on BuildContext {
  /// The current Ledger / Night ledger colours.
  LedgerColors get ledger => LedgerColors.of(this);
}

/// Font families bundled under `assets/fonts/`.
class Fonts {
  /// Interface text.
  static const ui = 'GolosText';

  /// Every figure: line input, results, gutter numbers, the total, keys.
  static const figures = 'RedditMono';

  /// Tabular figures so columns of numbers line up.
  static const tabular = [FontFeature.tabularFigures()];
}

/// Shape language: square sheet rows, barely rounded buttons and chips, and
/// bottom sheets whose top corners are the only soft edge.
class Radii {
  static const button = 4.0;
  static const chip = 4.0;
  static const input = 4.0;
  static const sheetTop = 8.0;
  static const row = 0.0;
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
