// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'CalcMaster';

  @override
  String get categoryDistance => '距離';

  @override
  String get categoryVolume => '体積';

  @override
  String get categoryWeight => '重さ';

  @override
  String get categoryTemperature => '温度';

  @override
  String get categorySpeed => '速度';

  @override
  String get categoryArea => '面積';

  @override
  String get categoryDataSize => 'データサイズ';

  @override
  String get categoryFuelEconomy => '燃費';

  @override
  String get categoryPressure => '圧力';

  @override
  String get categoryEnergy => 'エネルギー';

  @override
  String get labelFrom => 'から';

  @override
  String get labelTo => 'へ';

  @override
  String get labelAllConversions => 'すべての変換';

  @override
  String labelUnitsAvailable(int count) {
    return '$count 単位利用可能';
  }

  @override
  String get calcScientific => '関数';

  @override
  String get calcPercentage => 'パーセント';

  @override
  String get calcBase => '基数';

  @override
  String get calcFraction => '分数';

  @override
  String get financeTax => '税';

  @override
  String get financePaycheck => '手取り給与';

  @override
  String get financeTip => 'チップと割り勘';

  @override
  String get financeDiscount => '割引';

  @override
  String get financeCompound => '複利';

  @override
  String get financeEMI => 'ローン';

  @override
  String get financeCurrency => '通貨';

  @override
  String get financeUnitPrice => '単価';

  @override
  String get toolGps => 'GPS 座標';

  @override
  String get toolOhm => 'オームの法則';

  @override
  String get toolBmi => 'BMI';

  @override
  String get toolDateDiff => '日付差';

  @override
  String get toolTimeZones => 'タイムゾーン';

  @override
  String get toolAdcDac => 'ADC / DAC';

  @override
  String get toolAge => '年齢';

  @override
  String get toolAspectRatio => 'アスペクト比';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsNotifications => '通知';

  @override
  String get settingsHelp => 'ヘルプ';

  @override
  String get settingsSendFeedback => 'フィードバックを送る';

  @override
  String get settingsPrivacyPolicy => 'プライバシーポリシー';

  @override
  String get settingsPrivacyChoices => 'プライバシーの選択';

  @override
  String get settingsAbout => 'CalcMaster について';

  @override
  String get regionPickerTitle => '地域を選択';

  @override
  String get actionUseMyLocation => '現在地を使う';

  @override
  String get actionLocating => '位置情報を取得中…';

  @override
  String get actionPermissionDenied => '位置情報の許可が拒否されました';

  @override
  String get aboutVersion => 'バージョン';

  @override
  String get aboutBlurb =>
      'CalcMaster は罫線シートで日常の計算をします。四則演算、パーセント、単位、そして指定した日の欧州中央銀行参照レートでの通貨換算。30 のツールが結果をシートに追加します。シートは端末内にだけ保存され、アカウントはありません。';

  @override
  String get privacyAtGlance => 'プライバシーの概要';

  @override
  String get labelFilingStatus => '申告状況';

  @override
  String get labelCompoundFreq => '複利頻度';

  @override
  String get labelInputBase => '入力基数';

  @override
  String get labelOperator => '演算子';

  @override
  String get labelPerUnit => '単位あたり';

  @override
  String get labelXofY => 'YのX%';

  @override
  String get labelXisWhatPctOfY => 'XはYの何%か';

  @override
  String get labelPctChangeXtoY => 'XからYへの%変化';

  @override
  String get toolsTitle => 'ツール';

  @override
  String get toolsSubtitle => 'BMI 以外の結果はすべてシートに追加できます。';

  @override
  String get toolsGroupMoney => 'お金';

  @override
  String get toolsGroupMeasure => '単位';

  @override
  String get toolsGroupTime => '時間';

  @override
  String get toolsGroupMaths => '数学';

  @override
  String get toolsGroupEngineering => 'エンジニアリング';

  @override
  String get toolsGroupBody => 'からだ';

  @override
  String get toolSalesTax => '消費税 / VAT';

  @override
  String get toolIncomeTax => '所得税の概算';

  @override
  String get toolCalendar => 'カレンダー';

  @override
  String get settingsHomeCurrency => '基準通貨と地域';

  @override
  String get settingsHomeCurrencyHint => 'ツールが使う通貨と、適用する税表です。';

  @override
  String get settingsAppearance => '外観';

  @override
  String get appearanceSystem => 'システム';

  @override
  String get appearanceLedger => '台帳（ライト）';

  @override
  String get appearanceNight => '夜の台帳';

  @override
  String get settingsRates => '為替レート';

  @override
  String settingsRatesBody(int count) {
    return '欧州中央銀行の参照レート。保存済みレート：$count';
  }

  @override
  String get settingsClearRateCache => 'キャッシュを消去';

  @override
  String get helpHowLinesWork => '行の書き方';

  @override
  String get aboutTagline => '罫線シートで計算、その日の ECB レートで';

  @override
  String get sheetsTitle => 'シート';

  @override
  String get sheetsSearchHint => 'タイトルと行を検索';

  @override
  String get sheetsNew => '新規';

  @override
  String get sheetsEmpty => 'シートはまだありません。始めましょう——各行は入力するそばから計算されます。';

  @override
  String get sheetNewSheet => '新しいシート';

  @override
  String get sheetShareText => 'テキストで共有';

  @override
  String get sheetExportCsv => 'CSV を書き出す';

  @override
  String get sheetCopy => 'クリップボードにコピー';

  @override
  String get sheetReprice => '再計算';

  @override
  String sheetRatesAsOf(String date) {
    return '$date 時点のレート';
  }

  @override
  String get sheetTotal => '合計';

  @override
  String get sheetAddToSheet => 'シートに追加';

  @override
  String get sheetRename => '名前を変更';

  @override
  String get sheetDuplicate => '複製';

  @override
  String get sheetDelete => '削除';

  @override
  String get sheetUndo => '元に戻す';
}
