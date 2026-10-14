// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'CalcMaster';

  @override
  String get categoryDistance => 'Distance';

  @override
  String get categoryVolume => 'Volume';

  @override
  String get categoryWeight => 'Poids';

  @override
  String get categoryTemperature => 'Température';

  @override
  String get categorySpeed => 'Vitesse';

  @override
  String get categoryArea => 'Surface';

  @override
  String get categoryDataSize => 'Taille de données';

  @override
  String get categoryFuelEconomy => 'Consommation';

  @override
  String get categoryPressure => 'Pression';

  @override
  String get categoryEnergy => 'Énergie';

  @override
  String get labelFrom => 'DE';

  @override
  String get labelTo => 'VERS';

  @override
  String get labelAllConversions => 'TOUTES LES CONVERSIONS';

  @override
  String labelUnitsAvailable(int count) {
    return '$count unités disponibles';
  }

  @override
  String get calcScientific => 'Scientifique';

  @override
  String get calcPercentage => 'Pourcentage';

  @override
  String get calcBase => 'Base';

  @override
  String get calcFraction => 'Fraction';

  @override
  String get financeTax => 'Impôt';

  @override
  String get financePaycheck => 'Salaire net';

  @override
  String get financeTip => 'Pourboire & partage';

  @override
  String get financeDiscount => 'Remise';

  @override
  String get financeCompound => 'Intérêts composés';

  @override
  String get financeEMI => 'Prêt / EMI';

  @override
  String get financeCurrency => 'Devise';

  @override
  String get financeUnitPrice => 'Prix unitaire';

  @override
  String get toolGps => 'Coordonnées GPS';

  @override
  String get toolOhm => 'Loi d\'Ohm';

  @override
  String get toolBmi => 'IMC';

  @override
  String get toolDateDiff => 'Différence de date';

  @override
  String get toolTimeZones => 'Fuseaux horaires';

  @override
  String get toolAdcDac => 'ADC / DAC';

  @override
  String get toolAge => 'Âge';

  @override
  String get toolAspectRatio => 'Format d\'image';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsHelp => 'Aide';

  @override
  String get settingsSendFeedback => 'Envoyer un commentaire';

  @override
  String get settingsPrivacyPolicy => 'Politique de confidentialité';

  @override
  String get settingsPrivacyChoices => 'Choix de confidentialité';

  @override
  String get settingsAbout => 'À propos de CalcMaster';

  @override
  String get regionPickerTitle => 'Sélectionner la région';

  @override
  String get actionUseMyLocation => 'Utiliser ma position';

  @override
  String get actionLocating => 'Localisation…';

  @override
  String get actionPermissionDenied => 'Permission de localisation refusée';

  @override
  String get aboutVersion => 'Version';

  @override
  String get aboutBlurb =>
      'CalcMaster fait vos calculs de tous les jours sur des feuilles lignées : arithmétique, pourcentages, unités, et devises au taux de référence de la Banque centrale européenne du jour que vous indiquez. Trente outils ajoutent leurs résultats à votre feuille. Les feuilles restent sur votre appareil ; il n’y a pas de compte.';

  @override
  String get privacyAtGlance => 'Confidentialité en un coup d\'œil';

  @override
  String get labelFilingStatus => 'Situation fiscale';

  @override
  String get labelCompoundFreq => 'Fréquence de capitalisation';

  @override
  String get labelInputBase => 'Base d\'entrée';

  @override
  String get labelOperator => 'Opérateur';

  @override
  String get labelPerUnit => 'Par unité';

  @override
  String get labelXofY => 'X% de Y';

  @override
  String get labelXisWhatPctOfY => 'X est quel % de Y';

  @override
  String get labelPctChangeXtoY => '% de variation de X à Y';

  @override
  String get toolsTitle => 'Outils';

  @override
  String get toolsSubtitle =>
      'Chaque résultat peut aller sur votre feuille, sauf l’IMC.';

  @override
  String get toolsGroupMoney => 'Argent';

  @override
  String get toolsGroupMeasure => 'Mesures';

  @override
  String get toolsGroupTime => 'Temps';

  @override
  String get toolsGroupMaths => 'Maths';

  @override
  String get toolsGroupEngineering => 'Ingénierie';

  @override
  String get toolsGroupBody => 'Corps';

  @override
  String get toolSalesTax => 'Taxe de vente / TVA';

  @override
  String get toolIncomeTax => 'Estimation de l’impôt sur le revenu';

  @override
  String get toolCalendar => 'Calendrier';

  @override
  String get settingsHomeCurrency => 'Devise et région';

  @override
  String get settingsHomeCurrencyHint =>
      'La devise utilisée par les outils et les barèmes fiscaux appliqués.';

  @override
  String get settingsAppearance => 'Apparence';

  @override
  String get appearanceSystem => 'Système';

  @override
  String get appearanceLedger => 'Registre (clair)';

  @override
  String get appearanceNight => 'Registre de nuit';

  @override
  String get settingsRates => 'Taux';

  @override
  String settingsRatesBody(int count) {
    return 'Taux de référence de la Banque centrale européenne. Taux en cache : $count';
  }

  @override
  String get settingsClearRateCache => 'Vider le cache';

  @override
  String get helpHowLinesWork => 'Comment écrire les lignes';

  @override
  String get aboutTagline =>
      'Des calculs sur feuilles lignées, aux taux BCE du jour';

  @override
  String get sheetsTitle => 'Feuilles';

  @override
  String get sheetsSearchHint => 'Rechercher titres et lignes';

  @override
  String get sheetsNew => 'Nouvelle';

  @override
  String get sheetsEmpty =>
      'Aucune feuille pour l’instant. Commencez-en une : chaque ligne se calcule pendant la saisie.';

  @override
  String get sheetNewSheet => 'Nouvelle feuille';

  @override
  String get sheetShareText => 'Partager en texte';

  @override
  String get sheetExportCsv => 'Exporter en CSV';

  @override
  String get sheetCopy => 'Copier dans le presse-papiers';

  @override
  String get sheetReprice => 'Réévaluer';

  @override
  String sheetRatesAsOf(String date) {
    return 'Taux au $date';
  }

  @override
  String get sheetTotal => 'Total';

  @override
  String get sheetAddToSheet => 'Ajouter à la feuille';

  @override
  String get sheetRename => 'Renommer';

  @override
  String get sheetDuplicate => 'Dupliquer';

  @override
  String get sheetDelete => 'Supprimer';

  @override
  String get sheetUndo => 'Annuler';
}
