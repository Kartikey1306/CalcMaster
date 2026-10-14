import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../lib_currency.dart';
import '../state/region_provider.dart';
import '../theme/tokens.dart';

class RegionPill extends StatelessWidget {
  /// Opens the region/currency picker. Wired to a plain tap so it's
  /// discoverable (tap used to silently cycle regions, which was confusing).
  final VoidCallback? onTap;
  const RegionPill({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final region = context.watch<RegionProvider>().region;
    // The pill reads as "🇺🇸 United States · $" without help — a flag emoji and
    // a bare currency symbol. Name it explicitly instead.
    return Semantics(
      container: true,
      button: true,
      label: 'Region: ${region.label}, currency ${region.currency}',
      hint: 'Change region and currency',
      excludeSemantics: true,
      child: _build(context, region),
    );
  }

  Widget _build(BuildContext context, Region region) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        // 48dp minimum: the pill measured 41dp tall, below both the Android
        // and iOS tap-target guidelines. Constrain rather than pad, so the
        // height holds at larger text scales too.
        constraints: BoxConstraints(minHeight: 48),
        alignment: Alignment.center,
        padding:
            EdgeInsets.symmetric(horizontal: Spacing.md, vertical: 8),
        decoration: BoxDecoration(
          color: context.ledger.surface,
          borderRadius: BorderRadius.circular(Radii.chip),
          border: Border.all(color: context.ledger.rule),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on_outlined,
                size: 14, color: context.ledger.ink),
            SizedBox(width: 6),
            Text(region.flag, style: TextStyle(fontSize: 16)),
            SizedBox(width: 6),
            Text(region.label,
                style: TextStyle(
                    color: context.ledger.ink,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
            SizedBox(width: 4),
            Text('·', style: TextStyle(color: context.ledger.inkSoft)),
            SizedBox(width: 4),
            Text(region.symbol,
                style: TextStyle(
                    color: context.ledger.ink,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class RegionPickerSheet extends StatelessWidget {
  const RegionPickerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final current = context.watch<RegionProvider>().regionId;
    return Container(
      padding: EdgeInsets.fromLTRB(
          Spacing.lg, Spacing.lg, Spacing.lg, Spacing.xxxl),
      decoration: BoxDecoration(
        color: context.ledger.surface,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(Radii.sheetTop)),
      ),
      child: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(bottom: Spacing.md),
              decoration: BoxDecoration(
                color: context.ledger.rule,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(loc.regionPickerTitle,
              style: TextStyle(
                  color: context.ledger.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          SizedBox(height: Spacing.md),
          _DetectLocationButton(),
          SizedBox(height: Spacing.sm),
          for (final r in regions)
            InkWell(
              borderRadius: BorderRadius.circular(Radii.button),
              onTap: () {
                context.read<RegionProvider>().setRegion(r.id);
                Navigator.pop(context);
              },
              child: Container(
                padding: EdgeInsets.all(Spacing.md),
                decoration: BoxDecoration(
                  color: r.id == current
                      ? context.ledger.primary.withValues(alpha: 0.08)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(Radii.button),
                ),
                child: Row(
                  children: [
                    Text(r.flag, style: TextStyle(fontSize: 24)),
                    SizedBox(width: Spacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.label,
                              style: TextStyle(
                                  color: context.ledger.ink,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16)),
                          Text('${r.currency} · ${r.symbol}',
                              style: TextStyle(
                                  color: context.ledger.inkSoft, fontSize: 13)),
                        ],
                      ),
                    ),
                    if (r.id == current)
                      Icon(Icons.check, color: context.ledger.primary),
                  ],
                ),
              ),
            ),
        ],
      ),
      ),
    );
  }
}

/// "Detect my location" action inside the picker — uses GPS to set the
/// region/currency, with an inline spinner and result feedback.
class _DetectLocationButton extends StatelessWidget {
  const _DetectLocationButton();

  @override
  Widget build(BuildContext context) {
    final detecting = context.watch<RegionProvider>().detecting;
    return Material(
      color: context.ledger.primary.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(Radii.button),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.button),
        onTap: detecting
            ? null
            : () async {
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);
                final result = await context
                    .read<RegionProvider>()
                    .detectRegionFromLocation();
                if (result == DetectResult.success) {
                  navigator.pop();
                }
                messenger.showSnackBar(SnackBar(
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(milliseconds: 1600),
                  content: Text(switch (result) {
                    DetectResult.success => 'Region set from your location',
                    DetectResult.permissionDenied =>
                      'Location permission denied — pick a region below',
                    DetectResult.noMatch =>
                      'No matching region for your location — pick one below',
                    DetectResult.unavailable =>
                      "Couldn't detect location — pick a region below",
                  }),
                ));
              },
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: Spacing.md, vertical: Spacing.md),
          decoration: BoxDecoration(
            border: Border.all(
                color: context.ledger.primary.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(Radii.button),
          ),
          child: Row(
            children: [
              if (detecting)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: context.ledger.primary),
                )
              else
                Icon(Icons.my_location,
                    size: 18, color: context.ledger.primary),
              SizedBox(width: Spacing.md),
              Text(
                detecting ? 'Detecting…' : 'Detect my location',
                style: TextStyle(
                    color: context.ledger.ink,
                    fontWeight: FontWeight.w600,
                    fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
