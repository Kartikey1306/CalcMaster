import 'package:agl_observability/agl_observability.dart';
import 'package:agl_i18n/agl_i18n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_env.dart';
import 'app_router.dart';
import 'l10n/generated/app_localizations.dart';
import 'monetization/ad_service.dart';
import 'monetization/analytics_service.dart';
import 'monetization/premium_provider.dart';
import 'services/supabase_config.dart';
import 'state/auth_provider.dart';
import 'state/notes_provider.dart';
import 'state/region_provider.dart';
import 'theme/app_theme.dart';
import 'theme/tokens.dart';
import 'services/error_reporter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Crash reporting, before anything that could fail. Inactive and
  // harmless until the Firebase config files are added.
  await AglCrash.init(appName: 'CalcMaster');
  // The free Firebase products — Analytics, Performance Monitoring and
  // Remote Config. Same guarantee as the line above: inactive and
  // harmless when Firebase did not initialise.
  await AglInsights.init(appName: 'CalcMaster');
  ErrorReporter.sink = (error, stack, {context}) =>
      AglCrash.recordError(error, stack, reason: context);
  // Capture framework and uncaught async errors. No-op sink by
  // default - see services/error_reporter.dart to attach a crash service.
  ErrorReporter.install();
  // Fail loudly in dev if this binary was built without (or with the
  // wrong) --dart-define-from-file=env/<env>.json. Release only reports.
  AppEnv.validate(urls: const {'SUPABASE_URL': SupabaseConfig.url});

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  ));
  // Supabase handles auth + session persistence. Guarded so a missing/invalid
  // config never hard-blocks app startup (login simply won't be available).
  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
    );
  } catch (e) {
    debugPrint('Supabase init failed: $e');
  }
  // Fire-and-forget bootstrap. Each service no-ops gracefully when its
  // credentials are missing, so this never blocks startup.
  AnalyticsService.instance.bootstrap();
  AdService.instance.bootstrap();
  // Loaded before the first frame so a returning user never sees a flash of
  // the wrong language.
  final locale = AglLocaleController();
  await locale.load();
  runApp(CalcMasterApp(localeController: locale));
}

class CalcMasterApp extends StatelessWidget {
  final AglLocaleController localeController;
  CalcMasterApp({super.key, AglLocaleController? localeController})
      : localeController = localeController ?? AglLocaleController();

  @override
  Widget build(BuildContext context) {
    final base = buildAppTheme();
    final theme = base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: AppColors.text,
        displayColor: AppColors.text,
      ),
    );
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AglLocaleController>.value(
            value: localeController),
        ChangeNotifierProvider(create: (_) => RegionProvider()),
        ChangeNotifierProvider(create: (_) => NotesProvider()),
        ChangeNotifierProvider(create: (_) => PremiumProvider()),
        ChangeNotifierProvider(create: (_) {
          final auth = AuthProvider();
          auth.init();
          return auth;
        }),
      ],
      child: ListenableBuilder(
        listenable: localeController,
        builder: (context, _) => MaterialApp.router(
          onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
          theme: theme,
          debugShowCheckedModeBanner: false,
          routerConfig: appRouter,
          // Locale, picker and shared vocabulary come from agl_i18n. A null
          // locale means "follow the device", which Flutter resolves against
          // supportedLocales; an explicit choice overrides it and persists.
          locale: localeController.locale,
          supportedLocales: localeController.supportedLocales,
          localizationsDelegates:
              aglLocalizationsDelegates(AppLocalizations.delegate),
        ),
      ),
    );
  }
}
