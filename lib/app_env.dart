import 'package:flutter/foundation.dart';

/// Which deployment the binary was built for.
enum Environment { dev, staging, prod }

/// Build-time environment selection.
///
/// Values arrive via `--dart-define-from-file=env/<name>.json`; see
/// `env/README.md`. [name] defaults to `prod` so a build that forgets the flag
/// fails closed onto production configuration rather than silently pointing a
/// shipped binary at development infrastructure.
class AppEnv {
  const AppEnv._();

  static const String name = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'prod',
  );

  static Environment get current => switch (name) {
        'dev' => Environment.dev,
        'staging' => Environment.staging,
        _ => Environment.prod,
      };

  static bool get isDev => current == Environment.dev;
  static bool get isStaging => current == Environment.staging;
  static bool get isProd => current == Environment.prod;

  /// Shown in-app and attached to diagnostics so a report can be tied to the
  /// build it came from. Empty in production.
  static String get banner => isProd ? '' : name.toUpperCase();

  /// Reports configuration problems as early as possible.
  ///
  /// Returns the problems found (empty when sound). Throws in debug/profile so
  /// a developer hits it immediately; in release it only logs, because
  /// crashing every user's launch is worse than a misconfigured backend the
  /// app already tolerates. The real guard is build-time —
  /// `test/app_env_test.dart` validates the committed env files in CI.
  static List<String> validate({
    required Map<String, String> urls,
    bool credentialsPresent = false,
  }) {
    final problems = <String>[];
    urls.forEach((key, value) {
      if (value.isEmpty) {
        problems.add('$key is empty');
      } else if (!value.startsWith('https://')) {
        problems.add('$key must be https (got "$value")');
      }
    });
    if (isProd && kReleaseMode && credentialsPresent) {
      problems.add('test credentials are present in a production release');
    }
    if (problems.isNotEmpty) {
      final message = 'Invalid configuration for APP_ENV=$name:\n'
          '${problems.map((p) => '  - $p').join('\n')}\n'
          'Build with --dart-define-from-file=env/<env>.json '
          '(see env/README.md).';
      if (!kReleaseMode) throw StateError(message);
      debugPrint(message);
    }
    return problems;
  }
}
