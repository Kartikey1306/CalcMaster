// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'CalcMaster';

  @override
  String get categoryDistance => 'Distancia';

  @override
  String get categoryVolume => 'Volumen';

  @override
  String get categoryWeight => 'Peso';

  @override
  String get categoryTemperature => 'Temperatura';

  @override
  String get categorySpeed => 'Velocidad';

  @override
  String get categoryArea => 'Área';

  @override
  String get categoryDataSize => 'Tamaño de datos';

  @override
  String get categoryFuelEconomy => 'Consumo';

  @override
  String get categoryPressure => 'Presión';

  @override
  String get categoryEnergy => 'Energía';

  @override
  String get labelFrom => 'DESDE';

  @override
  String get labelTo => 'HASTA';

  @override
  String get labelAllConversions => 'TODAS LAS CONVERSIONES';

  @override
  String labelUnitsAvailable(int count) {
    return '$count unidades disponibles';
  }

  @override
  String get calcScientific => 'Científica';

  @override
  String get calcPercentage => 'Porcentaje';

  @override
  String get calcBase => 'Base';

  @override
  String get calcFraction => 'Fracción';

  @override
  String get financeTax => 'Impuestos';

  @override
  String get financePaycheck => 'Nómina';

  @override
  String get financeTip => 'Propina y dividir';

  @override
  String get financeDiscount => 'Descuento';

  @override
  String get financeCompound => 'Interés compuesto';

  @override
  String get financeEMI => 'Préstamo';

  @override
  String get financeCurrency => 'Divisas';

  @override
  String get financeUnitPrice => 'Precio unitario';

  @override
  String get toolGps => 'Coordenadas GPS';

  @override
  String get toolOhm => 'Ley de Ohm';

  @override
  String get toolBmi => 'IMC';

  @override
  String get toolDateDiff => 'Diferencia de fechas';

  @override
  String get toolTimeZones => 'Zonas horarias';

  @override
  String get toolAdcDac => 'ADC / DAC';

  @override
  String get toolAge => 'Edad';

  @override
  String get toolAspectRatio => 'Relación de aspecto';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsNotifications => 'Notificaciones';

  @override
  String get settingsHelp => 'Ayuda';

  @override
  String get settingsSendFeedback => 'Enviar comentarios';

  @override
  String get settingsPrivacyPolicy => 'Política de privacidad';

  @override
  String get settingsPrivacyChoices => 'Opciones de privacidad';

  @override
  String get settingsAbout => 'Acerca de CalcMaster';

  @override
  String get regionPickerTitle => 'Selecciona región';

  @override
  String get actionUseMyLocation => 'Usar mi ubicación';

  @override
  String get actionLocating => 'Localizando…';

  @override
  String get actionPermissionDenied => 'Permiso de ubicación denegado';

  @override
  String get aboutVersion => 'Versión';

  @override
  String get aboutBlurb =>
      'CalcMaster resuelve cuentas reales en hojas rayadas: aritmética, porcentajes, unidades y divisas al tipo de referencia del Banco Central Europeo del día que indiques. Treinta herramientas añaden sus resultados a tu hoja. Las hojas se quedan en tu dispositivo; no hay cuenta.';

  @override
  String get privacyAtGlance => 'Privacidad en resumen';

  @override
  String get labelFilingStatus => 'Estado civil fiscal';

  @override
  String get labelCompoundFreq => 'Frecuencia de capitalización';

  @override
  String get labelInputBase => 'Base de entrada';

  @override
  String get labelOperator => 'Operador';

  @override
  String get labelPerUnit => 'Por unidad';

  @override
  String get labelXofY => 'X% de Y';

  @override
  String get labelXisWhatPctOfY => 'X es qué % de Y';

  @override
  String get labelPctChangeXtoY => '% de cambio de X a Y';

  @override
  String get toolsTitle => 'Herramientas';

  @override
  String get toolsSubtitle =>
      'Cada resultado puede ir a tu hoja, salvo el IMC.';

  @override
  String get toolsGroupMoney => 'Dinero';

  @override
  String get toolsGroupMeasure => 'Medidas';

  @override
  String get toolsGroupTime => 'Tiempo';

  @override
  String get toolsGroupMaths => 'Matemáticas';

  @override
  String get toolsGroupEngineering => 'Ingeniería';

  @override
  String get toolsGroupBody => 'Cuerpo';

  @override
  String get toolSalesTax => 'Impuesto sobre ventas / IVA';

  @override
  String get toolIncomeTax => 'Estimación del impuesto sobre la renta';

  @override
  String get toolCalendar => 'Calendario';

  @override
  String get settingsHomeCurrency => 'Moneda y región';

  @override
  String get settingsHomeCurrencyHint =>
      'La moneda que usan las herramientas y las tablas de impuestos que aplican.';

  @override
  String get settingsAppearance => 'Apariencia';

  @override
  String get appearanceSystem => 'Sistema';

  @override
  String get appearanceLedger => 'Libro (claro)';

  @override
  String get appearanceNight => 'Libro nocturno';

  @override
  String get settingsRates => 'Tipos de cambio';

  @override
  String settingsRatesBody(int count) {
    return 'Tipos de referencia del Banco Central Europeo. Tipos guardados: $count';
  }

  @override
  String get settingsClearRateCache => 'Borrar caché';

  @override
  String get helpHowLinesWork => 'Cómo funcionan las líneas';

  @override
  String get aboutTagline =>
      'Cuentas en hojas rayadas, con tipos del BCE del día';

  @override
  String get sheetsTitle => 'Hojas';

  @override
  String get sheetsSearchHint => 'Buscar en títulos y líneas';

  @override
  String get sheetsNew => 'Nueva';

  @override
  String get sheetsEmpty =>
      'Aún no hay hojas. Empieza una: cada línea se calcula mientras escribes.';

  @override
  String get sheetNewSheet => 'Nueva hoja';

  @override
  String get sheetShareText => 'Compartir como texto';

  @override
  String get sheetExportCsv => 'Exportar CSV';

  @override
  String get sheetCopy => 'Copiar al portapapeles';

  @override
  String get sheetReprice => 'Recalcular';

  @override
  String sheetRatesAsOf(String date) {
    return 'Tipos al $date';
  }

  @override
  String get sheetTotal => 'Total';

  @override
  String get sheetAddToSheet => 'Añadir a la hoja';

  @override
  String get sheetRename => 'Renombrar';

  @override
  String get sheetDuplicate => 'Duplicar';

  @override
  String get sheetDelete => 'Eliminar';

  @override
  String get sheetUndo => 'Deshacer';
}
