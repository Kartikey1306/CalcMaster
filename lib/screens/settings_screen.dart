import 'package:agl_ads/agl_ads.dart';
import 'package:agl_i18n/agl_i18n.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/generated/app_localizations.dart';
import '../monetization/monetization_config.dart';
import '../monetization/notification_service.dart';
import '../sheet/sheets_controller.dart';
import '../state/appearance_provider.dart';
import '../theme/tokens.dart';
import '../widgets/region_pill.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    this.isPrivacyOptionsRequired = AglConsent.isPrivacyOptionsRequired,
    this.showPrivacyOptions = AglConsent.showPrivacyOptions,
  });

  /// Google UMP: whether this user (EEA/UK/CH) must be offered a way to
  /// change their ad-consent choice. Injectable for tests.
  final Future<bool> Function() isPrivacyOptionsRequired;

  /// Reopens Google's privacy-options form. Injectable for tests.
  final Future<void> Function() showPrivacyOptions;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = false;
  bool _loaded = false;
  bool _privacyOptionsRequired = false;

  @override
  void initState() {
    super.initState();
    _hydrate();
    _loadPrivacyOptionsRequirement();
  }

  Future<void> _loadPrivacyOptionsRequirement() async {
    final required = await widget.isPrivacyOptionsRequired();
    if (!mounted) return;
    setState(() => _privacyOptionsRequired = required);
  }

  Future<void> _hydrate() async {
    final on = await NotificationService.instance.isEnabled();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = on;
      _loaded = true;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    if (!value) {
      await NotificationService.instance.setEnabled(enabled: false);
      if (!mounted) return;
      setState(() => _notificationsEnabled = false);
      return;
    }
    await NotificationService.instance.setEnabled(enabled: true);
    final granted = await NotificationService.instance.requestPermission();
    if (!granted) {
      await NotificationService.instance.setEnabled(enabled: false);
    }
    if (!mounted) return;
    setState(() => _notificationsEnabled = granted);
    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notifications are turned off in system settings.'),
        ),
      );
    }
  }

  Future<void> _sendFeedback() async {
    final uri = Uri.parse(
        'mailto:${MonetizationConfig.supportEmail}?subject=CalcMaster%20feedback');
    try {
      await launchUrl(uri);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Email: ${MonetizationConfig.supportEmail}')),
        );
      }
    }
  }

  void _pickRegion() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const RegionPickerSheet(),
    );
  }

  Future<void> _clearRates(SheetsController sheets) async {
    await sheets.clearRateCache();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Cached rates cleared. Dated lines fetch them again.')));
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final c = context.ledger;
    final appearance = context.watch<AppearanceProvider?>();
    final sheets = context.watch<SheetsController?>();
    return Scaffold(
      backgroundColor: c.paper,
      appBar: AppBar(
        leading: IconButton(
          tooltip: (AglL10n.of(context)?.actionClose ?? 'Close'),
          icon: const Icon(Icons.close),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: Text(loc.settingsTitle),
      ),
      body: ListView(
        padding:
            const EdgeInsets.fromLTRB(Spacing.lg, 0, Spacing.lg, Spacing.xxl),
        children: [
          _SectionHeader(label: loc.settingsHomeCurrency),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
            child: Row(children: [
              Expanded(
                child: Text(loc.settingsHomeCurrencyHint,
                    style: TextStyle(color: c.inkSoft, fontSize: 13)),
              ),
              const SizedBox(width: Spacing.sm),
              RegionPill(onTap: _pickRegion),
            ]),
          ),
          if (appearance != null) ...[
            _SectionHeader(label: loc.settingsAppearance),
            for (final (mode, label) in [
              (ThemeMode.system, loc.appearanceSystem),
              (ThemeMode.light, loc.appearanceLedger),
              (ThemeMode.dark, loc.appearanceNight),
            ])
              _Tile(
                icon: switch (mode) {
                  ThemeMode.system => Icons.brightness_auto_outlined,
                  ThemeMode.light => Icons.light_mode_outlined,
                  ThemeMode.dark => Icons.dark_mode_outlined,
                },
                title: label,
                selected: appearance.mode == mode,
                trailing: appearance.mode == mode
                    ? Icon(Icons.check, color: c.primary)
                    : const SizedBox.shrink(),
                onTap: () => appearance.setMode(mode),
              ),
          ],
          _SectionHeader(label: AglL10n.of(context)?.miscLanguage ?? 'Language'),
          _Tile(
            icon: Icons.language,
            title: (AglL10n.of(context)?.miscLanguage ?? 'Language'),
            // The language's own name, so someone who cannot read the
            // current UI language can still tell which one is active.
            subtitle: AglLocales.nativeName(
                Localizations.localeOf(context).languageCode),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => AglLanguageScreen(
                    controller: context.read<AglLocaleController>()),
              ),
            ),
          ),
          // Only offered once a real push transport is attached: until then
          // the switch could store an opt-in but nothing would ever be sent.
          if (NotificationService.instance.isLive)
            _Tile(
              icon: Icons.notifications_outlined,
              title: loc.settingsNotifications,
              subtitle: _loaded ? (_notificationsEnabled ? 'On' : 'Off') : '…',
              trailing: Switch(
                value: _notificationsEnabled,
                onChanged: _loaded ? _toggleNotifications : null,
              ),
            ),
          if (sheets != null) ...[
            _SectionHeader(label: loc.settingsRates),
            _Tile(
              icon: Icons.autorenew,
              title: loc.settingsAutoRates,
              subtitle: loc.settingsAutoRatesBody,
              trailing: Switch(
                key: const Key('auto-update-rates'),
                value: sheets.autoUpdateRates,
                onChanged: sheets.setAutoUpdateRates,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
              child: Text(
                loc.settingsRatesBody(sheets.cachedRateCount),
                style: TextStyle(color: c.inkSoft, fontSize: 13, height: 1.35),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: sheets.cachedRateCount == 0
                    ? null
                    : () => _clearRates(sheets),
                child: Text(loc.settingsClearRateCache),
              ),
            ),
          ],
          _SectionHeader(label: loc.settingsHelp),
          _Tile(
            icon: Icons.help_outline,
            title: loc.helpHowLinesWork,
            onTap: () => context.push('/help'),
          ),
          _Tile(
            icon: Icons.email_outlined,
            title: loc.settingsSendFeedback,
            subtitle: MonetizationConfig.supportEmail,
            onTap: _sendFeedback,
          ),
          _Tile(
            icon: Icons.lock_outline,
            title: loc.settingsPrivacyPolicy,
            onTap: () => context.push('/privacy'),
          ),
          if (_privacyOptionsRequired)
            _Tile(
              icon: Icons.privacy_tip_outlined,
              title: loc.settingsPrivacyChoices,
              onTap: widget.showPrivacyOptions,
            ),
          _Tile(
            icon: Icons.info_outline,
            title: loc.settingsAbout,
            onTap: () => context.push('/about'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, Spacing.xl, 0, Spacing.xs),
      child: Semantics(
        header: true,
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            color: context.ledger.inkSoft,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool selected;

  const _Tile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.ledger;
    return Semantics(
      selected: selected,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.rule)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: c.primary),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            color: c.ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w500)),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(subtitle!,
                            style: TextStyle(color: c.inkSoft, fontSize: 13)),
                      ),
                  ],
                ),
              ),
              trailing ?? Icon(Icons.chevron_right, color: c.inkSoft),
            ],
          ),
        ),
      ),
    );
  }
}
