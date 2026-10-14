// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'CalcMaster';

  @override
  String get categoryDistance => 'Entfernung';

  @override
  String get categoryVolume => 'Volumen';

  @override
  String get categoryWeight => 'Gewicht';

  @override
  String get categoryTemperature => 'Temperatur';

  @override
  String get categorySpeed => 'Geschwindigkeit';

  @override
  String get categoryArea => 'Fläche';

  @override
  String get categoryDataSize => 'Datengröße';

  @override
  String get categoryFuelEconomy => 'Verbrauch';

  @override
  String get categoryPressure => 'Druck';

  @override
  String get categoryEnergy => 'Energie';

  @override
  String get labelFrom => 'VON';

  @override
  String get labelTo => 'ZU';

  @override
  String get labelAllConversions => 'ALLE UMRECHNUNGEN';

  @override
  String labelUnitsAvailable(int count) {
    return '$count Einheiten verfügbar';
  }

  @override
  String get calcScientific => 'Wissenschaftlich';

  @override
  String get calcPercentage => 'Prozent';

  @override
  String get calcBase => 'Basis';

  @override
  String get calcFraction => 'Bruch';

  @override
  String get financeTax => 'Steuer';

  @override
  String get financePaycheck => 'Nettolohn';

  @override
  String get financeTip => 'Trinkgeld & Teilen';

  @override
  String get financeDiscount => 'Rabatt';

  @override
  String get financeCompound => 'Zinseszins';

  @override
  String get financeEMI => 'Kredit / EMI';

  @override
  String get financeCurrency => 'Währung';

  @override
  String get financeUnitPrice => 'Stückpreis';

  @override
  String get toolGps => 'GPS-Koordinaten';

  @override
  String get toolOhm => 'Ohmsches Gesetz';

  @override
  String get toolBmi => 'BMI';

  @override
  String get toolDateDiff => 'Datumsdifferenz';

  @override
  String get toolTimeZones => 'Zeitzonen';

  @override
  String get toolAdcDac => 'ADC / DAC';

  @override
  String get toolAge => 'Alter';

  @override
  String get toolAspectRatio => 'Seitenverhältnis';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsNotifications => 'Benachrichtigungen';

  @override
  String get settingsHelp => 'Hilfe';

  @override
  String get settingsSendFeedback => 'Feedback senden';

  @override
  String get settingsPrivacyPolicy => 'Datenschutz';

  @override
  String get settingsPrivacyChoices => 'Datenschutzoptionen';

  @override
  String get settingsAbout => 'Über CalcMaster';

  @override
  String get regionPickerTitle => 'Region wählen';

  @override
  String get actionUseMyLocation => 'Meinen Standort verwenden';

  @override
  String get actionLocating => 'Standortbestimmung…';

  @override
  String get actionPermissionDenied => 'Standortberechtigung verweigert';

  @override
  String get aboutVersion => 'Version';

  @override
  String get aboutBlurb =>
      'CalcMaster rechnet Alltagssummen auf linierten Blättern: Arithmetik, Prozente, Einheiten und Währungen zum Referenzkurs der Europäischen Zentralbank für den Tag, den du angibst. Dreißig Werkzeuge schreiben ihre Ergebnisse auf dein Blatt. Die Blätter bleiben auf deinem Gerät; es gibt kein Konto.';

  @override
  String get privacyAtGlance => 'Datenschutz auf einen Blick';

  @override
  String get labelFilingStatus => 'Steuerstatus';

  @override
  String get labelCompoundFreq => 'Zinseszinsfrequenz';

  @override
  String get labelInputBase => 'Eingabebasis';

  @override
  String get labelOperator => 'Operator';

  @override
  String get labelPerUnit => 'Pro Einheit';

  @override
  String get labelXofY => 'X% von Y';

  @override
  String get labelXisWhatPctOfY => 'X ist wie viel % von Y';

  @override
  String get labelPctChangeXtoY => '% Änderung von X zu Y';

  @override
  String get toolsTitle => 'Werkzeuge';

  @override
  String get toolsSubtitle =>
      'Jedes Ergebnis kann auf dein Blatt – außer dem BMI.';

  @override
  String get toolsGroupMoney => 'Geld';

  @override
  String get toolsGroupMeasure => 'Maße';

  @override
  String get toolsGroupTime => 'Zeit';

  @override
  String get toolsGroupMaths => 'Mathe';

  @override
  String get toolsGroupEngineering => 'Technik';

  @override
  String get toolsGroupBody => 'Körper';

  @override
  String get toolSalesTax => 'Umsatzsteuer / MwSt.';

  @override
  String get toolIncomeTax => 'Einkommensteuer-Schätzung';

  @override
  String get toolCalendar => 'Kalender';

  @override
  String get settingsHomeCurrency => 'Heimatwährung & Region';

  @override
  String get settingsHomeCurrencyHint =>
      'Die Währung der Werkzeuge und die Steuertabellen, die sie anwenden.';

  @override
  String get settingsAppearance => 'Darstellung';

  @override
  String get appearanceSystem => 'System';

  @override
  String get appearanceLedger => 'Kontobuch (hell)';

  @override
  String get appearanceNight => 'Nacht-Kontobuch';

  @override
  String get settingsRates => 'Kurse';

  @override
  String settingsRatesBody(int count) {
    return 'Referenzkurse der Europäischen Zentralbank. Gespeicherte Kurse: $count';
  }

  @override
  String get settingsClearRateCache => 'Cache leeren';

  @override
  String get helpHowLinesWork => 'So funktionieren Zeilen';

  @override
  String get aboutTagline =>
      'Rechnen auf linierten Blättern, mit EZB-Kursen vom Tag';

  @override
  String get sheetsTitle => 'Blätter';

  @override
  String get sheetsSearchHint => 'Titel und Zeilen durchsuchen';

  @override
  String get sheetsNew => 'Neu';

  @override
  String get sheetsEmpty =>
      'Noch keine Blätter. Fang eins an – jede Zeile rechnet sich beim Tippen aus.';

  @override
  String get sheetNewSheet => 'Neues Blatt';

  @override
  String get sheetShareText => 'Als Text teilen';

  @override
  String get sheetExportCsv => 'Als CSV exportieren';

  @override
  String get sheetCopy => 'In die Zwischenablage kopieren';

  @override
  String get sheetReprice => 'Neu bewerten';

  @override
  String sheetRatesAsOf(String date) {
    return 'Kurse vom $date';
  }

  @override
  String get sheetTotal => 'Summe';

  @override
  String get sheetAddToSheet => 'Aufs Blatt';

  @override
  String get sheetRename => 'Umbenennen';

  @override
  String get sheetDuplicate => 'Duplizieren';

  @override
  String get sheetDelete => 'Löschen';

  @override
  String get sheetUndo => 'Rückgängig';
}
