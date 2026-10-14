import 'package:flutter/material.dart';

import '../../theme/tokens.dart';

/// A strip of ruled paper: a 1 px rule along the bottom and the margin rule
/// beside the gutter (bottle green at 40 %). Every sheet row is drawn on one,
/// and an empty one continues the page below the last line.
class RuledPaper extends StatelessWidget {
  /// Width of the line-number gutter; the margin rule sits on its right edge.
  static const double gutter = 48;

  /// Line pitch used to rule the empty paper below the last line.
  static const double pitch = 48;

  final Widget child;

  /// Rule the whole area every [pitch] (the empty page), rather than only
  /// under the row.
  final bool fill;
  const RuledPaper({super.key, required this.child, this.fill = false});

  @override
  Widget build(BuildContext context) {
    final c = context.ledger;
    return CustomPaint(
      painter: RuledPaperPainter(
        rule: c.rule,
        margin: c.primary.withValues(alpha: 0.4),
        fill: fill,
      ),
      child: child,
    );
  }
}

class RuledPaperPainter extends CustomPainter {
  final Color rule;
  final Color margin;
  final bool fill;
  const RuledPaperPainter(
      {required this.rule, required this.margin, this.fill = false});

  @override
  void paint(Canvas canvas, Size size) {
    final rulePaint = Paint()
      ..color = rule
      ..strokeWidth = 1;
    final marginPaint = Paint()
      ..color = margin
      ..strokeWidth = 1;
    if (fill) {
      for (var y = RuledPaper.pitch - 0.5; y < size.height; y += RuledPaper.pitch) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), rulePaint);
      }
    } else {
      final y = size.height - 0.5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), rulePaint);
    }
    canvas.drawLine(const Offset(RuledPaper.gutter + 0.5, 0),
        Offset(RuledPaper.gutter + 0.5, size.height), marginPaint);
  }

  @override
  bool shouldRepaint(RuledPaperPainter old) =>
      old.rule != rule || old.margin != margin || old.fill != fill;
}
