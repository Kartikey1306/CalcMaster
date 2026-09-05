import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';

/// Flat dark surface with a 1 dp hairline border and an optional accent rim.
///
/// Named for the frosted-glass treatment it used to carry; on the near-black
/// canvas a solid, slightly-lifted card reads cleaner (and skips a
/// BackdropFilter per card, which was the app's most expensive raster work).
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? accent;
  final double borderRadius;
  final VoidCallback? onTap;
  final bool glowRim;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Spacing.md),
    this.accent,
    this.borderRadius = Radii.card,
    this.onTap,
    this.glowRim = false,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = accent ?? AppColors.accentPrimary;
    final inner = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color:
              glowRim ? accentColor.withValues(alpha: 0.45) : AppColors.border,
          width: glowRim ? 1.5 : 1,
        ),
        boxShadow: glowRim
            ? [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.14),
                  blurRadius: 24,
                  spreadRadius: -6,
                ),
              ]
            : null,
      ),
      child: child,
    );

    if (onTap == null) return inner;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap!();
        },
        child: inner,
      ),
    );
  }
}
