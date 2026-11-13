// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'CalcMaster';

  @override
  String get categoryDistance => '距离';

  @override
  String get categoryVolume => '体积';

  @override
  String get categoryWeight => '重量';

  @override
  String get categoryTemperature => '温度';

  @override
  String get categorySpeed => '速度';

  @override
  String get categoryArea => '面积';

  @override
  String get categoryDataSize => '数据大小';

  @override
  String get categoryFuelEconomy => '燃油经济性';

  @override
  String get categoryPressure => '压力';

  @override
  String get categoryEnergy => '能量';

  @override
  String get labelFrom => '从';

  @override
  String get labelTo => '到';

  @override
  String get labelAllConversions => '全部转换';

  @override
  String labelUnitsAvailable(int count) {
    return '$count 个单位可用';
  }

  @override
  String get calcScientific => '科学';

  @override
  String get calcPercentage => '百分比';

  @override
  String get calcBase => '进制';

  @override
  String get calcFraction => '分数';

  @override
  String get financeTax => '税款';

  @override
  String get financePaycheck => '工资计算';

  @override
  String get financeTip => '小费与分摊';

  @override
  String get financeDiscount => '折扣';

  @override
  String get financeCompound => '复利';

  @override
  String get financeEMI => '贷款 EMI';

  @override
  String get financeCurrency => '货币';

  @override
  String get financeUnitPrice => '单价';

  @override
  String get toolGps => 'GPS 坐标';

  @override
  String get toolOhm => '欧姆定律';

  @override
  String get toolBmi => 'BMI';

  @override
  String get toolDateDiff => '日期差';

  @override
  String get toolTimeZones => '时区';

  @override
  String get toolAdcDac => 'ADC / DAC';

  @override
  String get toolAge => '年龄';

  @override
  String get toolAspectRatio => '宽高比';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsNotifications => '通知';

  @override
  String get settingsHelp => '帮助';

  @override
  String get settingsSendFeedback => '发送反馈';

  @override
  String get settingsPrivacyPolicy => '隐私政策';

  @override
  String get settingsPrivacyChoices => '隐私选项';

  @override
  String get settingsAbout => '关于 CalcMaster';

  @override
  String get regionPickerTitle => '选择地区';

  @override
  String get actionUseMyLocation => '使用我的位置';

  @override
  String get actionLocating => '定位中…';

  @override
  String get actionPermissionDenied => '位置权限被拒绝';

  @override
  String get aboutVersion => '版本';

  @override
  String get aboutBlurb =>
      'CalcMaster 在横线表单上完成真实生活中的计算：算术、百分比、单位，以及按你指定日期的欧洲央行参考汇率换算货币。三十个工具可把结果加到你的表单上。表单只保存在你的设备上，无需账户。';

  @override
  String get privacyAtGlance => '隐私概览';

  @override
  String get labelFilingStatus => '报税状态';

  @override
  String get labelCompoundFreq => '复利频率';

  @override
  String get labelInputBase => '输入进制';

  @override
  String get labelOperator => '运算符';

  @override
  String get labelPerUnit => '每单位';

  @override
  String get labelXofY => 'X% 的 Y';

  @override
  String get labelXisWhatPctOfY => 'X 是 Y 的百分之几';

  @override
  String get labelPctChangeXtoY => '从 X 到 Y 的百分比变化';

  @override
  String get toolsTitle => '工具';

  @override
  String get toolsSubtitle => '除 BMI 外，每个结果都能加到你的表单上。';

  @override
  String get toolsGroupMoney => '金钱';

  @override
  String get toolsGroupMeasure => '度量';

  @override
  String get toolsGroupTime => '时间';

  @override
  String get toolsGroupMaths => '数学';

  @override
  String get toolsGroupEngineering => '工程';

  @override
  String get toolsGroupBody => '身体';

  @override
  String get toolSalesTax => '销售税 / 增值税';

  @override
  String get toolIncomeTax => '所得税估算';

  @override
  String get toolCalendar => '日历';

  @override
  String get settingsHomeCurrency => '本币与地区';

  @override
  String get settingsHomeCurrencyHint => '工具使用的货币及其适用的税表。';

  @override
  String get settingsAppearance => '外观';

  @override
  String get appearanceSystem => '跟随系统';

  @override
  String get appearanceLedger => '账本（浅色）';

  @override
  String get appearanceNight => '夜间账本';

  @override
  String get settingsRates => '汇率';

  @override
  String settingsRatesBody(int count) {
    return '欧洲央行参考汇率。已缓存的汇率：$count';
  }

  @override
  String get settingsClearRateCache => '清除缓存';

  @override
  String get settingsAutoRates => '让表格使用最新汇率';

  @override
  String get settingsAutoRatesBody =>
      '每 30 分钟及打开应用时检查欧洲央行的新汇率，并更新各行。关闭：每行保留首次计算时的汇率。';

  @override
  String get helpHowLinesWork => '行的写法';

  @override
  String get aboutTagline => '横线表单上的计算，按当日欧洲央行汇率';

  @override
  String get sheetsTitle => '表单';

  @override
  String get sheetsSearchHint => '搜索标题和行';

  @override
  String get sheetsNew => '新建';

  @override
  String get sheetsEmpty => '还没有表单。新建一个吧——每一行都会边输入边算出结果。';

  @override
  String get sheetNewSheet => '新建表单';

  @override
  String get sheetShareText => '以文本分享';

  @override
  String get sheetExportCsv => '导出 CSV';

  @override
  String get sheetCopy => '复制到剪贴板';

  @override
  String get sheetReprice => '重新定价';

  @override
  String sheetRatesAsOf(String date) {
    return '汇率截至 $date';
  }

  @override
  String get sheetTotal => '合计';

  @override
  String get sheetAddToSheet => '加到表单';

  @override
  String get sheetRename => '重命名';

  @override
  String get sheetDuplicate => '复制';

  @override
  String get sheetDelete => '删除';

  @override
  String get sheetUndo => '撤销';
}
