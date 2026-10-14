import 'package:agl_observability/agl_observability.dart';
import 'package:agl_i18n/agl_i18n.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_router.dart';
import 'l10n/generated/app_localizations.dart';
import 'monetization/ad_service.dart';
import 'monetization/analytics_service.dart';
import 'monetization/tracking_service.dart';
import 'services/error_reporter.dart';
import 'sheet/sheets_controller.dart';
import 'state/appearance_provider.dart';
import 'state/region_provider.dart';
import 'theme/app_theme.dart';

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

  AnalyticsService.instance.bootstrap();
  // Loaded before the first frame so a returning user never sees a flash of
  // the wrong language.
  final locale = AglLocaleController();
  await locale.load();
  // The last sheet is loaded before the first frame too: the app opens
  // straight onto it — no splash, no sign-in, no carousel.
  final region = RegionProvider();
  final sheets = SheetsController(rates: region);
  await sheets.init();
  runApp(CalcMasterApp(
      localeController: locale, region: region, sheets: sheets));
  // The ATT prompt goes up once the first screen has rendered and the app is
  // active (iOS drops a request made any earlier), and the ads SDK — consent,
  // initialisation, every ad request — only starts after it is answered.
  TrackingService.instance
      .requestWhenActive()
      .whenComplete(AdService.instance.bootstrap);
}

class CalcMasterApp extends StatefulWidget {
  final AglLocaleController? localeController;
  final RegionProvider? region;
  final SheetsController? sheets;

  const CalcMasterApp({
    super.key,
    this.localeController,
    this.region,
    this.sheets,
  });

  @override
  State<CalcMasterApp> createState() => _CalcMasterAppState();
}

class _CalcMasterAppState extends State<CalcMasterApp> {
  late final AglLocaleController _locale;
  late final RegionProvider _region;
  late final SheetsController _sheets;
  final _appearance = AppearanceProvider();
  bool _ownsRegion = false;
  bool _ownsSheets = false;

  @override
  void initState() {
    super.initState();
    _locale = widget.localeController ?? AglLocaleController();
    _ownsRegion = widget.region == null;
    _region = widget.region ?? RegionProvider();
    _ownsSheets = widget.sheets == null;
    _sheets = widget.sheets ?? SheetsController(rates: _region);
    if (_ownsSheets) _sheets.init();
  }

  @override
  void dispose() {
    if (_ownsSheets) _sheets.dispose();
    if (_ownsRegion) _region.dispose();
    _appearance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AglLocaleController>.value(value: _locale),
        ChangeNotifierProvider<RegionProvider>.value(value: _region),
        ChangeNotifierProvider<SheetsController>.value(value: _sheets),
        ChangeNotifierProvider<AppearanceProvider>.value(value: _appearance),
      ],
      child: ListenableBuilder(
        listenable: Listenable.merge([_locale, _appearance]),
        builder: (context, _) => MaterialApp.router(
          onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
          theme: buildAppTheme(),
          darkTheme: buildNightTheme(),
          themeMode: _appearance.mode,
          debugShowCheckedModeBanner: false,
          routerConfig: appRouter,
          // Locale, picker and shared vocabulary come from agl_i18n. A null
          // locale means "follow the device", which Flutter resolves against
          // supportedLocales; an explicit choice overrides it and persists.
          locale: _locale.locale,
          supportedLocales: _locale.supportedLocales,
          localizationsDelegates:
              aglLocalizationsDelegates(AppLocalizations.delegate),
        ),
      ),
    );
  }
}
