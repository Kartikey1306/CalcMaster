import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screens/about_screen.dart';
import 'screens/calculate/calculate_screens.dart';
import 'screens/convert_detail.dart';
import 'screens/finance/finance_screens.dart';
import 'screens/help_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/sheet/sheet_screen.dart';
import 'screens/sheet/sheets_list_screen.dart';
import 'screens/tools/calendar_screen.dart';
import 'screens/tools/tools_drawer.dart';
import 'screens/tools/tools_screens.dart';

/// The Tools drawer slides up over the sheet as a full-height sheet.
Page<void> _drawerPage(GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      opaque: false,
      barrierColor: Colors.black26,
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      transitionsBuilder: (context, animation, _, child) => SlideTransition(
        position: Tween(begin: const Offset(0, 1), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutCubic))
            .animate(animation),
        child: child,
      ),
    );

GoRoute _tool(String path, Widget Function(GoRouterState s) build) =>
    GoRoute(path: path, builder: (_, s) => build(s));

/// One stack: the sheet is home; the Sheets list, the Tools drawer and
/// Settings open over it. There is no tab bar.
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const SheetScreen(),
      routes: [
        GoRoute(path: 'sheets', builder: (_, __) => const SheetsListScreen()),
        GoRoute(path: 'help', builder: (_, __) => const HelpScreen()),
        GoRoute(path: 'settings', builder: (_, __) => const SettingsScreen()),
        GoRoute(path: 'privacy', builder: (_, __) => const PrivacyPolicyScreen()),
        GoRoute(path: 'about', builder: (_, __) => const AboutScreen()),
        GoRoute(
          path: 'tools',
          pageBuilder: (_, state) => _drawerPage(state, const ToolsDrawer()),
          routes: [
            // Money
            _tool('tip', (_) => const TipCalc()),
            _tool('discount', (_) => const DiscountCalc()),
            _tool('sales-tax', (_) => const TaxCalc(initialMode: 'sales')),
            _tool('tax', (_) => const TaxCalc()),
            _tool('paycheck', (_) => const PaycheckCalc()),
            _tool('emi', (_) => const EmiCalc()),
            _tool('compound', (_) => const CompoundCalc()),
            _tool('unit-price', (_) => const UnitPriceCalc()),
            _tool('currency', (_) => const CurrencyCalc()),
            // Measure
            _tool('convert/:id',
                (s) => ConvertDetail(categoryId: s.pathParameters['id']!)),
            _tool('aspect-ratio', (_) => const AspectRatioCalc()),
            // Time
            _tool('date-diff', (_) => const DateDiffCalc()),
            _tool('age', (_) => const AgeCalc()),
            _tool('time-zones', (_) => const TimeZonesScreen()),
            _tool('calendar', (_) => const CalendarToolScreen()),
            // Maths
            _tool('scientific', (_) => const ScientificCalc()),
            _tool('percentage', (_) => const PercentageCalc()),
            _tool('base', (_) => const BaseCalc()),
            _tool('fraction', (_) => const FractionCalc()),
            // Engineering
            _tool('ohm', (_) => const OhmCalc()),
            _tool('adc-dac', (_) => const AdcDacCalc()),
            _tool('gps', (_) => const GpsCalc()),
            // Body — a calculator only: no Add to sheet, nothing stored.
            _tool('bmi', (_) => const BmiCalc()),
          ],
        ),
      ],
    ),
  ],
);
