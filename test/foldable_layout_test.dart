import 'dart:io';

import 'package:agl_i18n/agl_i18n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calcmaster/app_router.dart';
import 'package:calcmaster/l10n/generated/app_localizations.dart';
import 'package:calcmaster/monetization/premium_provider.dart';
import 'package:calcmaster/state/auth_provider.dart';
import 'package:calcmaster/state/notes_provider.dart';
import 'package:calcmaster/state/region_provider.dart';
import 'package:calcmaster/theme/app_theme.dart';

/// Foldable / dual-screen survival.
///
/// The defining property of a folding phone is not a new screen size: it is
/// that the window *changes size while the app is running*, and that it takes
/// aspect ratios no current iPhone has — near-square when unfolded, very tall
/// and narrow when folded. A layout that assumes a fixed width, or that only
/// ever sees 9:19.5, breaks visibly on the unfold.
///
/// Apple ships no simulator for this, so these widget tests *are* the
/// verification. Every screen is pumped at each window size and asserted to
/// produce no RenderFlex overflow and no layout exception (both surface
/// through `tester.takeException()` in debug).
///
/// Blocks real sockets: `RegionProvider` refreshes FX rates on construction and
/// that live request would outlive the test body. `fetchLatestRates()` already
/// falls back to the bundled static rates, so refusing to connect exercises the
/// offline path rather than papering over anything.
class _OfflineHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      throw const SocketException('network disabled in tests');
}

/// Logical window sizes a folding iPhone passes through.
const _windows = <String, Size>{
  // Folded / cover display: tall and narrow.
  'folded 360x840': Size(360, 840),
  // Unfolded, near-square (aspect ~0.87) — no current iPhone is this shape.
  'unfolded 730x840': Size(730, 840),
  // Unfolded, rotated.
  'unfolded landscape 840x730': Size(840, 730),
  // An intermediate frame seen *during* the unfold animation.
  'mid-resize 540x840': Size(540, 840),
  // Smallest supported window.
  'smallest 320x690': Size(320, 690),
};

/// Every primary destination, addressed by route so the real router, the real
/// shell chrome and the real providers are all in play.
const _tabRoutes = <String>[
  '/convert',
  '/calculate',
  '/finance',
  '/tools',
  '/notes',
];

const _detailRoutes = <String>[
  '/convert/distance',
  '/convert/temperature',
  '/convert/dataSize',
  '/calculate/standard',
  '/calculate/scientific',
  '/calculate/percentage',
  '/calculate/base',
  '/calculate/fraction',
  '/finance/tax',
  '/finance/tip',
  '/finance/discount',
  '/finance/compound',
  '/finance/emi',
  '/finance/currency',
  '/finance/unit-price',
  '/tools/gps',
  '/tools/ohm',
  '/tools/bmi',
  '/tools/date-diff',
  '/tools/time-zones',
  '/tools/adc-dac',
  '/tools/age',
  '/tools/aspect-ratio',
  '/tools/calendar',
  '/settings',
  '/paywall',
  '/privacy',
  '/about',
  '/login',
  '/ai-chat',
];

void main() {
  setUpAll(() => HttpOverrides.global = _OfflineHttpOverrides());
  tearDownAll(() => HttpOverrides.global = null);
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // `appRouter` is a top-level singleton shared by every test in this file,
    // so it remembers wherever the previous test navigated to. Put it back on
    // the first tab so each test boots the app the way a cold launch does.
    appRouter.go('/convert');
  });

  Widget buildApp({TextScaler? scaler}) {
    final locale = AglLocaleController();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AglLocaleController>.value(value: locale),
        ChangeNotifierProvider(create: (_) => RegionProvider()),
        ChangeNotifierProvider(create: (_) => NotesProvider()),
        ChangeNotifierProvider(create: (_) => PremiumProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp.router(
        theme: buildAppTheme(),
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
        // Same delegate set as `main.dart` — settings reads `AglL10n.of`.
        supportedLocales: locale.supportedLocales,
        localizationsDelegates:
            aglLocalizationsDelegates(AppLocalizations.delegate),
        builder: scaler == null
            ? null
            : (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(textScaler: scaler),
                  child: child!,
                ),
      ),
    );
  }

  /// Sizes the test window in *logical* pixels.
  void resize(WidgetTester tester, Size logical) {
    tester.view.devicePixelRatio = 3.0;
    tester.view.physicalSize = logical * 3.0;
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
  }

  /// Navigates to [route] and settles. Returns whatever the frame threw.
  Future<Object?> visit(WidgetTester tester, String route) async {
    appRouter.go(route);
    await settle(tester);
    return tester.takeException();
  }

  group('foldable window sizes', () {
    _windows.forEach((name, size) {
      testWidgets('every tab lays out at $name', (tester) async {
        resize(tester, size);
        addTearDown(tester.view.reset);

        await tester.pumpWidget(buildApp());
        await settle(tester);
        expect(tester.takeException(), isNull,
            reason: 'app boot overflowed at $name');

        for (final route in _tabRoutes) {
          expect(await visit(tester, route), isNull,
              reason: '$route overflowed at $name');
        }
      });

      testWidgets('every detail screen lays out at $name', (tester) async {
        resize(tester, size);
        addTearDown(tester.view.reset);

        await tester.pumpWidget(buildApp());
        await settle(tester);
        tester.takeException();

        for (final route in _detailRoutes) {
          expect(await visit(tester, route), isNull,
              reason: '$route overflowed at $name');
        }
        // Leave the shared router on a tab route for the next test.
        await visit(tester, '/convert');
      });
    });
  });

  group('large text plus a fold', () {
    // A fold *and* large type is where text layouts actually break, so the
    // busiest screens get a second pass at 1.6x.
    const busiest = <String>[
      '/convert',
      '/convert/distance',
      '/calculate',
      '/calculate/scientific',
      '/finance/currency',
      '/tools',
      '/notes',
      '/settings',
    ];

    _windows.forEach((name, size) {
      testWidgets('the busiest screens survive 1.6x text at $name',
          (tester) async {
        resize(tester, size);
        addTearDown(tester.view.reset);

        await tester.pumpWidget(buildApp(scaler: const TextScaler.linear(1.6)));
        await settle(tester);
        expect(tester.takeException(), isNull,
            reason: 'app boot overflowed at 1.6x text, $name');

        for (final route in busiest) {
          expect(await visit(tester, route), isNull,
              reason: '$route overflowed at 1.6x text, $name');
        }
        await visit(tester, '/convert');
      });
    });
  });

  group('resizing while running', () {
    // The actual foldable event: the window changes size under a live widget
    // tree. Anything that captured a width once at startup breaks here and
    // nowhere else.
    testWidgets('unfolding and refolding never throws', (tester) async {
      addTearDown(tester.view.reset);
      resize(tester, _windows['folded 360x840']!);

      await tester.pumpWidget(buildApp());
      await settle(tester);
      expect(tester.takeException(), isNull);

      const sequence = <String>[
        'folded 360x840',
        'mid-resize 540x840',
        'unfolded 730x840',
        'unfolded landscape 840x730',
        'unfolded 730x840',
        'mid-resize 540x840',
        'folded 360x840',
        'smallest 320x690',
      ];

      for (final route in _tabRoutes) {
        expect(await visit(tester, route), isNull, reason: route);
        for (final step in sequence) {
          resize(tester, _windows[step]!);
          await settle(tester);
          expect(tester.takeException(), isNull,
              reason: 'resizing $route to $step threw');
        }
      }
    });

    testWidgets('the nav chrome follows the live window width', (tester) async {
      addTearDown(tester.view.reset);
      resize(tester, _windows['folded 360x840']!);

      await tester.pumpWidget(buildApp());
      await settle(tester);
      await visit(tester, '/convert');

      // Folded: bottom bar, no rail.
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.byType(BottomNavigationBar), findsNothing,
          reason: 'this app uses a custom bottom bar, not the Material one');
      final foldedBottom = tester
          .widget<Scaffold>(find.byType(Scaffold).first)
          .bottomNavigationBar;
      expect(foldedBottom, isNotNull, reason: 'folded should show a bottom bar');

      // Unfold *without* rebuilding the app: the rail must appear anyway.
      resize(tester, _windows['unfolded landscape 840x730']!);
      await settle(tester);
      expect(tester.takeException(), isNull);
      expect(find.byType(NavigationRail), findsOneWidget,
          reason: 'the width breakpoint must react to the live window, not to '
              'a value captured at startup');

      // Refold: back to the bottom bar.
      resize(tester, _windows['folded 360x840']!);
      await settle(tester);
      expect(tester.takeException(), isNull);
      expect(find.byType(NavigationRail), findsNothing);
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold).first).bottomNavigationBar,
        isNotNull,
      );
    });
  });
}
