// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'CalcMaster';

  @override
  String get categoryDistance => 'दूरी';

  @override
  String get categoryVolume => 'आयतन';

  @override
  String get categoryWeight => 'भार';

  @override
  String get categoryTemperature => 'तापमान';

  @override
  String get categorySpeed => 'गति';

  @override
  String get categoryArea => 'क्षेत्रफल';

  @override
  String get categoryDataSize => 'डेटा आकार';

  @override
  String get categoryFuelEconomy => 'ईंधन क्षमता';

  @override
  String get categoryPressure => 'दाब';

  @override
  String get categoryEnergy => 'ऊर्जा';

  @override
  String get labelFrom => 'से';

  @override
  String get labelTo => 'तक';

  @override
  String get labelAllConversions => 'सभी रूपांतरण';

  @override
  String labelUnitsAvailable(int count) {
    return '$count यूनिट उपलब्ध';
  }

  @override
  String get calcScientific => 'वैज्ञानिक';

  @override
  String get calcPercentage => 'प्रतिशत';

  @override
  String get calcBase => 'आधार';

  @override
  String get calcFraction => 'भिन्न';

  @override
  String get financeTax => 'टैक्स';

  @override
  String get financePaycheck => 'वेतन';

  @override
  String get financeTip => 'टिप व विभाजन';

  @override
  String get financeDiscount => 'छूट';

  @override
  String get financeCompound => 'चक्रवृद्धि ब्याज';

  @override
  String get financeEMI => 'EMI / ऋण';

  @override
  String get financeCurrency => 'मुद्रा';

  @override
  String get financeUnitPrice => 'इकाई मूल्य';

  @override
  String get toolGps => 'GPS निर्देशांक';

  @override
  String get toolOhm => 'ओम का नियम';

  @override
  String get toolBmi => 'BMI';

  @override
  String get toolDateDiff => 'तिथि अंतर';

  @override
  String get toolTimeZones => 'समय क्षेत्र';

  @override
  String get toolAdcDac => 'ADC / DAC';

  @override
  String get toolAge => 'आयु';

  @override
  String get toolAspectRatio => 'पहलू अनुपात';

  @override
  String get settingsTitle => 'सेटिंग्स';

  @override
  String get settingsNotifications => 'सूचनाएँ';

  @override
  String get settingsHelp => 'सहायता';

  @override
  String get settingsSendFeedback => 'प्रतिक्रिया भेजें';

  @override
  String get settingsPrivacyPolicy => 'गोपनीयता नीति';

  @override
  String get settingsPrivacyChoices => 'गोपनीयता विकल्प';

  @override
  String get settingsAbout => 'CalcMaster के बारे में';

  @override
  String get regionPickerTitle => 'क्षेत्र चुनें';

  @override
  String get actionUseMyLocation => 'मेरा स्थान उपयोग करें';

  @override
  String get actionLocating => 'स्थान खोज रहा है…';

  @override
  String get actionPermissionDenied => 'स्थान अनुमति अस्वीकृत';

  @override
  String get aboutVersion => 'संस्करण';

  @override
  String get aboutBlurb =>
      'CalcMaster रूल्ड शीट पर असल ज़िंदगी के हिसाब करता है: अंकगणित, प्रतिशत, इकाइयाँ, और आपके बताए दिन की यूरोपीय सेंट्रल बैंक संदर्भ दर पर मुद्राएँ। तीस टूल अपने नतीजे आपकी शीट में जोड़ते हैं। शीटें आपके डिवाइस पर ही रहती हैं; कोई खाता नहीं है।';

  @override
  String get privacyAtGlance => 'गोपनीयता एक नज़र में';

  @override
  String get labelFilingStatus => 'दाखिल करने की स्थिति';

  @override
  String get labelCompoundFreq => 'चक्रवृद्धि आवृत्ति';

  @override
  String get labelInputBase => 'इनपुट आधार';

  @override
  String get labelOperator => 'ऑपरेटर';

  @override
  String get labelPerUnit => 'प्रति इकाई';

  @override
  String get labelXofY => 'Y का X%';

  @override
  String get labelXisWhatPctOfY => 'X, Y का कितना % है';

  @override
  String get labelPctChangeXtoY => 'X से Y तक % परिवर्तन';

  @override
  String get toolsTitle => 'टूल';

  @override
  String get toolsSubtitle =>
      'BMI को छोड़कर हर नतीजा आपकी शीट में जोड़ा जा सकता है।';

  @override
  String get toolsGroupMoney => 'पैसा';

  @override
  String get toolsGroupMeasure => 'माप';

  @override
  String get toolsGroupTime => 'समय';

  @override
  String get toolsGroupMaths => 'गणित';

  @override
  String get toolsGroupEngineering => 'इंजीनियरिंग';

  @override
  String get toolsGroupBody => 'शरीर';

  @override
  String get toolSalesTax => 'बिक्री कर / VAT';

  @override
  String get toolIncomeTax => 'आयकर अनुमान';

  @override
  String get toolCalendar => 'कैलेंडर';

  @override
  String get settingsHomeCurrency => 'मुख्य मुद्रा और क्षेत्र';

  @override
  String get settingsHomeCurrencyHint =>
      'टूल जिस मुद्रा और जिन कर तालिकाओं का उपयोग करते हैं।';

  @override
  String get settingsAppearance => 'दिखावट';

  @override
  String get appearanceSystem => 'सिस्टम';

  @override
  String get appearanceLedger => 'लेजर (हल्का)';

  @override
  String get appearanceNight => 'रात्रि लेजर';

  @override
  String get settingsRates => 'दरें';

  @override
  String settingsRatesBody(int count) {
    return 'यूरोपीय सेंट्रल बैंक की संदर्भ दरें। सहेजी गई दरें: $count';
  }

  @override
  String get settingsClearRateCache => 'कैश साफ़ करें';

  @override
  String get helpHowLinesWork => 'लाइनें कैसे काम करती हैं';

  @override
  String get aboutTagline => 'रूल्ड शीट पर हिसाब, उसी दिन की ECB दरों के साथ';

  @override
  String get sheetsTitle => 'शीटें';

  @override
  String get sheetsSearchHint => 'शीर्षक और लाइनें खोजें';

  @override
  String get sheetsNew => 'नई';

  @override
  String get sheetsEmpty =>
      'अभी कोई शीट नहीं। एक शुरू करें — हर लाइन टाइप करते ही हल हो जाती है।';

  @override
  String get sheetNewSheet => 'नई शीट';

  @override
  String get sheetShareText => 'टेक्स्ट के रूप में साझा करें';

  @override
  String get sheetExportCsv => 'CSV निर्यात करें';

  @override
  String get sheetCopy => 'क्लिपबोर्ड पर कॉपी करें';

  @override
  String get sheetReprice => 'फिर से दाम लगाएँ';

  @override
  String sheetRatesAsOf(String date) {
    return '$date की दरें';
  }

  @override
  String get sheetTotal => 'कुल';

  @override
  String get sheetAddToSheet => 'शीट में जोड़ें';

  @override
  String get sheetRename => 'नाम बदलें';

  @override
  String get sheetDuplicate => 'डुप्लिकेट';

  @override
  String get sheetDelete => 'हटाएँ';

  @override
  String get sheetUndo => 'पूर्ववत करें';
}
