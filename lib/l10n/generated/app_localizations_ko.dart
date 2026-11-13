// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'CalcMaster';

  @override
  String get categoryDistance => '거리';

  @override
  String get categoryVolume => '부피';

  @override
  String get categoryWeight => '무게';

  @override
  String get categoryTemperature => '온도';

  @override
  String get categorySpeed => '속도';

  @override
  String get categoryArea => '면적';

  @override
  String get categoryDataSize => '데이터 크기';

  @override
  String get categoryFuelEconomy => '연비';

  @override
  String get categoryPressure => '압력';

  @override
  String get categoryEnergy => '에너지';

  @override
  String get labelFrom => '에서';

  @override
  String get labelTo => '으로';

  @override
  String get labelAllConversions => '모든 변환';

  @override
  String labelUnitsAvailable(int count) {
    return '$count개 단위 사용 가능';
  }

  @override
  String get calcScientific => '공학';

  @override
  String get calcPercentage => '백분율';

  @override
  String get calcBase => '진수';

  @override
  String get calcFraction => '분수';

  @override
  String get financeTax => '세금';

  @override
  String get financePaycheck => '실수령액';

  @override
  String get financeTip => '팁 & 분할';

  @override
  String get financeDiscount => '할인';

  @override
  String get financeCompound => '복리';

  @override
  String get financeEMI => '대출';

  @override
  String get financeCurrency => '환율';

  @override
  String get financeUnitPrice => '단위가격';

  @override
  String get toolGps => 'GPS 좌표';

  @override
  String get toolOhm => '옴의 법칙';

  @override
  String get toolBmi => 'BMI';

  @override
  String get toolDateDiff => '날짜 차이';

  @override
  String get toolTimeZones => '시간대';

  @override
  String get toolAdcDac => 'ADC / DAC';

  @override
  String get toolAge => '나이';

  @override
  String get toolAspectRatio => '화면 비율';

  @override
  String get settingsTitle => '설정';

  @override
  String get settingsNotifications => '알림';

  @override
  String get settingsHelp => '도움말';

  @override
  String get settingsSendFeedback => '피드백 보내기';

  @override
  String get settingsPrivacyPolicy => '개인정보 처리방침';

  @override
  String get settingsPrivacyChoices => '개인정보 보호 선택';

  @override
  String get settingsAbout => 'CalcMaster 정보';

  @override
  String get regionPickerTitle => '지역 선택';

  @override
  String get actionUseMyLocation => '내 위치 사용';

  @override
  String get actionLocating => '위치 확인 중…';

  @override
  String get actionPermissionDenied => '위치 권한 거부됨';

  @override
  String get aboutVersion => '버전';

  @override
  String get aboutBlurb =>
      'CalcMaster는 줄 쳐진 시트에서 실생활 계산을 합니다. 사칙연산, 퍼센트, 단위, 그리고 지정한 날짜의 유럽중앙은행 기준 환율로 통화를 환산합니다. 서른 개의 도구가 결과를 시트에 추가합니다. 시트는 기기에만 저장되며 계정은 없습니다.';

  @override
  String get privacyAtGlance => '개인정보 보호 요약';

  @override
  String get labelFilingStatus => '신고 상태';

  @override
  String get labelCompoundFreq => '복리 빈도';

  @override
  String get labelInputBase => '입력 진수';

  @override
  String get labelOperator => '연산자';

  @override
  String get labelPerUnit => '단위당';

  @override
  String get labelXofY => 'Y의 X%';

  @override
  String get labelXisWhatPctOfY => 'X는 Y의 몇 %인가';

  @override
  String get labelPctChangeXtoY => 'X에서 Y로의 % 변화';

  @override
  String get toolsTitle => '도구';

  @override
  String get toolsSubtitle => 'BMI를 제외한 모든 결과를 시트에 추가할 수 있습니다.';

  @override
  String get toolsGroupMoney => '돈';

  @override
  String get toolsGroupMeasure => '측정';

  @override
  String get toolsGroupTime => '시간';

  @override
  String get toolsGroupMaths => '수학';

  @override
  String get toolsGroupEngineering => '공학';

  @override
  String get toolsGroupBody => '신체';

  @override
  String get toolSalesTax => '판매세 / 부가세';

  @override
  String get toolIncomeTax => '소득세 추정';

  @override
  String get toolCalendar => '달력';

  @override
  String get settingsHomeCurrency => '기본 통화 및 지역';

  @override
  String get settingsHomeCurrencyHint => '도구가 사용하는 통화와 적용하는 세율표입니다.';

  @override
  String get settingsAppearance => '화면 모드';

  @override
  String get appearanceSystem => '시스템';

  @override
  String get appearanceLedger => '장부 (라이트)';

  @override
  String get appearanceNight => '야간 장부';

  @override
  String get settingsRates => '환율';

  @override
  String settingsRatesBody(int count) {
    return '유럽중앙은행 기준 환율. 저장된 환율: $count';
  }

  @override
  String get settingsClearRateCache => '캐시 지우기';

  @override
  String get settingsAutoRates => '시트를 최신 환율로 유지';

  @override
  String get settingsAutoRatesBody =>
      '30분마다, 그리고 앱을 열 때 ECB의 새 환율을 확인해 줄을 업데이트합니다. 끄기: 각 줄은 처음 계산한 환율을 유지합니다.';

  @override
  String get helpHowLinesWork => '줄 작성법';

  @override
  String get aboutTagline => '줄 쳐진 시트 위의 계산, 그날의 ECB 환율로';

  @override
  String get sheetsTitle => '시트';

  @override
  String get sheetsSearchHint => '제목과 줄 검색';

  @override
  String get sheetsNew => '새로 만들기';

  @override
  String get sheetsEmpty => '아직 시트가 없습니다. 하나 시작해 보세요 — 줄마다 입력하는 즉시 계산됩니다.';

  @override
  String get sheetNewSheet => '새 시트';

  @override
  String get sheetShareText => '텍스트로 공유';

  @override
  String get sheetExportCsv => 'CSV 내보내기';

  @override
  String get sheetCopy => '클립보드에 복사';

  @override
  String get sheetReprice => '재계산';

  @override
  String sheetRatesAsOf(String date) {
    return '$date 기준 환율';
  }

  @override
  String get sheetTotal => '합계';

  @override
  String get sheetAddToSheet => '시트에 추가';

  @override
  String get sheetRename => '이름 바꾸기';

  @override
  String get sheetDuplicate => '복제';

  @override
  String get sheetDelete => '삭제';

  @override
  String get sheetUndo => '실행 취소';
}
