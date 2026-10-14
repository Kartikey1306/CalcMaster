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
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: highlight ? context.ledger.surface : context.ledger.surface,
        borderRadius: BorderRadius.circular(Radii.button),
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.button),
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
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: Spacing.lg, vertical: Spacing.md),
            decoration: BoxDecoration(
              border: Border.all(
                  color: highlight ? context.ledger.rule : context.ledger.rule),
              borderRadius: BorderRadius.circular(Radii.button),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: TextStyle(
                              color: context.ledger.ink,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                      if (caption != null)
                        Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Text(caption!,
                              style: TextStyle(
                                  color: context.ledger.inkSoft, fontSize: 13)),
                        ),
                    ],
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 180),
                  child: Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      color: highlight ? context.ledger.primary : context.ledger.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(width: Spacing.md),
                Icon(Icons.copy_outlined,
                    size: 16, color: context.ledger.inkSoft),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
