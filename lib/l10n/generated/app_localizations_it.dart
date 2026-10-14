// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'CalcMaster';

  @override
  String get categoryDistance => 'Distanza';

  @override
  String get categoryVolume => 'Volume';

  @override
  String get categoryWeight => 'Peso';

  @override
  String get categoryTemperature => 'Temperatura';

  @override
  String get categorySpeed => 'Velocità';

  @override
  String get categoryArea => 'Area';

  @override
  String get categoryDataSize => 'Dimensione dati';

  @override
  String get categoryFuelEconomy => 'Consumo';

  @override
  String get categoryPressure => 'Pressione';

  @override
  String get categoryEnergy => 'Energia';

  @override
  String get labelFrom => 'DA';

  @override
  String get labelTo => 'A';

  @override
  String get labelAllConversions => 'TUTTE LE CONVERSIONI';

  @override
  String labelUnitsAvailable(int count) {
    return '$count unità disponibili';
  }

  @override
  String get calcScientific => 'Scientifica';

  @override
  String get calcPercentage => 'Percentuale';

  @override
  String get calcBase => 'Base';

  @override
  String get calcFraction => 'Frazione';

  @override
  String get financeTax => 'Tasse';

  @override
  String get financePaycheck => 'Busta paga';

  @override
  String get financeTip => 'Mancia e divisione';

  @override
  String get financeDiscount => 'Sconto';

  @override
  String get financeCompound => 'Interesse composto';

  @override
  String get financeEMI => 'Prestito';

  @override
  String get financeCurrency => 'Valuta';

  @override
  String get financeUnitPrice => 'Prezzo unitario';

  @override
  String get toolGps => 'Coordinate GPS';

  @override
  String get toolOhm => 'Legge di Ohm';

  @override
  String get toolBmi => 'IMC';

  @override
  String get toolDateDiff => 'Differenza date';

  @override
  String get toolTimeZones => 'Fusi orari';

  @override
  String get toolAdcDac => 'ADC / DAC';

  @override
  String get toolAge => 'Età';

  @override
  String get toolAspectRatio => 'Proporzioni';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get settingsNotifications => 'Notifiche';

  @override
  String get settingsHelp => 'Aiuto';

  @override
  String get settingsSendFeedback => 'Invia feedback';

  @override
  String get settingsPrivacyPolicy => 'Privacy policy';

  @override
  String get settingsPrivacyChoices => 'Scelte sulla privacy';

  @override
  String get settingsAbout => 'Informazioni';

  @override
  String get regionPickerTitle => 'Seleziona regione';

  @override
  String get actionUseMyLocation => 'Usa la mia posizione';

  @override
  String get actionLocating => 'Localizzazione…';

  @override
  String get actionPermissionDenied => 'Permesso posizione negato';

  @override
  String get aboutVersion => 'Versione';

  @override
  String get aboutBlurb =>
      'CalcMaster fa i conti di tutti i giorni su fogli a righe: aritmetica, percentuali, unità e valute al tasso di riferimento della Banca centrale europea del giorno che indichi. Trenta strumenti aggiungono i risultati al tuo foglio. I fogli restano sul tuo dispositivo; non c’è alcun account.';

  @override
  String get privacyAtGlance => 'Privacy in sintesi';

  @override
  String get labelFilingStatus => 'Stato dichiarazione';

  @override
  String get labelCompoundFreq => 'Frequenza di capitalizzazione';

  @override
  String get labelInputBase => 'Base di input';

  @override
  String get labelOperator => 'Operatore';

  @override
  String get labelPerUnit => 'Per unità';

  @override
  String get labelXofY => 'X% di Y';

  @override
  String get labelXisWhatPctOfY => 'X è quale % di Y';

  @override
  String get labelPctChangeXtoY => '% di variazione da X a Y';

  @override
  String get toolsTitle => 'Strumenti';

  @override
  String get toolsSubtitle =>
      'Ogni risultato può finire sul tuo foglio, tranne il BMI.';

  @override
  String get toolsGroupMoney => 'Denaro';

  @override
  String get toolsGroupMeasure => 'Misure';

  @override
  String get toolsGroupTime => 'Tempo';

  @override
  String get toolsGroupMaths => 'Matematica';

  @override
  String get toolsGroupEngineering => 'Ingegneria';

  @override
  String get toolsGroupBody => 'Corpo';

  @override
  String get toolSalesTax => 'Imposta sulle vendite / IVA';

  @override
  String get toolIncomeTax => 'Stima dell’imposta sul reddito';

  @override
  String get toolCalendar => 'Calendario';

  @override
  String get settingsHomeCurrency => 'Valuta e regione';

  @override
  String get settingsHomeCurrencyHint =>
      'La valuta usata dagli strumenti e le tabelle fiscali che applicano.';

  @override
  String get settingsAppearance => 'Aspetto';

  @override
  String get appearanceSystem => 'Sistema';

  @override
  String get appearanceLedger => 'Registro (chiaro)';

  @override
  String get appearanceNight => 'Registro notturno';

  @override
  String get settingsRates => 'Tassi';

  @override
  String settingsRatesBody(int count) {
    return 'Tassi di riferimento della Banca centrale europea. Tassi salvati: $count';
  }

  @override
  String get settingsClearRateCache => 'Svuota cache';

  @override
  String get helpHowLinesWork => 'Come funzionano le righe';

  @override
  String get aboutTagline =>
      'Conti su fogli a righe, con i tassi BCE del giorno';

  @override
  String get sheetsTitle => 'Fogli';

  @override
  String get sheetsSearchHint => 'Cerca titoli e righe';

  @override
  String get sheetsNew => 'Nuovo';

  @override
  String get sheetsEmpty =>
      'Ancora nessun foglio. Iniziane uno: ogni riga si calcola mentre scrivi.';

  @override
  String get sheetNewSheet => 'Nuovo foglio';

  @override
  String get sheetShareText => 'Condividi come testo';

  @override
  String get sheetExportCsv => 'Esporta CSV';

  @override
  String get sheetCopy => 'Copia negli appunti';

  @override
  String get sheetReprice => 'Ricalcola';

  @override
  String sheetRatesAsOf(String date) {
    return 'Tassi al $date';
  }

  @override
  String get sheetTotal => 'Totale';

  @override
  String get sheetAddToSheet => 'Aggiungi al foglio';

  @override
  String get sheetRename => 'Rinomina';

  @override
  String get sheetDuplicate => 'Duplica';

  @override
  String get sheetDelete => 'Elimina';

  @override
  String get sheetUndo => 'Annulla';
}
