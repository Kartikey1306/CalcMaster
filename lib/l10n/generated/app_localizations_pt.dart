// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'CalcMaster';

  @override
  String get categoryDistance => 'Distância';

  @override
  String get categoryVolume => 'Volume';

  @override
  String get categoryWeight => 'Peso';

  @override
  String get categoryTemperature => 'Temperatura';

  @override
  String get categorySpeed => 'Velocidade';

  @override
  String get categoryArea => 'Área';

  @override
  String get categoryDataSize => 'Dados';

  @override
  String get categoryFuelEconomy => 'Consumo';

  @override
  String get categoryPressure => 'Pressão';

  @override
  String get categoryEnergy => 'Energia';

  @override
  String get labelFrom => 'DE';

  @override
  String get labelTo => 'PARA';

  @override
  String get labelAllConversions => 'TODAS AS CONVERSÕES';

  @override
  String labelUnitsAvailable(int count) {
    return '$count unidades disponíveis';
  }

  @override
  String get calcScientific => 'Científica';

  @override
  String get calcPercentage => 'Porcentagem';

  @override
  String get calcBase => 'Base';

  @override
  String get calcFraction => 'Fração';

  @override
  String get financeTax => 'Imposto';

  @override
  String get financePaycheck => 'Salário líquido';

  @override
  String get financeTip => 'Gorjeta e divisão';

  @override
  String get financeDiscount => 'Desconto';

  @override
  String get financeCompound => 'Juros compostos';

  @override
  String get financeEMI => 'Empréstimo';

  @override
  String get financeCurrency => 'Câmbio';

  @override
  String get financeUnitPrice => 'Preço unitário';

  @override
  String get toolGps => 'Coordenadas GPS';

  @override
  String get toolOhm => 'Lei de Ohm';

  @override
  String get toolBmi => 'IMC';

  @override
  String get toolDateDiff => 'Diferença de datas';

  @override
  String get toolTimeZones => 'Fusos horários';

  @override
  String get toolAdcDac => 'ADC / DAC';

  @override
  String get toolAge => 'Idade';

  @override
  String get toolAspectRatio => 'Proporção';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsNotifications => 'Notificações';

  @override
  String get settingsHelp => 'Ajuda';

  @override
  String get settingsSendFeedback => 'Enviar feedback';

  @override
  String get settingsPrivacyPolicy => 'Política de privacidade';

  @override
  String get settingsPrivacyChoices => 'Opções de privacidade';

  @override
  String get settingsAbout => 'Sobre o CalcMaster';

  @override
  String get regionPickerTitle => 'Selecionar região';

  @override
  String get actionUseMyLocation => 'Usar minha localização';

  @override
  String get actionLocating => 'Localizando…';

  @override
  String get actionPermissionDenied => 'Permissão de localização negada';

  @override
  String get aboutVersion => 'Versão';

  @override
  String get aboutBlurb =>
      'O CalcMaster resolve contas do dia a dia em folhas pautadas: aritmética, porcentagens, unidades e moedas pela taxa de referência do Banco Central Europeu do dia que você indicar. Trinta ferramentas adicionam os resultados à sua folha. As folhas ficam no seu aparelho; não há conta.';

  @override
  String get privacyAtGlance => 'Privacidade em resumo';

  @override
  String get labelFilingStatus => 'Status de declaração';

  @override
  String get labelCompoundFreq => 'Frequência de capitalização';

  @override
  String get labelInputBase => 'Base de entrada';

  @override
  String get labelOperator => 'Operador';

  @override
  String get labelPerUnit => 'Por unidade';

  @override
  String get labelXofY => 'X% de Y';

  @override
  String get labelXisWhatPctOfY => 'X é qual % de Y';

  @override
  String get labelPctChangeXtoY => '% de mudança de X para Y';

  @override
  String get toolsTitle => 'Ferramentas';

  @override
  String get toolsSubtitle =>
      'Todo resultado pode ir para a sua folha, menos o IMC.';

  @override
  String get toolsGroupMoney => 'Dinheiro';

  @override
  String get toolsGroupMeasure => 'Medidas';

  @override
  String get toolsGroupTime => 'Tempo';

  @override
  String get toolsGroupMaths => 'Matemática';

  @override
  String get toolsGroupEngineering => 'Engenharia';

  @override
  String get toolsGroupBody => 'Corpo';

  @override
  String get toolSalesTax => 'Imposto sobre vendas / IVA';

  @override
  String get toolIncomeTax => 'Estimativa de imposto de renda';

  @override
  String get toolCalendar => 'Calendário';

  @override
  String get settingsHomeCurrency => 'Moeda e região';

  @override
  String get settingsHomeCurrencyHint =>
      'A moeda usada pelas ferramentas e as tabelas de impostos aplicadas.';

  @override
  String get settingsAppearance => 'Aparência';

  @override
  String get appearanceSystem => 'Sistema';

  @override
  String get appearanceLedger => 'Livro (claro)';

  @override
  String get appearanceNight => 'Livro noturno';

  @override
  String get settingsRates => 'Câmbio';

  @override
  String settingsRatesBody(int count) {
    return 'Taxas de referência do Banco Central Europeu. Taxas guardadas: $count';
  }

  @override
  String get settingsClearRateCache => 'Limpar cache';

  @override
  String get settingsAutoRates => 'Manter as folhas na taxa mais recente';

  @override
  String get settingsAutoRatesBody =>
      'Procura novas taxas do BCE a cada 30 minutos e ao abrir a app, e atualiza as linhas. Desligado: cada linha mantém a primeira taxa.';

  @override
  String get helpHowLinesWork => 'Como as linhas funcionam';

  @override
  String get aboutTagline =>
      'Contas em folhas pautadas, com taxas do BCE do dia';

  @override
  String get sheetsTitle => 'Folhas';

  @override
  String get sheetsSearchHint => 'Pesquisar títulos e linhas';

  @override
  String get sheetsNew => 'Nova';

  @override
  String get sheetsEmpty =>
      'Ainda não há folhas. Comece uma: cada linha é calculada enquanto você digita.';

  @override
  String get sheetNewSheet => 'Nova folha';

  @override
  String get sheetShareText => 'Compartilhar como texto';

  @override
  String get sheetExportCsv => 'Exportar CSV';

  @override
  String get sheetCopy => 'Copiar para a área de transferência';

  @override
  String get sheetReprice => 'Reprecificar';

  @override
  String sheetRatesAsOf(String date) {
    return 'Taxas de $date';
  }

  @override
  String get sheetTotal => 'Total';

  @override
  String get sheetAddToSheet => 'Adicionar à folha';

  @override
  String get sheetRename => 'Renomear';

  @override
  String get sheetDuplicate => 'Duplicar';

  @override
  String get sheetDelete => 'Excluir';

  @override
  String get sheetUndo => 'Desfazer';
}
