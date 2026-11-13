// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'CalcMaster';

  @override
  String get categoryDistance => 'المسافة';

  @override
  String get categoryVolume => 'الحجم';

  @override
  String get categoryWeight => 'الوزن';

  @override
  String get categoryTemperature => 'درجة الحرارة';

  @override
  String get categorySpeed => 'السرعة';

  @override
  String get categoryArea => 'المساحة';

  @override
  String get categoryDataSize => 'حجم البيانات';

  @override
  String get categoryFuelEconomy => 'استهلاك الوقود';

  @override
  String get categoryPressure => 'الضغط';

  @override
  String get categoryEnergy => 'الطاقة';

  @override
  String get labelFrom => 'من';

  @override
  String get labelTo => 'إلى';

  @override
  String get labelAllConversions => 'جميع التحويلات';

  @override
  String labelUnitsAvailable(int count) {
    return '$count وحدات متاحة';
  }

  @override
  String get calcScientific => 'علمي';

  @override
  String get calcPercentage => 'نسبة مئوية';

  @override
  String get calcBase => 'أساس';

  @override
  String get calcFraction => 'كسر';

  @override
  String get financeTax => 'ضريبة';

  @override
  String get financePaycheck => 'صافي الراتب';

  @override
  String get financeTip => 'بقشيش وتقسيم';

  @override
  String get financeDiscount => 'خصم';

  @override
  String get financeCompound => 'فائدة مركبة';

  @override
  String get financeEMI => 'قسط / قرض';

  @override
  String get financeCurrency => 'عملة';

  @override
  String get financeUnitPrice => 'سعر الوحدة';

  @override
  String get toolGps => 'إحداثيات GPS';

  @override
  String get toolOhm => 'قانون أوم';

  @override
  String get toolBmi => 'BMI';

  @override
  String get toolDateDiff => 'فرق التواريخ';

  @override
  String get toolTimeZones => 'المناطق الزمنية';

  @override
  String get toolAdcDac => 'ADC / DAC';

  @override
  String get toolAge => 'العمر';

  @override
  String get toolAspectRatio => 'نسبة العرض';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get settingsNotifications => 'الإشعارات';

  @override
  String get settingsHelp => 'المساعدة';

  @override
  String get settingsSendFeedback => 'إرسال ملاحظات';

  @override
  String get settingsPrivacyPolicy => 'سياسة الخصوصية';

  @override
  String get settingsPrivacyChoices => 'خيارات الخصوصية';

  @override
  String get settingsAbout => 'حول CalcMaster';

  @override
  String get regionPickerTitle => 'اختر المنطقة';

  @override
  String get actionUseMyLocation => 'استخدم موقعي';

  @override
  String get actionLocating => 'جاري تحديد الموقع…';

  @override
  String get actionPermissionDenied => 'تم رفض إذن الموقع';

  @override
  String get aboutVersion => 'الإصدار';

  @override
  String get aboutBlurb =>
      'يحسب CalcMaster مسائل الحياة اليومية على أوراق مسطّرة: الحساب والنسب المئوية والوحدات، والعملات بالسعر المرجعي للبنك المركزي الأوروبي في اليوم الذي تحدده. ثلاثون أداة تضيف نتائجها إلى ورقتك. تبقى الأوراق على جهازك، ولا يوجد حساب.';

  @override
  String get privacyAtGlance => 'الخصوصية في لمحة';

  @override
  String get labelFilingStatus => 'حالة الإيداع الضريبي';

  @override
  String get labelCompoundFreq => 'تكرار الفائدة المركبة';

  @override
  String get labelInputBase => 'قاعدة الإدخال';

  @override
  String get labelOperator => 'العملية';

  @override
  String get labelPerUnit => 'لكل وحدة';

  @override
  String get labelXofY => 'X% من Y';

  @override
  String get labelXisWhatPctOfY => 'X هو كم % من Y';

  @override
  String get labelPctChangeXtoY => '% التغيير من X إلى Y';

  @override
  String get toolsTitle => 'الأدوات';

  @override
  String get toolsSubtitle =>
      'يمكن إضافة كل نتيجة إلى ورقتك، ما عدا مؤشر كتلة الجسم.';

  @override
  String get toolsGroupMoney => 'المال';

  @override
  String get toolsGroupMeasure => 'القياس';

  @override
  String get toolsGroupTime => 'الوقت';

  @override
  String get toolsGroupMaths => 'الرياضيات';

  @override
  String get toolsGroupEngineering => 'الهندسة';

  @override
  String get toolsGroupBody => 'الجسم';

  @override
  String get toolSalesTax => 'ضريبة المبيعات / القيمة المضافة';

  @override
  String get toolIncomeTax => 'تقدير ضريبة الدخل';

  @override
  String get toolCalendar => 'التقويم';

  @override
  String get settingsHomeCurrency => 'العملة والمنطقة';

  @override
  String get settingsHomeCurrencyHint =>
      'العملة التي تستخدمها الأدوات وجداول الضرائب التي تطبقها.';

  @override
  String get settingsAppearance => 'المظهر';

  @override
  String get appearanceSystem => 'النظام';

  @override
  String get appearanceLedger => 'دفتر (فاتح)';

  @override
  String get appearanceNight => 'دفتر ليلي';

  @override
  String get settingsRates => 'أسعار الصرف';

  @override
  String settingsRatesBody(int count) {
    return 'أسعار مرجعية من البنك المركزي الأوروبي. الأسعار المحفوظة: $count';
  }

  @override
  String get settingsClearRateCache => 'مسح الذاكرة المؤقتة';

  @override
  String get settingsAutoRates => 'إبقاء الأوراق على أحدث سعر';

  @override
  String get settingsAutoRatesBody =>
      'يتحقق من أسعار البنك المركزي الأوروبي الجديدة كل 30 دقيقة وعند فتح التطبيق ويحدّث الأسطر. عند الإيقاف: يحتفظ كل سطر بسعره الأول.';

  @override
  String get helpHowLinesWork => 'كيف تعمل الأسطر';

  @override
  String get aboutTagline =>
      'حسابات على أوراق مسطّرة بأسعار البنك المركزي الأوروبي لذلك اليوم';

  @override
  String get sheetsTitle => 'الأوراق';

  @override
  String get sheetsSearchHint => 'ابحث في العناوين والأسطر';

  @override
  String get sheetsNew => 'جديدة';

  @override
  String get sheetsEmpty =>
      'لا توجد أوراق بعد. ابدأ واحدة — كل سطر يُحسب أثناء الكتابة.';

  @override
  String get sheetNewSheet => 'ورقة جديدة';

  @override
  String get sheetShareText => 'مشاركة كنص';

  @override
  String get sheetExportCsv => 'تصدير CSV';

  @override
  String get sheetCopy => 'نسخ إلى الحافظة';

  @override
  String get sheetReprice => 'إعادة التسعير';

  @override
  String sheetRatesAsOf(String date) {
    return 'الأسعار بتاريخ $date';
  }

  @override
  String get sheetTotal => 'المجموع';

  @override
  String get sheetAddToSheet => 'أضف إلى الورقة';

  @override
  String get sheetRename => 'إعادة تسمية';

  @override
  String get sheetDuplicate => 'تكرار';

  @override
  String get sheetDelete => 'حذف';

  @override
  String get sheetUndo => 'تراجع';
}
