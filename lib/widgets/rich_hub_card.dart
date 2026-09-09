import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/tokens.dart';
import 'glass_card.dart';

/// Card with a tinted icon square + title + subtitle, on a flat dark surface.
class RichHubCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String svgPath;
  final Color accent;
  final VoidCallback onTap;

  const RichHubCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.svgPath,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      accent: accent,
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(
          Spacing.md, Spacing.md, Spacing.md, Spacing.md),
      glowRim: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: SvgPicture.asset(
                svgPath,
                width: 18,
                height: 18,
                colorFilter: ColorFilter.mode(accent, BlendMode.srcIn),
              ),
            ),
          ),
          const SizedBox(height: Spacing.sm),
          // Flexible like the subtitle: at 2.0x text scale a fixed-height
          // title plus a flexible subtitle overflowed the card by 2.9px,
          // because only one of the two could give way.
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
