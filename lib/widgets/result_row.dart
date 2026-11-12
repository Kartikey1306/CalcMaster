import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';

class ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final String? caption;
  final bool highlight;

  const ResultRow({
    super.key,
    required this.label,
    required this.value,
    this.caption,
    this.highlight = false,
  });

  /// What a screen reader announces for the row. The visible layout splits the
  /// label and the value into two columns, which read as two disconnected
  /// fragments; merging them into one node keeps "Future value, $1,234"
  /// together.
  String get semanticsLabel =>
      caption == null ? '$label, $value' : '$label, $caption, $value';

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      label: semanticsLabel,
      hint: 'Copy to clipboard',
      excludeSemantics: true,
      child: _build(context),
    );
  }

  Widget _build(BuildContext context) {
    final c = context.ledger;
    final dark = Theme.of(context).brightness == Brightness.dark;
    // Receipt paper: a shade brighter than the sheet in light mode.
    final slip = dark
        ? c.surface
        : Color.alphaBlend(Colors.white.withValues(alpha: 0.6), c.paper);
    return Padding(
      padding: EdgeInsets.zero,
      child: Material(
        color: slip,
        child: InkWell(
          onTap: () async {
            await Clipboard.setData(ClipboardData(text: value));
            await HapticFeedback.selectionClick();
            if (context.mounted) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: context.ledger.surface,
                    duration: Duration(milliseconds: 1200),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Radii.button),
                      side: BorderSide(
                          color: context.ledger.primary.withValues(alpha: 0.4)),
                    ),
                    content: Row(
                      children: [
                        Icon(Icons.check_circle_outline,
                            color: context.ledger.primary, size: 18),
                        SizedBox(width: Spacing.sm),
                        Expanded(
                          child: Text(
                            'Copied  $value',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: context.ledger.ink,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
            }
          },
          child: CustomPaint(
            // A torn-off till receipt: rows sit flush on one slip, with a
            // dashed rule between them and a dotted leader to each figure.
            foregroundPainter: _DashedRule(color: c.rule),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.lg, vertical: Spacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    // Dots run behind the whole row; the label and the figure
                    // sit on slip-coloured patches that hide them, leaving a
                    // dotted leader in between whatever their lengths.
                    child: CustomPaint(
                      painter: _DotLeader(color: c.rule),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Flexible(
                            flex: 3,
                            child: Container(
                              color: slip,
                              padding: const EdgeInsets.only(right: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(label.toUpperCase(),
                                      style: TextStyle(
                                          fontFamily: Fonts.figures,
                                          color: highlight ? c.ink : c.inkSoft,
                                          fontSize: 13,
                                          letterSpacing: 0.8,
                                          fontWeight: highlight
                                              ? FontWeight.w700
                                              : FontWeight.w500)),
                                  if (caption != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(caption!,
                                          style: TextStyle(
                                              color: c.inkSoft, fontSize: 12)),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          Flexible(
                            flex: 2,
                            child: Container(
                              color: slip,
                              padding: const EdgeInsets.only(left: 6),
                              child: Text(
                                value,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                  fontFamily: Fonts.figures,
                                  fontFeatures: Fonts.tabular,
                                  color: highlight ? c.result : c.ink,
                                  fontSize: highlight ? 20 : 16,
                                  fontWeight: highlight
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Icon(Icons.copy_outlined,
                        size: 14, color: c.inkSoft.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedRule extends CustomPainter {
  final Color color;
  const _DashedRule({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1;
    final y = size.height - 0.5;
    for (var x = Spacing.lg; x < size.width - Spacing.lg; x += 7) {
      canvas.drawLine(Offset(x, y), Offset(x + 3.5, y), p);
    }
  }

  @override
  bool shouldRepaint(_DashedRule old) => old.color != color;
}

class _DotLeader extends CustomPainter {
  final Color color;
  const _DotLeader({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    // Along the baseline of the last line of text.
    final y = size.height - 6;
    for (var x = 0.0; x < size.width; x += 5) {
      canvas.drawCircle(Offset(x + 1, y), 0.9, p);
    }
  }

  @override
  bool shouldRepaint(_DotLeader old) => old.color != color;
}
