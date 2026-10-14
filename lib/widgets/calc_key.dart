import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'pressable_scale.dart';

/// Which palette slot a keypad key belongs to.
enum CalcKeyKind {
  /// AC / ⌫ / +/− / % / SWAP — a faint ink wash.
  function,

  /// Digits and the decimal point — plain paper.
  digit,

  /// ÷ × − + = — bottle green, copper while latched.
  operator,

  /// Scientific function keys — the darkest, most recessive slot.
  secondary,
}

/// A single keypad key: a ruled rectangle with 4 px corners.
///
/// [size] is the key's diameter; a key that spans several columns passes
/// [widthFactor] > 1 and the [gap] it bridges so it lines up with the grid.
class CalcKey extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final CalcKeyKind kind;
  final double size;
  final double gap;
  final double widthFactor;

  /// Latched state — a pending operator, or a toggle like `2nd` / `Deg`.
  final bool active;

  /// Multiplies the derived font size; used to fit long labels like `log₁₀`.
  final double fontScale;

  final VoidCallback onTap;
  final HapticFeedbackKind haptic;

  /// Overrides what a screen reader announces. Required for icon-only keys
  /// (backspace), which have no [label] to fall back on.
  final String? semanticLabel;

  const CalcKey({
    super.key,
    this.label,
    this.icon,
    required this.kind,
    required this.size,
    required this.onTap,
    this.gap = 0,
    this.widthFactor = 1,
    this.active = false,
    this.fontScale = 1,
    this.haptic = HapticFeedbackKind.selection,
    this.semanticLabel,
  }) : assert(label != null || icon != null, 'a key needs a label or an icon');

  /// Spoken names for the glyphs on the keypad. VoiceOver and TalkBack read
  /// bare symbols like `÷`, `⌫` or `+/−` as nothing at all or as punctuation,
  /// so every non-alphanumeric key gets a word.
  static const _spoken = <String, String>{
    'AC': 'All clear',
    'C': 'Clear',
    '⌫': 'Backspace',
    '+/−': 'Toggle sign',
    '%': 'Percent',
    '÷': 'Divide',
    '×': 'Multiply',
    '−': 'Minus',
    '-': 'Minus',
    '+': 'Plus',
    '=': 'Equals',
    '.': 'Decimal point',
    '(': 'Open bracket',
    ')': 'Close bracket',
    '√': 'Square root',
    'x²': 'Square',
    'xʸ': 'Power',
    '1/x': 'Reciprocal',
    'π': 'Pi',
    'n!': 'Factorial',
    '±': 'Toggle sign',
  };

  /// The announced name: an explicit [semanticLabel] wins, otherwise the
  /// glyph's spoken form, otherwise the glyph itself.
  static String spokenName(String? label, String? semanticLabel) {
    final source = semanticLabel ?? label;
    if (source == null || source.isEmpty) return '';
    return _spoken[source] ?? source;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ledger;
    Color bg;
    Color fg;
    switch (kind) {
      case CalcKeyKind.function:
        bg = active ? c.primary : c.ink.withValues(alpha: 0.08);
        fg = active ? c.onPrimary : c.ink;
        break;
      case CalcKeyKind.digit:
        bg = c.paper;
        fg = c.ink;
        break;
      case CalcKeyKind.secondary:
        bg = active ? c.primary : c.ink.withValues(alpha: 0.05);
        fg = active ? c.onPrimary : c.ink;
        break;
      case CalcKeyKind.operator:
        bg = active ? c.result : c.primary;
        fg = active ? c.paper : c.onPrimary;
        break;
    }

    // A wide key spans N columns plus the gaps it bridges.
    final width = size * widthFactor + gap * (widthFactor - 1);

    return Semantics(
      container: true,
      button: true,
      enabled: true,
      selected: active,
      label: spokenName(label, semanticLabel),
      excludeSemantics: true,
      child: PressableScale(
        onTap: onTap,
        haptic: haptic,
        child: Container(
          width: width,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(Radii.button),
            border: Border.all(color: c.rule),
          ),
          child: icon != null
              ? Icon(icon, color: fg, size: size * 0.36)
              : Text(
                  label!,
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: Fonts.figures,
                    color: fg,
                    fontSize: size * 0.36 * fontScale,
                    fontWeight: FontWeight.w500,
                    height: 1,
                  ),
                ),
        ),
      ),
    );
  }
}

/// Lays out rows of [CalcKey]s on a fixed 4-or-more column grid.
class CalcKeypad extends StatelessWidget {
  final List<List<Widget>> rows;
  final double gap;
  const CalcKeypad({super.key, required this.rows, required this.gap});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var r = 0; r < rows.length; r++)
          Padding(
            padding: EdgeInsets.only(bottom: r == rows.length - 1 ? 0 : gap),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < rows[r].length; i++) ...[
                  if (i > 0) SizedBox(width: gap),
                  rows[r][i],
                ],
              ],
            ),
          ),
      ],
    );
  }
}

/// The expression / result readout that sits above a keypad.
///
/// Mirrors the reference design: the expression is a small muted line, the
/// value below it is the large one, and once a result is committed the
/// expression keeps a trailing `=`.
class CalcDisplay extends StatelessWidget {
  /// Small muted line — the expression being typed, or `expr =` after equals.
  final String expression;

  /// Large line — the live result while typing, the answer after equals, or
  /// `0` when idle.
  final String value;

  /// Renders `0` in outline gray, as in the reference's idle state.
  final bool idle;

  final double maxWidth;

  /// Fired on a horizontal swipe across the display (backspace).
  final VoidCallback? onSwipe;

  const CalcDisplay({
    super.key,
    required this.expression,
    required this.value,
    required this.maxWidth,
    this.idle = false,
    this.onSwipe,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      // The readout changes on every keypress; a live region makes the screen
      // reader announce the new result instead of leaving it silent.
      liveRegion: true,
      label: expression.isEmpty ? 'Result' : 'Result for $expression',
      value: value,
      excludeSemantics: true,
      child: _build(context),
    );
  }

  Widget _build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: onSwipe == null ? null : (_) => onSwipe!(),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: maxWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (expression.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: FittedBox(
                  alignment: Alignment.centerRight,
                  fit: BoxFit.scaleDown,
                  child: Text(
                    expression,
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: Fonts.figures,
                      color: context.ledger.inkSoft,
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            FittedBox(
              alignment: Alignment.centerRight,
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                maxLines: 1,
                style: TextStyle(
                  fontFamily: Fonts.figures,
                  color: idle ? context.ledger.inkSoft : context.ledger.result,
                  fontSize: 56,
                  fontWeight: FontWeight.w400,
                  height: 1.1,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
