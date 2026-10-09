// App Store 5.1.1(v): an app that creates accounts must delete them in-app.
// Settings > Account > Delete account confirms, then AuthProvider.deleteAccount
// calls public.delete_user() through rpc('delete_user') and signs out only
// after the server call succeeded. These tests drive a real SupabaseClient
// against a fake HTTP client, so the request, the failure path and the cancel
// path are checked without a network.
import 'dart:convert';
import 'dart:io';

import 'package:agl_i18n/agl_i18n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:calcmaster/l10n/generated/app_localizations.dart';
import 'package:calcmaster/monetization/premium_provider.dart';
import 'package:calcmaster/screens/settings_screen.dart';
import 'package:calcmaster/state/auth_provider.dart';

class _OfflineHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      throw const SocketException('network disabled in tests');
}

const _rpcPath = '/rest/v1/rpc/delete_user';

void main() {
  setUpAll(() => HttpOverrides.global = _OfflineHttpOverrides());
  tearDownAll(() => HttpOverrides.global = null);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  late List<http.Request> requests;
  late SupabaseClient client;

  /// A real client with a restored (unexpiring) session for a signed-in user.
  Future<AuthProvider> signedIn(
      http.Response Function(http.Request) handler) async {
    requests = <http.Request>[];
    client = SupabaseClient(
      'https://example.supabase.co',
      'anon-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((req) async {
        requests.add(req);
        final res = handler(req);
        // postgrest reads response.request, which a bare Response lacks.
        return http.Response(res.body, res.statusCode,
            headers: res.headers, request: req);
      }),
    );
    await client.auth.recoverSession(jsonEncode({
      'access_token': 'test-access-token',
      'token_type': 'bearer',
      'refresh_token': 'test-refresh-token',
      'user': {
        'id': '00000000-0000-0000-0000-000000000001',
        'aud': 'authenticated',
        'email': 'tester@example.com',
        'created_at': '2026-01-01T00:00:00Z',
        'app_metadata': <String, dynamic>{},
        'user_metadata': <String, dynamic>{},
      },
    }));
    final auth = AuthProvider(client: client);
    await auth.init();
    return auth;
  }

  http.Response notDeployed(http.Request req) => req.url.path == _rpcPath
      ? http.Response(
          jsonEncode({
            'code': 'PGRST202',
            'message': 'Could not find the function public.delete_user',
          }),
          404,
          headers: {'content-type': 'application/json'},
        )
      : http.Response('', 204);

  Iterable<http.Request> rpcCalls() =>
      requests.where((r) => r.url.path == _rpcPath);

  tearDown(() async => client.dispose());

  group('AuthProvider.deleteAccount', () {
    test('calls delete_user on the server, then signs out', () async {
      final auth = await signedIn((_) => http.Response('', 204));
      expect(auth.isLoggedIn, isTrue);

      expect(await auth.deleteAccount(), isTrue);

      expect(rpcCalls(), hasLength(1));
      expect(rpcCalls().single.method, 'POST');
      expect(auth.isLoggedIn, isFalse);
      expect(auth.user, isNull);
      expect(client.auth.currentSession, isNull);
    });

    test('a server error is reported and the user stays signed in', () async {
      final auth = await signedIn(notDeployed);

      expect(await auth.deleteAccount(), isFalse);

      expect(rpcCalls(), hasLength(1));
      expect(auth.error, contains('Could not find the function'));
      expect(auth.isLoggedIn, isTrue);
      expect(client.auth.currentSession, isNotNull);
    });
  });

  group('Settings > Delete account', () {
    Future<void> pumpSettings(WidgetTester tester, AuthProvider auth) async {
      final locale = AglLocaleController();
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<AglLocaleController>.value(value: locale),
          ChangeNotifierProvider(create: (_) => PremiumProvider()),
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ],
        child: MaterialApp(
          supportedLocales: locale.supportedLocales,
          localizationsDelegates:
              aglLocalizationsDelegates(AppLocalizations.delegate),
          home: const SettingsScreen(),
        ),
      ));
      await tester.pumpAndSettle();
    }

    Future<void> openDialog(WidgetTester tester) async {
      await tester.tap(find.text('Delete account'));
      await tester.pumpAndSettle();
      expect(find.text('Delete account?'), findsOneWidget);
      expect(find.textContaining('permanently deletes'), findsOneWidget);
      expect(find.textContaining('cannot be undone'), findsOneWidget);
      expect(find.textContaining('shared across American Group LLC apps'),
          findsOneWidget);
    }

    testWidgets('cancel keeps the account and sends nothing', (tester) async {
      final auth = (await tester
          .runAsync(() => signedIn((_) => http.Response('', 204))))!;
      await pumpSettings(tester, auth);

      await openDialog(tester);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Delete account?'), findsNothing);
      expect(rpcCalls(), isEmpty);
      expect(auth.isLoggedIn, isTrue);
      expect(find.text('Delete account'), findsOneWidget);
    });

    testWidgets('confirm deletes on the server and signs out', (tester) async {
      final auth = (await tester
          .runAsync(() => signedIn((_) => http.Response('', 204))))!;
      await pumpSettings(tester, auth);

      await openDialog(tester);
      await tester.tap(find.text('Delete permanently'));
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pumpAndSettle();

      expect(rpcCalls(), hasLength(1));
      expect(auth.isLoggedIn, isFalse);
      expect(
          find.text('Your account was permanently deleted.'), findsOneWidget);
      expect(find.text('Delete account'), findsNothing);
    });

    testWidgets('a failure shows the error and keeps the user signed in',
        (tester) async {
      final auth = (await tester.runAsync(() => signedIn(notDeployed)))!;
      await pumpSettings(tester, auth);

      await openDialog(tester);
      await tester.tap(find.text('Delete permanently'));
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pumpAndSettle();

      expect(rpcCalls(), hasLength(1));
      expect(auth.isLoggedIn, isTrue);
      expect(
          find.textContaining('Could not find the function'), findsOneWidget);
      expect(find.textContaining('You are still signed in.'), findsOneWidget);
      expect(find.text('Your account was permanently deleted.'), findsNothing);
      expect(find.text('Delete account'), findsOneWidget);
    });
  });
}
