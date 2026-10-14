import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('zh'),
    Locale('hi'),
    Locale('fr'),
    Locale('ar'),
    Locale('de'),
    Locale('ja'),
    Locale('pt'),
    Locale('ko'),
    Locale('ru'),
    Locale('it')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'CalcMaster'**
  String get appTitle;

  /// No description provided for @categoryDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get categoryDistance;

  /// No description provided for @categoryVolume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get categoryVolume;

  /// No description provided for @categoryWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get categoryWeight;

  /// No description provided for @categoryTemperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get categoryTemperature;

  /// No description provided for @categorySpeed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get categorySpeed;

  /// No description provided for @categoryArea.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get categoryArea;

  /// No description provided for @categoryDataSize.
  ///
  /// In en, this message translates to:
  /// **'Data Size'**
  String get categoryDataSize;

  /// No description provided for @categoryFuelEconomy.
  ///
  /// In en, this message translates to:
  /// **'Fuel Economy'**
  String get categoryFuelEconomy;

  /// No description provided for @categoryPressure.
  ///
  /// In en, this message translates to:
  /// **'Pressure'**
  String get categoryPressure;

  /// No description provided for @categoryEnergy.
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get categoryEnergy;

  /// No description provided for @labelFrom.
  ///
  /// In en, this message translates to:
  /// **'FROM'**
  String get labelFrom;

  /// No description provided for @labelTo.
  ///
  /// In en, this message translates to:
  /// **'TO'**
  String get labelTo;

  /// No description provided for @labelAllConversions.
  ///
  /// In en, this message translates to:
  /// **'ALL CONVERSIONS'**
  String get labelAllConversions;

  /// No description provided for @labelUnitsAvailable.
  ///
  /// In en, this message translates to:
  /// **'{count} units available'**
  String labelUnitsAvailable(int count);

  /// No description provided for @calcScientific.
  ///
  /// In en, this message translates to:
  /// **'Scientific'**
  String get calcScientific;

  /// No description provided for @calcPercentage.
  ///
  /// In en, this message translates to:
  /// **'Percentage'**
  String get calcPercentage;

  /// No description provided for @calcBase.
  ///
  /// In en, this message translates to:
  /// **'Base'**
  String get calcBase;

  /// No description provided for @calcFraction.
  ///
  /// In en, this message translates to:
  /// **'Fraction'**
  String get calcFraction;

  /// No description provided for @financeTax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get financeTax;

  /// No description provided for @financePaycheck.
  ///
  /// In en, this message translates to:
  /// **'Paycheck'**
  String get financePaycheck;

  /// No description provided for @financeTip.
  ///
  /// In en, this message translates to:
  /// **'Tip & Split'**
  String get financeTip;

  /// No description provided for @financeDiscount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get financeDiscount;

  /// No description provided for @financeCompound.
  ///
  /// In en, this message translates to:
  /// **'Compound Interest'**
  String get financeCompound;

  /// No description provided for @financeEMI.
  ///
  /// In en, this message translates to:
  /// **'EMI / Loan'**
  String get financeEMI;

  /// No description provided for @financeCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get financeCurrency;

  /// No description provided for @financeUnitPrice.
  ///
  /// In en, this message translates to:
  /// **'Unit Price'**
  String get financeUnitPrice;

  /// No description provided for @toolGps.
  ///
  /// In en, this message translates to:
  /// **'GPS Coordinates'**
  String get toolGps;

  /// No description provided for @toolOhm.
  ///
  /// In en, this message translates to:
  /// **'Ohm\'s Law'**
  String get toolOhm;

  /// No description provided for @toolBmi.
  ///
  /// In en, this message translates to:
  /// **'BMI'**
  String get toolBmi;

  /// No description provided for @toolDateDiff.
  ///
  /// In en, this message translates to:
  /// **'Date Difference'**
  String get toolDateDiff;

  /// No description provided for @toolTimeZones.
  ///
  /// In en, this message translates to:
  /// **'Time Zones'**
  String get toolTimeZones;

  /// No description provided for @toolAdcDac.
  ///
  /// In en, this message translates to:
  /// **'ADC / DAC'**
  String get toolAdcDac;

  /// No description provided for @toolAge.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get toolAge;

  /// No description provided for @toolAspectRatio.
  ///
  /// In en, this message translates to:
  /// **'Aspect Ratio'**
  String get toolAspectRatio;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsHelp.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get settingsHelp;

  /// No description provided for @settingsSendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get settingsSendFeedback;

  /// No description provided for @settingsPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get settingsPrivacyPolicy;

  /// No description provided for @settingsPrivacyChoices.
  ///
  /// In en, this message translates to:
  /// **'Privacy choices'**
  String get settingsPrivacyChoices;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About CalcMaster'**
  String get settingsAbout;

  /// No description provided for @regionPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Select region'**
  String get regionPickerTitle;

  /// No description provided for @actionUseMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get actionUseMyLocation;

  /// No description provided for @actionLocating.
  ///
  /// In en, this message translates to:
  /// **'Locating…'**
  String get actionLocating;

  /// No description provided for @actionPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied'**
  String get actionPermissionDenied;

  /// No description provided for @aboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get aboutVersion;

  /// No description provided for @aboutBlurb.
  ///
  /// In en, this message translates to:
  /// **'CalcMaster works out real-life sums on ruled sheets: arithmetic, percentages, units, and currencies at the European Central Bank reference rate for the day you name. Thirty tools add their results to your sheet. Sheets stay on your device; there is no account.'**
  String get aboutBlurb;

  /// No description provided for @privacyAtGlance.
  ///
  /// In en, this message translates to:
  /// **'Privacy at a glance'**
  String get privacyAtGlance;

  /// No description provided for @labelFilingStatus.
  ///
  /// In en, this message translates to:
  /// **'Filing status'**
  String get labelFilingStatus;

  /// No description provided for @labelCompoundFreq.
  ///
  /// In en, this message translates to:
  /// **'Compounding frequency'**
  String get labelCompoundFreq;

  /// No description provided for @labelInputBase.
  ///
  /// In en, this message translates to:
  /// **'Input base'**
  String get labelInputBase;

  /// No description provided for @labelOperator.
  ///
  /// In en, this message translates to:
  /// **'Operator'**
  String get labelOperator;

  /// No description provided for @labelPerUnit.
  ///
  /// In en, this message translates to:
  /// **'Per unit'**
  String get labelPerUnit;

  /// No description provided for @labelXofY.
  ///
  /// In en, this message translates to:
  /// **'X% of Y'**
  String get labelXofY;

  /// No description provided for @labelXisWhatPctOfY.
  ///
  /// In en, this message translates to:
  /// **'X is what % of Y'**
  String get labelXisWhatPctOfY;

  /// No description provided for @labelPctChangeXtoY.
  ///
  /// In en, this message translates to:
  /// **'% change from X to Y'**
  String get labelPctChangeXtoY;

  /// No description provided for @toolsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get toolsTitle;

  /// No description provided for @toolsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Every result can go onto your sheet — except BMI.'**
  String get toolsSubtitle;

  /// No description provided for @toolsGroupMoney.
  ///
  /// In en, this message translates to:
  /// **'Money'**
  String get toolsGroupMoney;

  /// No description provided for @toolsGroupMeasure.
  ///
  /// In en, this message translates to:
  /// **'Measure'**
  String get toolsGroupMeasure;

  /// No description provided for @toolsGroupTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get toolsGroupTime;

  /// No description provided for @toolsGroupMaths.
  ///
  /// In en, this message translates to:
  /// **'Maths'**
  String get toolsGroupMaths;

  /// No description provided for @toolsGroupEngineering.
  ///
  /// In en, this message translates to:
  /// **'Engineering'**
  String get toolsGroupEngineering;

  /// No description provided for @toolsGroupBody.
  ///
  /// In en, this message translates to:
  /// **'Body'**
  String get toolsGroupBody;

  /// No description provided for @toolSalesTax.
  ///
  /// In en, this message translates to:
  /// **'Sales tax / VAT'**
  String get toolSalesTax;

  /// No description provided for @toolIncomeTax.
  ///
  /// In en, this message translates to:
  /// **'Income tax estimate'**
  String get toolIncomeTax;

  /// No description provided for @toolCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get toolCalendar;

  /// No description provided for @settingsHomeCurrency.
  ///
  /// In en, this message translates to:
  /// **'Home currency & region'**
  String get settingsHomeCurrency;

  /// No description provided for @settingsHomeCurrencyHint.
  ///
  /// In en, this message translates to:
  /// **'The currency the tools use, and the tax tables they apply.'**
  String get settingsHomeCurrencyHint;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @appearanceSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get appearanceSystem;

  /// No description provided for @appearanceLedger.
  ///
  /// In en, this message translates to:
  /// **'Ledger'**
  String get appearanceLedger;

  /// No description provided for @appearanceNight.
  ///
  /// In en, this message translates to:
  /// **'Night ledger'**
  String get appearanceNight;

  /// No description provided for @settingsRates.
  ///
  /// In en, this message translates to:
  /// **'Rates'**
  String get settingsRates;

  /// No description provided for @settingsRatesBody.
  ///
  /// In en, this message translates to:
  /// **'Reference rates from the European Central Bank. Cached rates: {count}'**
  String settingsRatesBody(int count);

  /// No description provided for @settingsClearRateCache.
  ///
  /// In en, this message translates to:
  /// **'Clear cache'**
  String get settingsClearRateCache;

  /// No description provided for @helpHowLinesWork.
  ///
  /// In en, this message translates to:
  /// **'How lines work'**
  String get helpHowLinesWork;

  /// No description provided for @aboutTagline.
  ///
  /// In en, this message translates to:
  /// **'Sums on ruled sheets, with ECB rates on the day'**
  String get aboutTagline;

  /// No description provided for @sheetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Sheets'**
  String get sheetsTitle;

  /// No description provided for @sheetsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search titles and lines'**
  String get sheetsSearchHint;

  /// No description provided for @sheetsNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get sheetsNew;

  /// No description provided for @sheetsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No sheets yet. Start one — every line works out as you type.'**
  String get sheetsEmpty;

  /// No description provided for @sheetNewSheet.
  ///
  /// In en, this message translates to:
  /// **'New sheet'**
  String get sheetNewSheet;

  /// No description provided for @sheetShareText.
  ///
  /// In en, this message translates to:
  /// **'Share as text'**
  String get sheetShareText;

  /// No description provided for @sheetExportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get sheetExportCsv;

  /// No description provided for @sheetCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy to clipboard'**
  String get sheetCopy;

  /// No description provided for @sheetReprice.
  ///
  /// In en, this message translates to:
  /// **'Re-price'**
  String get sheetReprice;

  /// No description provided for @sheetRatesAsOf.
  ///
  /// In en, this message translates to:
  /// **'Rates as of {date}'**
  String sheetRatesAsOf(String date);

  /// No description provided for @sheetTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get sheetTotal;

  /// No description provided for @sheetAddToSheet.
  ///
  /// In en, this message translates to:
  /// **'Add to sheet'**
  String get sheetAddToSheet;

  /// No description provided for @sheetRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get sheetRename;

  /// No description provided for @sheetDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get sheetDuplicate;

  /// No description provided for @sheetDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get sheetDelete;

  /// No description provided for @sheetUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get sheetUndo;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'ar',
        'de',
        'en',
        'es',
        'fr',
        'hi',
        'it',
        'ja',
        'ko',
        'pt',
        'ru',
        'zh'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
