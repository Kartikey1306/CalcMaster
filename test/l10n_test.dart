import 'package:agl_i18n/agl_i18n.dart';
import 'package:calcmaster/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// CalcMaster already had its own ARB catalogue; what adopting agl_i18n adds
/// is a persisted user choice, a picker, and the shared vocabulary. These
/// cover the seam between the two catalogues.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('the app catalogue and the shared one both resolve, and do not '
      'collide', () async {
    final app = await AppLocalizations.delegate.load(const Locale('es'));
    final shared = await AglL10n.delegate.load(const Locale('es'));
    expect(app.appTitle, isNotEmpty);
    expect(shared.actionSave, 'Guardar');
  });

  test('every locale the app ships is one the shared controller offers', () {
    final controller = AglLocaleController();
    final offered =
        controller.supportedLocales.map((l) => l.languageCode).toSet();
    for (final locale in AppLocalizations.supportedLocales) {
      expect(offered, contains(locale.languageCode),
          reason: '${locale.languageCode} is in the app catalogue but the '
              'picker would never offer it');
    }
  });

  test('the delegate order lets this app override a shared string', () {
    final delegates = aglLocalizationsDelegates(AppLocalizations.delegate);
    expect(delegates.first, same(AppLocalizations.delegate));
  });
}
