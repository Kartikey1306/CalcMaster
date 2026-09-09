import 'package:calcmaster/l10n/generated/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Flutter falls back to the *first* entry of supportedLocales for any locale
/// it cannot match. gen-l10n orders that list alphabetically unless
/// l10n.yaml sets preferred-supported-locales, which puts Arabic first and
/// silently makes Arabic the fallback for every unmatched device.
///
/// This happened. It is a one-line config regression with no compile error and
/// no visible symptom in a test that only ever pumps English, so it gets its
/// own test.
void main() {
  test('English is first, so it is the fallback for an unmatched locale', () {
    expect(AppLocalizations.supportedLocales.first, const Locale('en'));
  });

  test('an unmatched device locale resolves to English', () {
    final resolved = basicLocaleListResolution(
      const <Locale>[Locale('is')], // Icelandic — deliberately not shipped
      AppLocalizations.supportedLocales,
    );
    expect(resolved, const Locale('en'));
  });
}
