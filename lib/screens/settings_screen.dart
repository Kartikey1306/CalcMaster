import 'package:agl_ads/agl_ads.dart';
import 'package:agl_i18n/agl_i18n.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/generated/app_localizations.dart';
import '../monetization/analytics_service.dart';
import '../monetization/monetization_config.dart';
import '../monetization/notification_service.dart';
import '../monetization/premium_provider.dart';
import '../state/auth_provider.dart';
import '../theme/tokens.dart';
import '../widgets/pro_badge.dart';

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

    // Turning the switch on is a request, not a grant. Honour whatever the OS
    // said: with no push transport attached `requestPermission()` reports the
    // stored opt-in, so persist the opt-in first and then reconcile.
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
        'mailto:${MonetizationConfig.supportEmail}?subject=Calculator%20Feedback');
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

  // App Store 5.1.1(v): an app that creates accounts must let the user delete
  // the account in-app. This deletes it on the server; on failure the user
  // stays signed in and sees the real error.
  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This permanently deletes your account from our servers and signs '
          'you out. This cannot be undone.\n\n'
          'Your account is shared across American Group LLC apps, so it is '
          'deleted for every one of them you sign in to with it.\n\n'
          'Notes and settings on this device are not part of your account '
          'and stay on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete permanently',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.deleteAccount();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Your account was permanently deleted.'
            : '${auth.error ?? 'Could not delete your account.'} '
                'You are still signed in.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isPro = context.watch<PremiumProvider>().isPro;
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          tooltip: (AglL10n.of(context)?.actionClose ?? 'Close'),
          icon: const Icon(Icons.close, color: AppColors.text),
          onPressed: () => context.pop(),
        ),
        title: Text(loc.settingsTitle,
            style: const TextStyle(
                color: AppColors.text, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding:
            const EdgeInsets.fromLTRB(Spacing.lg, 0, Spacing.lg, Spacing.xxl),
        children: [
          _SectionHeader(label: (AglL10n.of(context)?.navAccount ?? 'Account')),
          if (auth.isLoggedIn)
            _Tile(
              icon: Icons.person_outline,
              iconColor: AppColors.accentPrimary,
              title: (auth.user?['displayName'] ??
                      auth.user?['email'] ??
                      'Signed in')
                  .toString(),
              subtitle: auth.user?['email']?.toString(),
              trailing: TextButton(
                onPressed: () async {
                  await context.read<AuthProvider>().logout();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Signed out.')),
                  );
                },
                child: Text((AglL10n.of(context)?.authSignOut ?? 'Sign out'),
                    style: TextStyle(color: AppColors.accentPrimary)),
              ),
            ),
          if (auth.isLoggedIn)
            _Tile(
              icon: Icons.delete_forever_outlined,
              iconColor: AppColors.danger,
              title: 'Delete account',
              subtitle: 'Permanently delete your account',
              onTap: _deleteAccount,
            )
          else
            _Tile(
              icon: Icons.login,
              iconColor: AppColors.accentPrimary,
              title: (AglL10n.of(context)?.authSignIn ?? 'Sign in'),
              subtitle: 'Sign in or create an account',
              onTap: () => context.push('/login'),
            ),
          const SizedBox(height: Spacing.lg),
          _SectionHeader(label: loc.settingsSubscription),
          _Tile(
            icon: Icons.workspace_premium,
            iconColor: AppColors.warning,
            title: isPro ? loc.settingsCalcMasterPro : loc.settingsSubscribePro,
            subtitle: isPro
                ? 'Active subscription · thanks!'
                : (MonetizationConfig.adsReady
                    ? 'Remove ads + year-by-year finance breakdowns'
                    : 'Year-by-year loan & investment breakdowns'),
            trailing: isPro
                ? const ProBadge()
                : const Icon(Icons.chevron_right, color: AppColors.textDim),
            onTap: isPro
                ? null
                : () {
                    AnalyticsService.instance.logPaywallShown('settings');
                    context.push('/paywall');
                  },
          ),
          _Tile(
            icon: Icons.restore,
            iconColor: AppColors.text,
            title: loc.settingsRestorePurchases,
            subtitle: 'Already paid on another device?',
            onTap: () async {
              final premium = context.read<PremiumProvider>();
              final ok = await premium.restore();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(ok
                      ? 'Restored.'
                      : (premium.lastError ?? 'No active purchases found.')),
                ),
              );
            },
          ),
          const SizedBox(height: Spacing.lg),
          _SectionHeader(label: loc.settingsPreferences),
          // Only offered once a real push transport is attached: until then
          // the switch could store an opt-in but nothing would ever be sent.
          if (NotificationService.instance.isLive)
            _Tile(
              icon: Icons.notifications_outlined,
              iconColor: AppColors.accentPrimary,
              title: loc.settingsNotifications,
              subtitle: _loaded
                  ? (_notificationsEnabled ? 'Reminders & rate alerts on' : 'Off')
                  : 'Loading…',
              trailing: Switch(
                value: _notificationsEnabled,
                activeTrackColor: AppColors.accentPrimary,
                onChanged: _loaded ? _toggleNotifications : null,
              ),
            ),
          _Tile(
            icon: Icons.language,
            iconColor: AppColors.accentPrimary,
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
          const SizedBox(height: Spacing.lg),
          _SectionHeader(label: loc.settingsHelp),
          _Tile(
            icon: Icons.email_outlined,
            iconColor: AppColors.text,
            title: loc.settingsSendFeedback,
            subtitle: MonetizationConfig.supportEmail,
            onTap: _sendFeedback,
          ),
          _Tile(
            icon: Icons.lock_outline,
            iconColor: AppColors.text,
            title: loc.settingsPrivacyPolicy,
            onTap: () => context.push('/privacy'),
          ),
          if (_privacyOptionsRequired)
            _Tile(
              icon: Icons.privacy_tip_outlined,
              iconColor: AppColors.text,
              title: loc.settingsPrivacyChoices,
              onTap: widget.showPrivacyOptions,
            ),
          _Tile(
            icon: Icons.info_outline,
            iconColor: AppColors.text,
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
      padding: const EdgeInsets.fromLTRB(2, Spacing.md, 0, Spacing.sm),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _Tile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Radii.button),
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.button),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: Spacing.md, vertical: Spacing.md),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(Radii.button),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: iconColor),
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                      if (subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(subtitle!,
                              style: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 13)),
                        ),
                    ],
                  ),
                ),
                trailing ??
                    const Icon(Icons.chevron_right, color: AppColors.textDim),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
