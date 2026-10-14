import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../i18n_helpers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../lib_units.dart';
import '../../theme/tokens.dart';
import '../../widgets/banner_ad_slot.dart';

/// One entry in the Tools drawer.
class ToolEntry {
  final String id;
  final String Function(AppLocalizations loc) label;
  final String route;
  final String svg;
  const ToolEntry(this.id, this.label, this.route, this.svg);
}

class ToolGroup {
  final String Function(AppLocalizations loc) title;
  final List<ToolEntry> tools;
  const ToolGroup(this.title, this.tools);
}

/// Every tool, grouped. All of them except BMI end in "Add to sheet".
List<ToolGroup> toolGroups() => [
      ToolGroup((l) => l.toolsGroupMoney, [
        ToolEntry('tip', (l) => l.financeTip, '/tools/tip', 'assets/icons/tip.svg'),
        ToolEntry('discount', (l) => l.financeDiscount, '/tools/discount',
            'assets/icons/discount.svg'),
        ToolEntry('sales-tax', (l) => l.toolSalesTax, '/tools/sales-tax',
            'assets/icons/tax.svg'),
        ToolEntry('tax', (l) => l.toolIncomeTax, '/tools/tax',
            'assets/icons/tax.svg'),
        ToolEntry('paycheck', (l) => l.financePaycheck, '/tools/paycheck',
            'assets/icons/paycheck.svg'),
        ToolEntry('emi', (l) => l.financeEMI, '/tools/emi', 'assets/icons/emi.svg'),
        ToolEntry('compound', (l) => l.financeCompound, '/tools/compound',
            'assets/icons/compound.svg'),
        ToolEntry('unit-price', (l) => l.financeUnitPrice, '/tools/unit-price',
            'assets/icons/unit_price.svg'),
        ToolEntry('currency', (l) => l.financeCurrency, '/tools/currency',
            'assets/icons/currency.svg'),
      ]),
      ToolGroup((l) => l.toolsGroupMeasure, [
        for (final cat in categories)
          ToolEntry('convert-${cat.id}', (_) => '', '/tools/convert/${cat.id}',
              cat.svg),
        ToolEntry('aspect-ratio', (l) => l.toolAspectRatio,
            '/tools/aspect-ratio', 'assets/icons/aspect_ratio.svg'),
      ]),
      ToolGroup((l) => l.toolsGroupTime, [
        ToolEntry('date-diff', (l) => l.toolDateDiff, '/tools/date-diff',
            'assets/icons/date_diff.svg'),
        ToolEntry('age', (l) => l.toolAge, '/tools/age', 'assets/icons/age.svg'),
        ToolEntry('time-zones', (l) => l.toolTimeZones, '/tools/time-zones',
            'assets/icons/time_zones.svg'),
        ToolEntry('calendar', (l) => l.toolCalendar, '/tools/calendar',
            'assets/icons/calendar.svg'),
      ]),
      ToolGroup((l) => l.toolsGroupMaths, [
        ToolEntry('scientific', (l) => l.calcScientific, '/tools/scientific',
            'assets/icons/scientific.svg'),
        ToolEntry('percentage', (l) => l.calcPercentage, '/tools/percentage',
            'assets/icons/percentage.svg'),
        ToolEntry('base', (l) => l.calcBase, '/tools/base', 'assets/icons/base.svg'),
        ToolEntry('fraction', (l) => l.calcFraction, '/tools/fraction',
            'assets/icons/fraction.svg'),
      ]),
      ToolGroup((l) => l.toolsGroupEngineering, [
        ToolEntry('ohm', (l) => l.toolOhm, '/tools/ohm', 'assets/icons/ohm.svg'),
        ToolEntry('adc-dac', (l) => l.toolAdcDac, '/tools/adc-dac',
            'assets/icons/adc_dac.svg'),
        ToolEntry('gps', (l) => l.toolGps, '/tools/gps', 'assets/icons/gps.svg'),
      ]),
      ToolGroup((l) => l.toolsGroupBody, [
        ToolEntry('bmi', (l) => l.toolBmi, '/tools/bmi', 'assets/icons/bmi.svg'),
      ]),
    ];

/// The Tools drawer: a full-height sheet of the thirty tools, grouped Money ·
/// Measure · Time · Maths · Engineering · Body.
class ToolsDrawer extends StatelessWidget {
  const ToolsDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.ledger;
    final loc = AppLocalizations.of(context)!;
    final groups = toolGroups();
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Container(
          margin: const EdgeInsets.only(top: Spacing.sm),
          decoration: BoxDecoration(
            color: c.surface,
            border: Border.all(color: c.rule),
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(Radii.sheetTop)),
          ),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  Spacing.lg, Spacing.sm, Spacing.xs, 0),
              child: Row(children: [
                Expanded(
                  child: Text(loc.toolsTitle,
                      style: TextStyle(
                          color: c.ink,
                          fontSize: 20,
                          fontWeight: FontWeight.w600)),
                ),
                IconButton(
                  tooltip: 'Close tools',
                  icon: const Icon(Icons.close),
                  onPressed: () =>
                      context.canPop() ? context.pop() : context.go('/'),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  Spacing.lg, 0, Spacing.lg, Spacing.sm),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(loc.toolsSubtitle,
                    style: TextStyle(color: c.inkSoft, fontSize: 13)),
              ),
            ),
            Divider(height: 1, color: c.rule),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: Spacing.lg),
                children: [
                  for (final g in groups) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                          Spacing.lg, Spacing.lg, Spacing.lg, Spacing.xs),
                      child: Semantics(
                        header: true,
                        child: Text(g.title(loc).toUpperCase(),
                            style: TextStyle(
                                color: c.inkSoft,
                                fontSize: 12,
                                letterSpacing: 1.1,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                    for (final t in g.tools)
                      _ToolTile(
                        label: t.id.startsWith('convert-')
                            ? localizedCategoryLabel(
                                context, t.id.substring('convert-'.length))
                            : t.label(loc),
                        svg: t.svg,
                        onTap: () => context.push(t.route),
                      ),
                  ],
                ],
              ),
            ),
            const SafeArea(top: false, child: BannerAdSlot()),
          ]),
        ),
      ),
    );
  }
}

class _ToolTile extends StatelessWidget {
  final String label;
  final String svg;
  final VoidCallback onTap;
  const _ToolTile({required this.label, required this.svg, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.ledger;
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.rule)),
        ),
        child: Row(children: [
          SvgPicture.asset(
            svg,
            width: 22,
            height: 22,
            colorFilter: ColorFilter.mode(c.primary, BlendMode.srcIn),
            excludeFromSemantics: true,
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
              child: Text(label,
                  style: TextStyle(color: c.ink, fontSize: 16)),
            ),
          ),
          Icon(Icons.chevron_right, color: c.inkSoft),
        ]),
      ),
    );
  }
}
