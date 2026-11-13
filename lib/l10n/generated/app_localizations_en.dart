// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'CalcMaster';

  @override
  String get categoryDistance => 'Distance';

  @override
  String get categoryVolume => 'Volume';

  @override
  String get categoryWeight => 'Weight';

  @override
  String get categoryTemperature => 'Temperature';

  @override
  String get categorySpeed => 'Speed';

  @override
  String get categoryArea => 'Area';

  @override
  String get categoryDataSize => 'Data Size';

  @override
  String get categoryFuelEconomy => 'Fuel Economy';

  @override
  String get categoryPressure => 'Pressure';

  @override
  String get categoryEnergy => 'Energy';

  @override
  String get labelFrom => 'FROM';

  @override
  String get labelTo => 'TO';

  @override
  String get labelAllConversions => 'ALL CONVERSIONS';

  @override
  String labelUnitsAvailable(int count) {
    return '$count units available';
  }

  @override
  String get calcScientific => 'Scientific';

  @override
  String get calcPercentage => 'Percentage';

  @override
  String get calcBase => 'Base';

  @override
  String get calcFraction => 'Fraction';

  @override
  String get financeTax => 'Tax';

  @override
  String get financePaycheck => 'Paycheck';

  @override
  String get financeTip => 'Tip & Split';

  @override
  String get financeDiscount => 'Discount';

  @override
  String get financeCompound => 'Compound Interest';

  @override
  String get financeEMI => 'EMI / Loan';

  @override
  String get financeCurrency => 'Currency';

  @override
  String get financeUnitPrice => 'Unit Price';

  @override
  String get toolGps => 'GPS Coordinates';

  @override
  String get toolOhm => 'Ohm\'s Law';

  @override
  String get toolBmi => 'BMI';

  @override
  String get toolDateDiff => 'Date Difference';

  @override
  String get toolTimeZones => 'Time Zones';

  @override
  String get toolAdcDac => 'ADC / DAC';

  @override
  String get toolAge => 'Age';

  @override
  String get toolAspectRatio => 'Aspect Ratio';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsHelp => 'Help';

  @override
  String get settingsSendFeedback => 'Send feedback';

  @override
  String get settingsPrivacyPolicy => 'Privacy policy';

  @override
  String get settingsPrivacyChoices => 'Privacy choices';

  @override
  String get settingsAbout => 'About CalcMaster';

  @override
  String get regionPickerTitle => 'Select region';

  @override
  String get actionUseMyLocation => 'Use my location';

  @override
  String get actionLocating => 'Locating…';

  @override
  String get actionPermissionDenied => 'Location permission denied';

  @override
  String get aboutVersion => 'Version';

  @override
  String get aboutBlurb =>
      'CalcMaster works out real-life sums on ruled sheets: arithmetic, percentages, units, and currencies at the European Central Bank reference rate for the day you name. Thirty tools add their results to your sheet. Sheets stay on your device; there is no account.';

  @override
  String get privacyAtGlance => 'Privacy at a glance';

  @override
  String get labelFilingStatus => 'Filing status';

  @override
  String get labelCompoundFreq => 'Compounding frequency';

  @override
  String get labelInputBase => 'Input base';

  @override
  String get labelOperator => 'Operator';

  @override
  String get labelPerUnit => 'Per unit';

  @override
  String get labelXofY => 'X% of Y';

  @override
  String get labelXisWhatPctOfY => 'X is what % of Y';

  @override
  String get labelPctChangeXtoY => '% change from X to Y';

  @override
  String get toolsTitle => 'Tools';

  @override
  String get toolsSubtitle =>
      'Every result can go onto your sheet — except BMI.';

  @override
  String get toolsGroupMoney => 'Money';

  @override
  String get toolsGroupMeasure => 'Measure';

  @override
  String get toolsGroupTime => 'Time';

  @override
  String get toolsGroupMaths => 'Maths';

  @override
  String get toolsGroupEngineering => 'Engineering';

  @override
  String get toolsGroupBody => 'Body';

  @override
  String get toolSalesTax => 'Sales tax / VAT';

  @override
  String get toolIncomeTax => 'Income tax estimate';

  @override
  String get toolCalendar => 'Calendar';

  @override
  String get settingsHomeCurrency => 'Home currency & region';

  @override
  String get settingsHomeCurrencyHint =>
      'The currency the tools use, and the tax tables they apply.';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get appearanceSystem => 'System';

  @override
  String get appearanceLedger => 'Ledger';

  @override
  String get appearanceNight => 'Night ledger';

  @override
  String get settingsRates => 'Rates';

  @override
  String settingsRatesBody(int count) {
    return 'Reference rates from the European Central Bank. Cached rates: $count';
  }

  @override
  String get settingsClearRateCache => 'Clear cache';

  @override
  String get settingsAutoRates => 'Keep sheets at the latest rate';

  @override
  String get settingsAutoRatesBody =>
      'Checks for new ECB rates every 30 minutes and when you open the app, and moves lines to them. Off: each line keeps the rate it was first worked out at.';

  @override
  String get helpHowLinesWork => 'How lines work';

  @override
  String get aboutTagline => 'Sums on ruled sheets, with ECB rates on the day';

  @override
  String get sheetsTitle => 'Sheets';

  @override
  String get sheetsSearchHint => 'Search titles and lines';

  @override
  String get sheetsNew => 'New';

  @override
  String get sheetsEmpty =>
      'No sheets yet. Start one — every line works out as you type.';

  @override
  String get sheetNewSheet => 'New sheet';

  @override
  String get sheetShareText => 'Share as text';

  @override
  String get sheetExportCsv => 'Export CSV';

  @override
  String get sheetCopy => 'Copy to clipboard';

  @override
  String get sheetReprice => 'Re-price';

  @override
  String sheetRatesAsOf(String date) {
    return 'Rates as of $date';
  }

  @override
  String get sheetTotal => 'Total';

  @override
  String get sheetAddToSheet => 'Add to sheet';

  @override
  String get sheetRename => 'Rename';

  @override
  String get sheetDuplicate => 'Duplicate';

  @override
  String get sheetDelete => 'Delete';

  @override
  String get sheetUndo => 'Undo';
}
