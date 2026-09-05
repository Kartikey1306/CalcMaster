import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/generated/app_localizations.dart';
import '../monetization/analytics_service.dart';
import '../theme/tokens.dart';
import 'animated_gradient_background.dart';
import 'banner_ad_slot.dart';
import 'particle_dot_grid.dart';

class TabScaffold extends StatelessWidget {
  final StatefulNavigationShell shell;
  const TabScaffold({super.key, required this.shell});

  static const _tabNames = [
    'convert',
    'calculate',
    'finance',
    'tools',
    'notes'
  ];

  /// Below this width we use the mobile bottom-nav layout; at or above it we
  /// switch to a desktop web layout with a side navigation rail and a bounded,
  /// centered content column.
  static const double _desktopBreakpoint = 840;

  /// Content never grows wider than this on desktop — keeps line lengths and
  /// tap targets comfortable instead of stretching edge-to-edge.
  static const double _contentMaxWidth = 1120;

  void _onSelect(int i) {
    if (i < _tabNames.length) {
      AnalyticsService.instance.logTabOpen(_tabNames[i]);
    }
    shell.goBranch(i, initialLocation: i == shell.currentIndex);
  }

  List<({IconData icon, String label})> _destinations(AppLocalizations loc) => [
        (icon: Icons.swap_horiz, label: loc.tabConvert),
        (icon: Icons.calculate, label: loc.tabCalculate),
        (icon: Icons.attach_money, label: loc.tabFinance),
        (icon: Icons.build, label: loc.tabTools),
        (icon: Icons.bookmark_outline, label: loc.tabNotes),
      ];

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isDesktop = MediaQuery.sizeOf(context).width >= _desktopBreakpoint;

    final content = Column(
      children: [
        Expanded(child: shell),
        // Banner ad anchored above the bottom nav. Renders nothing for
        // Pro users or when ads are not configured.
        const BannerAdSlot(),
      ],
    );

    return Scaffold(
      backgroundColor: AppColors.bg,
      // Body wrapped in animated gradient + particle grid for the futuristic look.
      body: AnimatedGradientBackground(
        child: Stack(
          children: [
            const Positioned.fill(child: ParticleDotGrid()),
            if (isDesktop)
              SafeArea(
                child: Row(
                  children: [
                    _SideRail(
                      destinations: _destinations(loc),
                      currentIndex: shell.currentIndex,
                      onSelect: _onSelect,
                      extended: MediaQuery.sizeOf(context).width >= 1180,
                    ),
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints:
                              const BoxConstraints(maxWidth: _contentMaxWidth),
                          child: content,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              content,
          ],
        ),
      ),
      bottomNavigationBar: isDesktop
          ? null
          : _BottomNav(
              destinations: _destinations(loc),
              currentIndex: shell.currentIndex,
              onSelect: _onSelect,
            ),
    );
  }
}

/// Mobile bottom navigation — a floating dark bar with rounded top corners and
/// an amber active tab, matching the reference instrument-app chrome.
class _BottomNav extends StatelessWidget {
  final List<({IconData icon, String label})> destinations;
  final int currentIndex;
  final ValueChanged<int> onSelect;

  const _BottomNav({
    required this.destinations,
    required this.currentIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.sheet)),
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
          child: Row(
            children: [
              for (var i = 0; i < destinations.length; i++)
                Expanded(
                  child: _NavItem(
                    icon: destinations[i].icon,
                    label: destinations[i].label,
                    selected: i == currentIndex,
                    onTap: () => onSelect(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.accentPrimary : AppColors.textDim;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.button),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Desktop side navigation rail — the core of the "webapp" layout.
class _SideRail extends StatelessWidget {
  final List<({IconData icon, String label})> destinations;
  final int currentIndex;
  final ValueChanged<int> onSelect;
  final bool extended;

  const _SideRail({
    required this.destinations,
    required this.currentIndex,
    required this.onSelect,
    required this.extended,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        // Translucent sidebar with a right hairline separating it from content.
        border: Border(right: BorderSide(color: AppColors.borderStrong)),
      ),
      child: NavigationRail(
        backgroundColor: AppColors.surface.withValues(alpha: 0.45),
        extended: extended,
        minWidth: 76,
        minExtendedWidth: 200,
        selectedIndex: currentIndex,
        onDestinationSelected: onSelect,
        groupAlignment: -0.85,
        indicatorColor: AppColors.accentPrimary.withValues(alpha: 0.18),
        selectedIconTheme: const IconThemeData(color: AppColors.accentPrimary),
        unselectedIconTheme: const IconThemeData(color: AppColors.textDim),
        selectedLabelTextStyle: const TextStyle(
          color: AppColors.accentPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
        unselectedLabelTextStyle: const TextStyle(
          color: AppColors.textMuted,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        leading: Padding(
          padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFC15C), AppColors.accentPrimary],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentPrimary.withValues(alpha: 0.35),
                  blurRadius: 16,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: const Icon(Icons.calculate_outlined,
                color: Colors.black, size: 22),
          ),
        ),
        destinations: [
          for (final d in destinations)
            NavigationRailDestination(
              icon: Icon(d.icon),
              label: Text(d.label),
            ),
        ],
      ),
    );
  }
}
