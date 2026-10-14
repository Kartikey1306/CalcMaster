import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:calcmaster/theme/app_theme.dart';
import 'package:calcmaster/theme/contrast.dart';
import 'package:calcmaster/theme/tokens.dart';

/// The app's own identity (spec M5) and the removed template tells (M6).
void main() {
  group('Ledger palette', () {
    test('light theme: bottle green on paper', () {
      final t = buildAppTheme();
      expect(t.colorScheme.primary, const Color(0xFF2C5E4F));
      expect(t.scaffoldBackgroundColor, const Color(0xFFF4F0E6));
      expect(t.brightness, Brightness.light);
      expect(t.extension<LedgerColors>()!.result, const Color(0xFF9A4A14));
      expect(t.extension<LedgerColors>()!.error, const Color(0xFFA8322A));
      expect(t.extension<LedgerColors>()!.rule, const Color(0xFFD9D2C1));
      expect(t.extension<LedgerColors>()!.ink, const Color(0xFF22201C));
    });

    test('Night ledger', () {
      final t = buildNightTheme();
      expect(t.scaffoldBackgroundColor, const Color(0xFF161A17));
      expect(t.colorScheme.primary, const Color(0xFF7FB89F));
      expect(t.extension<LedgerColors>()!.surface, const Color(0xFF1F2420));
      expect(t.extension<LedgerColors>()!.ink, const Color(0xFFEAE5D7));
      expect(t.brightness, Brightness.dark);
    });

    test('every text pair is at least 4.5:1', () {
      for (final c in [LedgerColors.ledger, LedgerColors.night]) {
        for (final ground in [c.paper, c.surface]) {
          for (final (name, fg) in [
            ('ink', c.ink),
            ('inkSoft', c.inkSoft),
            ('primary', c.primary),
            ('result', c.result),
            ('error', c.error),
          ]) {
            expect(contrastRatio(fg, ground), greaterThanOrEqualTo(4.5),
                reason: '$name on $ground');
          }
        }
        expect(contrastRatio(c.onPrimary, c.primary), greaterThanOrEqualTo(4.5));
      }
    });

    test('shape: 4 px buttons, 8 px bottom-sheet tops, square rows', () {
      expect(Radii.button, 4);
      expect(Radii.chip, 4);
      expect(Radii.sheetTop, 8);
      expect(Radii.row, 0);
    });
  });

  group('typography', () {
    test('Golos Text and Reddit Mono are bundled with their licences', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      for (final family in ['GolosText', 'RedditMono']) {
        expect(pubspec, contains('family: $family'));
        expect(File('assets/fonts/$family-OFL.txt').existsSync(), isTrue);
        for (final w in [400, 500, 600, 700]) {
          final f = File('assets/fonts/$family-$w.ttf');
          expect(f.existsSync(), isTrue, reason: f.path);
          expect(pubspec, contains('assets/fonts/$family-$w.ttf'));
        }
      }
      expect(buildAppTheme().textTheme.bodyMedium!.fontFamily, Fonts.ui);
    });

    test('google_fonts and Inter are gone', () {
      expect(File('pubspec.yaml').readAsStringSync(),
          isNot(contains('google_fonts')));
      for (final f in _dartFiles('lib')) {
        final src = f.readAsStringSync();
        expect(src.contains("Inter'") || src.contains('GoogleFonts'), isFalse,
            reason: f.path);
      }
    });
  });

  group('template tells (M6)', () {
    test('none of the removed strings is left in lib/', () {
      const banned = [
        'Sign in with Apple',
        'Continue with Google',
        'Welcome Back',
        'BEST VALUE',
        'Ad-free experience',
        'in this build',
        'only calculator you need',
        'supabase',
        'RevenueCat',
        'DUMMY',
        'aiChat',
        // The old world-clock city. (Flutter's generated l10n file names
        // GlobalCupertinoLocalizations, which is not copy.)
        "'Cupertino'",
        'coming soon',
        'not connected',
        'World calculator',
      ];
      for (final f in _dartFiles('lib')) {
        final src = f.readAsStringSync().toLowerCase();
        for (final b in banned) {
          expect(src.contains(b.toLowerCase()), isFalse,
              reason: '"$b" in ${f.path}');
        }
      }
      for (final f in Directory('lib/l10n')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.arb'))) {
        final src = f.readAsStringSync().toLowerCase();
        for (final b in ['aichat', 'auth', 'paywall', 'pill', 'world calculator']) {
          expect(src.contains(b), isFalse, reason: '"$b" in ${f.path}');
        }
      }
    });

    test('the sign-in family and the paywall are deleted', () {
      for (final path in [
        'lib/screens/auth/login_screen.dart',
        'lib/state/auth_provider.dart',
        'lib/services/auth_service.dart',
        'lib/services/supabase_config.dart',
        'lib/app_env.dart',
        'lib/screens/paywall_screen.dart',
        'lib/monetization/premium_provider.dart',
        'lib/monetization/premium_gate.dart',
        'lib/widgets/pro_badge.dart',
        'lib/screens/splash_screen.dart',
        'lib/screens/diagnostics_screen.dart',
        'lib/widgets/affiliate_cta.dart',
        'lib/monetization/affiliate_service.dart',
        'lib/widgets/hub_tile.dart',
        'lib/widgets/glass_card.dart',
        'lib/widgets/glow_text.dart',
        'lib/widgets/animated_gradient_background.dart',
        'lib/widgets/particle_dot_grid.dart',
      ]) {
        expect(File(path).existsSync(), isFalse, reason: path);
      }
      final pubspec = File('pubspec.yaml').readAsStringSync();
      for (final dep in [
        'supabase_flutter',
        'google_sign_in',
        'sign_in_with_apple',
        'crypto:',
        'in_app_purchase',
      ]) {
        expect(pubspec.contains(dep), isFalse, reason: dep);
      }
    });

    test('no tab bar: one stack with the sheet as home', () {
      for (final f in _dartFiles('lib')) {
        final src = f.readAsStringSync();
        expect(
            src.contains('StatefulShellRoute') || src.contains('NavigationBar('),
            isFalse,
            reason: f.path);
      }
    });

    test('the banner is never on the sheet editor', () {
      final editor =
          File('lib/screens/sheet/sheet_screen.dart').readAsStringSync();
      expect(editor.contains('BannerAdSlot'), isFalse);
      expect(File('lib/screens/sheet/sheets_list_screen.dart')
          .readAsStringSync(), contains('BannerAdSlot'));
      expect(File('lib/screens/tools/tools_drawer.dart').readAsStringSync(),
          contains('BannerAdSlot'));
    });

    test('no static or invented exchange rates', () {
      for (final f in _dartFiles('lib')) {
        expect(f.readAsStringSync().contains('staticRates'), isFalse,
            reason: f.path);
      }
    });
  });
}

Iterable<File> _dartFiles(String dir) => Directory(dir)
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'));
