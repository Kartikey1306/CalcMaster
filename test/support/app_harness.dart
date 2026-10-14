import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calcmaster/app_router.dart';
import 'package:calcmaster/main.dart';
import 'package:calcmaster/state/region_provider.dart';

/// Blocks real sockets. `RegionProvider` refreshes ECB rates on construction;
/// refusing to connect exercises the offline path instead of the network.
class OfflineHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      throw const SocketException('network disabled in tests');
}

/// An HTTP client that is always offline.
http.Client offlineClient() =>
    MockClient((_) async => throw http.ClientException('offline'));

/// Standard setup for full-app widget tests: no network, empty storage (or
/// [prefs]), the shared router back at home.
void setUpApp([Map<String, Object> Function()? prefs]) {
  setUpAll(() => HttpOverrides.global = OfflineHttpOverrides());
  tearDownAll(() => HttpOverrides.global = null);
  setUp(() {
    SharedPreferences.setMockInitialValues(prefs?.call() ?? {});
    appRouter.go('/');
  });
}

/// The real app, with its real router and providers. Pass [region] to
/// control the rates source.
Widget testApp({RegionProvider? region, Key? key}) => CalcMasterApp(
    key: key, region: region ?? RegionProvider(client: offlineClient()));

/// Large text, the way a user sets it in system settings.
void textScale(WidgetTester tester, double scale) {
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

Future<void> settle(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pumpAndSettle(const Duration(milliseconds: 100));
}

/// Pumps long enough for the sheet's autosave to run.
Future<void> letAutosave(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pumpAndSettle();
}

void phone(WidgetTester tester, [Size logical = const Size(390, 844)]) {
  tester.view.devicePixelRatio = 3.0;
  tester.view.physicalSize = logical * 3.0;
  addTearDown(tester.view.reset);
}
