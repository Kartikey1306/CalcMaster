import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:calcmaster/app_env.dart';

/// Build-time guard for the environment configuration.
///
/// AppEnv.validate() deliberately does not throw in release, so this is where a
/// bad `env/*.json` is actually caught. It runs in CI on every push.
void main() {
  Map<String, dynamic> load(String env) =>
      jsonDecode(File('env/$env.json').readAsStringSync())
          as Map<String, dynamic>;

  const envs = ['dev', 'staging', 'prod'];
  const required = [
    "API_BASE_URL",
    "GOOGLE_IOS_CLIENT_ID",
    "GOOGLE_SERVER_CLIENT_ID",
    "SUPABASE_ANON_KEY",
    "SUPABASE_URL"
  ];
  const secretKeys = [
    "ADMIN_EMAIL",
    "ADMIN_PASSWORD",
    "DEV_EMAIL",
    "DEV_PASSWORD",
    "QA_EMAIL",
    "QA_PASSWORD"
  ];

  for (final env in envs) {
    group('env/$env.json', () {
      test('exists, valid JSON, APP_ENV matches the file name', () {
        expect(File('env/$env.json').existsSync(), isTrue);
        expect(load(env)['APP_ENV'], env);
      });

      test('declares every configuration key', () {
        final cfg = load(env);
        for (final key in required) {
          expect(cfg.containsKey(key), isTrue, reason: '$key is missing');
        }
      });

      test('every http(s) value is https', () {
        load(env).forEach((key, value) {
          if (value is String && value.startsWith('http')) {
            expect(value.startsWith('https://'), isTrue,
                reason: '$key must be https, got $value');
          }
        });
      });

      test('carries no credentials or secrets', () {
        final cfg = load(env);
        for (final key in secretKeys) {
          expect(cfg.containsKey(key), isFalse,
              reason: '$key must come from the gitignored env/secrets.json, '
                  'never a committed env file.');
        }
      });
    });
  }

  test('AppEnv defaults to prod when APP_ENV is not supplied', () {
    expect(AppEnv.name, 'prod');
    expect(AppEnv.isProd, isTrue);
    expect(AppEnv.banner, isEmpty);
  });

  test('validate() rejects empty and non-https URLs', () {
    expect(() => AppEnv.validate(urls: {'X': ''}), throwsStateError);
    expect(() => AppEnv.validate(urls: {'X': 'http://insecure.example'}),
        throwsStateError);
  });

  test('validate() accepts a sound configuration', () {
    expect(AppEnv.validate(urls: {'X': 'https://ok.example'}), isEmpty);
  });

  test('every fromEnvironment key in lib/ is declared somewhere', () {
    final keys = <String>{};
    for (final f in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      keys.addAll(RegExp(r"fromEnvironment\(\s*'([A-Z_0-9]+)'")
          .allMatches(f.readAsStringSync())
          .map((m) => m.group(1)!));
    }
    const harness = {'APP_ENV', 'FLUTTER_TEST', 'FIREBASE_CONFIGURED'};
    final known = {...required, ...secretKeys, ...harness};
    expect(keys.difference(known), isEmpty,
        reason: 'Undocumented dart-define key(s). Add them to env/*.json '
            '(or env/secrets.example.json) and to env/README.md.');
  });
}
