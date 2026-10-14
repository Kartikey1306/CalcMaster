import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/tokens.dart';
import 'package:agl_i18n/agl_i18n.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final c = context.ledger;
    return Scaffold(
      backgroundColor: c.paper,
      appBar: AppBar(
        leading: IconButton(
          tooltip: (AglL10n.of(context)?.actionClose ?? 'Close'),
          icon: const Icon(Icons.close),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: Text(loc.settingsAbout),
      ),
      body: ListView(
        padding:
            const EdgeInsets.fromLTRB(Spacing.lg, 0, Spacing.lg, Spacing.xxl),
        children: [
          const SizedBox(height: Spacing.lg),
          Text(loc.appTitle,
              style: TextStyle(
                  color: c.ink, fontSize: 30, fontWeight: FontWeight.w700)),
          const SizedBox(height: Spacing.xs),
          Text(loc.aboutTagline,
              style: TextStyle(color: c.inkSoft, fontSize: 15)),
          const SizedBox(height: Spacing.lg),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snap) {
              final info = snap.data;
              return _Row(
                label: loc.aboutVersion,
                value: info == null
                    ? '…'
                    : '${info.version} (${info.buildNumber})',
              );
            },
          ),
          _Row(label: loc.settingsRates, value: 'ECB · api.frankfurter.dev'),
          const SizedBox(height: Spacing.xl),
          Text(
            loc.aboutBlurb,
            style: TextStyle(color: c.inkSoft, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final c = context.ledger;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: Spacing.md),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.rule)),
      ),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: c.inkSoft, fontSize: 14)),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Text(value,
                textAlign: TextAlign.end,
                style: TextStyle(
                    fontFamily: Fonts.figures,
                    color: c.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
