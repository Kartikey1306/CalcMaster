import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/generated/app_localizations.dart';
import '../monetization/monetization_config.dart';
import '../theme/tokens.dart';
import 'package:agl_i18n/agl_i18n.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: context.ledger.paper,
      appBar: AppBar(
        backgroundColor: context.ledger.paper,
        elevation: 0,
        leading: IconButton(
          tooltip: (AglL10n.of(context)?.actionClose ?? 'Close'),
          icon: Icon(Icons.close, color: context.ledger.ink),
          onPressed: () => context.pop(),
        ),
        title: Text(loc.settingsPrivacyPolicy,
            style: TextStyle(color: context.ledger.ink)),
      ),
      body: ListView(
        padding:
            EdgeInsets.fromLTRB(Spacing.lg, 0, Spacing.lg, Spacing.xxl),
        children: [
          Text(loc.privacyAtGlance,
              style: TextStyle(
                  color: context.ledger.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w700)),
          SizedBox(height: Spacing.md),
          _para(context,
              'CalcMaster keeps your sheets, settings and cached exchange '
              'rates on this device. There is no account.'),
          _para(context,
              'We use anonymous analytics to understand which calculators are most useful so '
              'we can prioritize improvements. No personally identifiable information is collected.'),
          _para(context,
              'Exchange rates come from Frankfurter (api.frankfurter.dev), '
              'which serves European Central Bank reference rates. A rate '
              'request names the two currencies and the date — never your '
              'sheet.'),
          SizedBox(height: Spacing.lg),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.ledger.surface,
              foregroundColor: context.ledger.ink,
              padding: EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () =>
                launchUrl(Uri.parse(MonetizationConfig.privacyPolicyUrl)),
            child: Text(loc.settingsPrivacyPolicy),
          ),
          SizedBox(height: Spacing.sm),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: context.ledger.ink,
              side: BorderSide(color: context.ledger.rule),
              padding: EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () =>
                launchUrl(Uri.parse(MonetizationConfig.termsOfServiceUrl)),
            child: const Text('Terms of Service'),
          ),
        ],
      ),
    );
  }

  Widget _para(BuildContext context, String s) => Padding(
        padding: EdgeInsets.only(bottom: Spacing.md),
        child: Text(s,
            style: TextStyle(
                color: context.ledger.inkSoft, fontSize: 14, height: 1.5)),
      );
}
