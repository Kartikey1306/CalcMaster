import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'pressable_scale.dart';

/// Which palette slot a keypad key belongs to (iOS Calculator convention).
enum CalcKeyKind {
  /// AC / ⌫ / +/− / % / SWAP — light gray.
  function,

  /// Digits and the decimal point — dark gray.
  digit,

  /// ÷ × − + = — amber, inverts while latched.
  operator,

  /// Scientific function keys — the darkest, most recessive slot.
  secondary,
}

/// A single round keypad key.
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
  }) : assert(label != null || icon != null, 'a key needs a label or an icon');

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (kind) {
      case CalcKeyKind.function:
        bg = active ? AppColors.accentPrimary : KeyColors.function;
        fg = active ? Colors.black : KeyColors.functionText;
        break;
      case CalcKeyKind.digit:
        bg = KeyColors.digit;
        fg = KeyColors.digitText;
        break;
      case CalcKeyKind.secondary:
        bg = active ? AppColors.accentPrimary : KeyColors.secondary;
        fg = active ? Colors.black : KeyColors.digitText;
        break;
      case CalcKeyKind.operator:
        bg = active ? KeyColors.operatorActive : KeyColors.operator;
        fg = active ? KeyColors.operator : KeyColors.operatorText;
        break;
    }

    // A wide key spans N columns plus the gaps it bridges.
    final width = size * widthFactor + gap * (widthFactor - 1);
    final wide = widthFactor > 1;

    return PressableScale(
      onTap: onTap,
      haptic: haptic,
      child: Container(
        width: width,
        height: size,
        // Wide keys keep their glyph over the first column, like iOS's `0`.
        alignment: wide ? Alignment.centerLeft : Alignment.center,
        padding: wide ? EdgeInsets.only(left: size * 0.36) : EdgeInsets.zero,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(size / 2),
          boxShadow: kind == CalcKeyKind.operator && !active
              ? [
                  BoxShadow(
                    color: KeyColors.operator.withValues(alpha: 0.35),
                    blurRadius: 14,
                    spreadRadius: -5,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: icon != null
            ? Icon(icon, color: fg, size: size * 0.36)
            : Text(
                label!,
                maxLines: 1,
                style: TextStyle(
                  color: fg,
                  fontSize: size * 0.4 * fontScale,
                  fontWeight: FontWeight.w500,
                  height: 1,
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
                padding: const EdgeInsets.only(bottom: 4),
                child: FittedBox(
                  alignment: Alignment.centerRight,
                  fit: BoxFit.scaleDown,
                  child: Text(
                    expression,
                    maxLines: 1,
                    style: const TextStyle(
                      color: AppColors.textMuted,
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
                  color: idle ? AppColors.textDim : AppColors.text,
                  fontSize: 64,
                  fontWeight: FontWeight.w300,
                  height: 1.1,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
