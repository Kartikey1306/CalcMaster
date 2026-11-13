// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'CalcMaster';

  @override
  String get categoryDistance => 'Расстояние';

  @override
  String get categoryVolume => 'Объём';

  @override
  String get categoryWeight => 'Вес';

  @override
  String get categoryTemperature => 'Температура';

  @override
  String get categorySpeed => 'Скорость';

  @override
  String get categoryArea => 'Площадь';

  @override
  String get categoryDataSize => 'Объём данных';

  @override
  String get categoryFuelEconomy => 'Расход топлива';

  @override
  String get categoryPressure => 'Давление';

  @override
  String get categoryEnergy => 'Энергия';

  @override
  String get labelFrom => 'ИЗ';

  @override
  String get labelTo => 'В';

  @override
  String get labelAllConversions => 'ВСЕ КОНВЕРСИИ';

  @override
  String labelUnitsAvailable(int count) {
    return '$count единиц доступно';
  }

  @override
  String get calcScientific => 'Научный';

  @override
  String get calcPercentage => 'Процент';

  @override
  String get calcBase => 'Системы';

  @override
  String get calcFraction => 'Дробь';

  @override
  String get financeTax => 'Налог';

  @override
  String get financePaycheck => 'Зарплата';

  @override
  String get financeTip => 'Чаевые и счёт';

  @override
  String get financeDiscount => 'Скидка';

  @override
  String get financeCompound => 'Сложный процент';

  @override
  String get financeEMI => 'Кредит';

  @override
  String get financeCurrency => 'Валюта';

  @override
  String get financeUnitPrice => 'Цена за единицу';

  @override
  String get toolGps => 'GPS координаты';

  @override
  String get toolOhm => 'Закон Ома';

  @override
  String get toolBmi => 'ИМТ';

  @override
  String get toolDateDiff => 'Разница дат';

  @override
  String get toolTimeZones => 'Часовые пояса';

  @override
  String get toolAdcDac => 'АЦП / ЦАП';

  @override
  String get toolAge => 'Возраст';

  @override
  String get toolAspectRatio => 'Соотношение сторон';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsNotifications => 'Уведомления';

  @override
  String get settingsHelp => 'Помощь';

  @override
  String get settingsSendFeedback => 'Отправить отзыв';

  @override
  String get settingsPrivacyPolicy => 'Политика конфиденциальности';

  @override
  String get settingsPrivacyChoices => 'Настройки конфиденциальности';

  @override
  String get settingsAbout => 'О CalcMaster';

  @override
  String get regionPickerTitle => 'Выберите регион';

  @override
  String get actionUseMyLocation => 'Использовать моё местоположение';

  @override
  String get actionLocating => 'Определение…';

  @override
  String get actionPermissionDenied => 'Доступ к местоположению запрещён';

  @override
  String get aboutVersion => 'Версия';

  @override
  String get aboutBlurb =>
      'CalcMaster считает житейские суммы на листах в линейку: арифметика, проценты, единицы и валюты по справочному курсу Европейского центрального банка на указанный вами день. Тридцать инструментов добавляют результаты на ваш лист. Листы хранятся только на устройстве; учётной записи нет.';

  @override
  String get privacyAtGlance => 'Конфиденциальность вкратце';

  @override
  String get labelFilingStatus => 'Статус подачи';

  @override
  String get labelCompoundFreq => 'Частота начисления';

  @override
  String get labelInputBase => 'Система счисления';

  @override
  String get labelOperator => 'Оператор';

  @override
  String get labelPerUnit => 'За единицу';

  @override
  String get labelXofY => 'X% от Y';

  @override
  String get labelXisWhatPctOfY => 'X — какой % от Y';

  @override
  String get labelPctChangeXtoY => '% изменения от X до Y';

  @override
  String get toolsTitle => 'Инструменты';

  @override
  String get toolsSubtitle =>
      'Любой результат можно добавить на лист — кроме ИМТ.';

  @override
  String get toolsGroupMoney => 'Деньги';

  @override
  String get toolsGroupMeasure => 'Измерения';

  @override
  String get toolsGroupTime => 'Время';

  @override
  String get toolsGroupMaths => 'Математика';

  @override
  String get toolsGroupEngineering => 'Инженерия';

  @override
  String get toolsGroupBody => 'Тело';

  @override
  String get toolSalesTax => 'Налог с продаж / НДС';

  @override
  String get toolIncomeTax => 'Оценка подоходного налога';

  @override
  String get toolCalendar => 'Календарь';

  @override
  String get settingsHomeCurrency => 'Основная валюта и регион';

  @override
  String get settingsHomeCurrencyHint =>
      'Валюта инструментов и налоговые таблицы, которые они применяют.';

  @override
  String get settingsAppearance => 'Оформление';

  @override
  String get appearanceSystem => 'Как в системе';

  @override
  String get appearanceLedger => 'Гроссбух (светлая)';

  @override
  String get appearanceNight => 'Ночной гроссбух';

  @override
  String get settingsRates => 'Курсы';

  @override
  String settingsRatesBody(int count) {
    return 'Справочные курсы Европейского центрального банка. Сохранено курсов: $count';
  }

  @override
  String get settingsClearRateCache => 'Очистить кэш';

  @override
  String get settingsAutoRates => 'Обновлять листы по последнему курсу';

  @override
  String get settingsAutoRatesBody =>
      'Проверяет новые курсы ЕЦБ каждые 30 минут и при открытии приложения и обновляет строки. Выкл.: каждая строка сохраняет первый курс.';

  @override
  String get helpHowLinesWork => 'Как работают строки';

  @override
  String get aboutTagline =>
      'Расчёты на листах в линейку, по курсам ЕЦБ на нужный день';

  @override
  String get sheetsTitle => 'Листы';

  @override
  String get sheetsSearchHint => 'Поиск по названиям и строкам';

  @override
  String get sheetsNew => 'Новый';

  @override
  String get sheetsEmpty =>
      'Листов пока нет. Начните новый — каждая строка считается по мере ввода.';

  @override
  String get sheetNewSheet => 'Новый лист';

  @override
  String get sheetShareText => 'Поделиться текстом';

  @override
  String get sheetExportCsv => 'Экспорт CSV';

  @override
  String get sheetCopy => 'Скопировать в буфер обмена';

  @override
  String get sheetReprice => 'Пересчитать';

  @override
  String sheetRatesAsOf(String date) {
    return 'Курсы на $date';
  }

  @override
  String get sheetTotal => 'Итого';

  @override
  String get sheetAddToSheet => 'Добавить на лист';

  @override
  String get sheetRename => 'Переименовать';

  @override
  String get sheetDuplicate => 'Дублировать';

  @override
  String get sheetDelete => 'Удалить';

  @override
  String get sheetUndo => 'Отменить';
}
