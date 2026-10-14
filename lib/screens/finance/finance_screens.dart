import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../lib_currency.dart';
import '../../lib_finance.dart';
import '../../lib_format.dart';
import '../../lib_payroll.dart';
import '../../lib_tax.dart';
import '../../state/region_provider.dart';
import '../../theme/tokens.dart';
import '../../widgets/chip_picker.dart';
import '../../widgets/inner_scaffold.dart';
import '../../widgets/number_input.dart';
import '../../widgets/result_row.dart';
import '../../sheet/sheet_engine.dart' show dayMonth, dayMonthYear, formatRate, noEcbRateMessage, weekdayDayMonth;
import '../../sheet/add_to_sheet.dart';
import '../../sheet/sheets_controller.dart';
import 'package:agl_i18n/agl_i18n.dart';

// =================== TAX ===================

class TaxCalc extends StatefulWidget {
  /// `income` (income-tax estimate) or `sales` (sales tax / VAT).
  final String initialMode;
  const TaxCalc({super.key, this.initialMode = 'income'});
  @override
  State<TaxCalc> createState() => _TaxCalcState();
}

class _TaxCalcState extends State<TaxCalc> {
  late String mode = widget.initialMode;
  final income = TextEditingController();
  final stateRate = TextEditingController(text: '0');
  final salePrice = TextEditingController();
  late TextEditingController salesRate;
  FilingStatus filing = FilingStatus.single;

  @override
  void initState() {
    super.initState();
    final region = context.read<RegionProvider>().region.id;
    salesRate = TextEditingController(
        text: ((salesTaxRate[region] ?? 0) * 100).toStringAsFixed(1));
    for (final c in [income, stateRate, salePrice, salesRate]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [income, stateRate, salePrice, salesRate]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final region = context.watch<RegionProvider>().region;
    String cur(double n) => formatCurrency(n, region.locale, region.currency);

    final result = computeIncomeTax(
      safeNumber(income.text),
      region.id,
      filing,
      stateLocalRate: (safeNumber(stateRate.text) / 100).clamp(0, 0.15),
    );
    final p = safeNumber(salePrice.text);
    final r = safeNumber(salesRate.text) / 100;
    final salesTax = p * r;
    final salesTotal = p + salesTax;

    return InnerScaffold(
      title: AppLocalizations.of(context)!.financeTax,
      subtitle: '${region.flag} ${region.label} · ${region.currency}',
      tool: 'tax',
      sheetLine: () {
        if (mode == 'income') {
          final gross = safeNumber(income.text);
          if (gross <= 0) return null;
          return 'Income tax ($taxTableYear brackets, ${region.label}, gross '
              '${plainNumber(gross)}${nonEcbNote(region.currency)}): '
              '${sheetMoney(result.taxOwed, region.currency)}';
        }
        if (p <= 0) return null;
        return 'Total with ${plainNumber(r * 100)}% tax (price '
            '${plainNumber(p)}${nonEcbNote(region.currency)}): '
            '${sheetMoney(salesTotal, region.currency)}';
      },
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: _ModePill(
                  label: 'Income',
                  active: mode == 'income',
                  onTap: () => setState(() => mode = 'income'))),
          SizedBox(width: Spacing.sm),
          Expanded(
              child: _ModePill(
                  label: 'Sales / VAT',
                  active: mode == 'sales',
                  onTap: () => setState(() => mode = 'sales'))),
        ]),
        if (mode == 'income') ...[
          NumberInput(
              label: 'Annual gross (${region.currency})', controller: income),
          SizedBox(height: Spacing.md),
          Text(AppLocalizations.of(context)!.labelFilingStatus,
              style: TextStyle(color: context.ledger.inkSoft, fontSize: 13)),
          SizedBox(height: Spacing.sm),
          ChipPicker<FilingStatus>(
            options: [
              (id: FilingStatus.single, label: 'Single'),
              (id: FilingStatus.joint, label: 'Joint'),
              (id: FilingStatus.head, label: 'Head'),
            ],
            value: filing,
            onChange: (v) => setState(() => filing = v),
          ),
          NumberInput(label: 'State / local rate (%)', controller: stateRate),
          SizedBox(height: Spacing.lg),
          ResultRow(label: 'Taxable income', value: cur(result.taxableIncome)),
          ResultRow(
              label: 'Tax owed', value: cur(result.taxOwed), highlight: true),
          ResultRow(
              label: 'Effective rate',
              value: formatPercent(result.effectiveRate)),
          ResultRow(
              label: 'Marginal rate',
              value: formatPercent(result.marginalRate)),
          ResultRow(
              label: 'Take-home (year)',
              value: cur(result.takeHome),
              highlight: true),
          ResultRow(
              label: 'Take-home (month)', value: cur(result.takeHomeMonthly)),
          const SizedBox(height: Spacing.md),
          Text(taxYearNote,
              style: TextStyle(color: context.ledger.inkSoft, fontSize: 12)),
        ] else ...[
          NumberInput(
              label: 'Sale price (${region.currency})', controller: salePrice),
          NumberInput(label: 'Tax rate (%)', controller: salesRate),
          SizedBox(height: Spacing.lg),
          ResultRow(label: 'Tax amount', value: cur(salesTax)),
          ResultRow(
              label: 'Total with tax', value: cur(salesTotal), highlight: true),
        ],
      ]),
    );
  }
}

class _ModePill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ModePill(
      {required this.label, required this.active, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? context.ledger.ink : context.ledger.surface,
      borderRadius: BorderRadius.circular(Radii.button),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.button),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
              border:
                  Border.all(color: active ? context.ledger.ink : context.ledger.rule),
              borderRadius: BorderRadius.circular(Radii.button)),
          child: Text(label,
              style: TextStyle(
                  color: active ? context.ledger.paper : context.ledger.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

// =================== PAYCHECK ===================

class PaycheckCalc extends StatefulWidget {
  const PaycheckCalc({super.key});
  @override
  State<PaycheckCalc> createState() => _PaycheckCalcState();
}

class _PaycheckCalcState extends State<PaycheckCalc> {
  String mode = 'salary';
  final salary = TextEditingController();
  final hourly = TextEditingController();
  final hours = TextEditingController(text: '40');
  final preTax = TextEditingController(text: '0');
  final localRate = TextEditingController();
  FilingStatus filing = FilingStatus.single;
  late RegionId regionId;
  late PayFrequency frequency;
  String? subCode;

  @override
  void initState() {
    super.initState();
    _applyRegion(context.read<RegionProvider>().region.id);
    for (final c in [salary, hourly, hours, preTax, localRate]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [salary, hourly, hours, preTax, localRate]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Resets the location-dependent defaults when the region changes.
  void _applyRegion(RegionId id) {
    regionId = id;
    frequency = defaultPayFrequency(id);
    subCode = null;
    localRate.text = _pctText(defaultLocalRate(id));
  }

  static String _pctText(double rate) =>
      (rate * 100).toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');

  @override
  Widget build(BuildContext context) {
    final region = context.watch<RegionProvider>().region;
    if (region.id != regionId) {
      // The region picker sits over this screen; pick up its change after the
      // frame so the controller update doesn't setState mid-build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && region.id != regionId) {
          setState(() => _applyRegion(region.id));
        }
      });
    }
    String cur(double n) => formatCurrency(n, region.locale, region.currency);

    final subs = subRegions[region.id];
    final subLabel = region.id == RegionId.CA ? 'Province' : 'State';
    final localLabel = switch (region.id) {
      RegionId.US => 'State tax',
      RegionId.CA => 'Provincial tax',
      RegionId.JP => 'Resident tax',
      _ => 'Local tax',
    };
    final gross = mode == 'salary'
        ? safeNumber(salary.text)
        : safeNumber(hourly.text) * safeNumber(hours.text) * 52;
    final result = computePaycheck(
      gross,
      region.id,
      filing,
      frequency,
      preTaxRate: safeNumber(preTax.text) / 100,
      localRate: (safeNumber(localRate.text) / 100).clamp(0, 0.20),
    );
    ResultRow line(String label, double annual, {bool highlight = false}) =>
        ResultRow(
          label: label,
          value: cur(result.perPeriod(annual)),
          caption: '${cur(annual)} / year',
          highlight: highlight,
        );

    return InnerScaffold(
      title: AppLocalizations.of(context)!.financePaycheck,
      subtitle: '${region.flag} ${region.label} · ${region.currency}',
      tool: 'paycheck',
      sheetLine: () => gross <= 0
          ? null
          : 'Take-home per paycheck (${frequency.label}, $taxTableYear '
              'tables${nonEcbNote(region.currency)}): '
              '${sheetMoney(result.perPeriod(result.netAnnual), region.currency)}',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: _ModePill(
                  label: 'Salary',
                  active: mode == 'salary',
                  onTap: () => setState(() => mode = 'salary'))),
          SizedBox(width: Spacing.sm),
          Expanded(
              child: _ModePill(
                  label: 'Hourly',
                  active: mode == 'hourly',
                  onTap: () => setState(() => mode = 'hourly'))),
        ]),
        if (mode == 'salary')
          NumberInput(
              label: 'Annual salary (${region.currency})', controller: salary)
        else ...[
          NumberInput(
              label: 'Hourly rate (${region.currency})', controller: hourly),
          NumberInput(label: 'Hours per week', controller: hours),
        ],
        SizedBox(height: Spacing.md),
        Text('Pay frequency',
            style: TextStyle(color: context.ledger.inkSoft, fontSize: 13)),
        SizedBox(height: Spacing.sm),
        ChipPicker<PayFrequency>(
          options: [
            for (final f in PayFrequency.values) (id: f, label: f.label)
          ],
          value: frequency,
          onChange: (v) => setState(() => frequency = v),
        ),
        SizedBox(height: Spacing.md),
        Text(AppLocalizations.of(context)!.labelFilingStatus,
            style: TextStyle(color: context.ledger.inkSoft, fontSize: 13)),
        SizedBox(height: Spacing.sm),
        ChipPicker<FilingStatus>(
          options: [
            (id: FilingStatus.single, label: 'Single'),
            (id: FilingStatus.joint, label: 'Joint'),
            (id: FilingStatus.head, label: 'Head'),
          ],
          value: filing,
          onChange: (v) => setState(() => filing = v),
        ),
        if (subs != null) ...[
          SizedBox(height: Spacing.md),
          Text(subLabel,
              style: TextStyle(color: context.ledger.inkSoft, fontSize: 13)),
          SizedBox(height: Spacing.sm),
          ChipPicker<String?>(
            options: [
              for (final s in subs) (id: s.code, label: s.name),
            ],
            value: subCode,
            onChange: (v) => setState(() {
              subCode = v;
              localRate.text =
                  _pctText(subs.firstWhere((s) => s.code == v).rate);
            }),
          ),
        ],
        NumberInput(label: '$localLabel rate (%)', controller: localRate),
        NumberInput(
            label: 'Pre-tax retirement (% of gross)', controller: preTax),
        SizedBox(height: Spacing.lg),
        Text('Per paycheck · ${frequency.label}',
            style: TextStyle(color: context.ledger.inkSoft, fontSize: 13)),
        line('Gross pay', result.grossAnnual),
        if (result.preTaxAnnual > 0)
          line('Pre-tax retirement', result.preTaxAnnual),
        line(subs != null ? 'Federal income tax' : 'Income tax',
            result.incomeTaxAnnual),
        if (result.localTaxAnnual > 0 || subs != null)
          line(localLabel, result.localTaxAnnual),
        for (final d in result.social) line(d.label, d.annual),
        line('Take-home pay', result.netAnnual, highlight: true),
        ResultRow(
            label: 'Total deductions',
            value: formatPercent(result.deductionRate)),
        SizedBox(height: Spacing.md),
        Text(
            '$taxYearNote. $localLabel rates are approximate and editable; '
            'your payslip may differ.',
            style: TextStyle(color: context.ledger.inkSoft, fontSize: 12)),
      ]),
    );
  }
}

// =================== TIP ===================

class TipCalc extends StatefulWidget {
  const TipCalc({super.key});
  @override
  State<TipCalc> createState() => _TipCalcState();
}

class _TipCalcState extends State<TipCalc> {
  final bill = TextEditingController();
  final tipPct = TextEditingController();
  final people = TextEditingController(text: '2');

  /// Region whose customary tip is currently in [tipPct], or null before the
  /// first default has been applied.
  RegionId? _defaultFor;

  /// Once the user types their own percentage it is never overwritten.
  bool _tipEdited = false;
  bool _applyingDefault = false;

  @override
  void initState() {
    super.initState();
    for (final c in [bill, people]) {
      c.addListener(() => setState(() {}));
    }
    tipPct.addListener(() {
      if (_applyingDefault) return;
      _tipEdited = true;
      setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Follow the region's tipping custom (0% in Japan, 18% in the US, ...)
    // until the user enters a percentage of their own.
    final regionId = Provider.of<RegionProvider>(context).regionId;
    if (!_tipEdited && regionId != _defaultFor) {
      _defaultFor = regionId;
      _applyingDefault = true;
      tipPct.text = formatNumber(customaryTipPercent[regionId] ?? 0);
      _applyingDefault = false;
    }
  }

  @override
  void dispose() {
    for (final c in [bill, tipPct, people]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final region = context.watch<RegionProvider>().region;
    String cur(double n) => formatCurrency(n, region.locale, region.currency);
    final b = safeNumber(bill.text);
    final t = safeNumber(tipPct.text) / 100;
    final p = safeNumber(people.text).toInt().clamp(1, 1000000);
    final tip = b * t;
    final total = b + tip;
    final customary = customaryTipPercent[region.id] ?? 0;
    return InnerScaffold(
      title: AppLocalizations.of(context)!.financeTip,
      subtitle: '${region.flag} ${region.currency}',
      tool: 'tip',
      sheetLine: () => b <= 0
          ? null
          : 'Per person (bill ${plainNumber(b)} + ${plainNumber(t * 100)}% '
              'tip, $p ${p == 1 ? 'person' : 'people'}'
              '${nonEcbNote(region.currency)}): '
              '${sheetMoney(total / p, region.currency)}',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        NumberInput(label: 'Bill (${region.currency})', controller: bill),
        NumberInput(label: 'Tip %', controller: tipPct),
        Text('Customary tip in ${region.label}: ${formatNumber(customary)}%',
            style: TextStyle(color: context.ledger.inkSoft, fontSize: 12)),
        NumberInput(
            label: 'People',
            controller: people,
            keyboardType: TextInputType.number),
        SizedBox(height: Spacing.lg),
        ResultRow(label: 'Tip', value: cur(tip)),
        ResultRow(label: (AglL10n.of(context)?.miscTotal ?? 'Total'), value: cur(total), highlight: true),
        ResultRow(label: 'Per person', value: cur(total / p), highlight: true),
        ResultRow(label: 'Tip per person', value: cur(tip / p)),
      ]),
    );
  }
}

// =================== DISCOUNT ===================

class DiscountCalc extends StatefulWidget {
  const DiscountCalc({super.key});
  @override
  State<DiscountCalc> createState() => _DiscountCalcState();
}

class _DiscountCalcState extends State<DiscountCalc> {
  final original = TextEditingController();
  final pct = TextEditingController();
  @override
  void initState() {
    super.initState();
    for (final c in [original, pct]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [original, pct]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final region = context.watch<RegionProvider>().region;
    String cur(double n) => formatCurrency(n, region.locale, region.currency);
    final o = safeNumber(original.text);
    final p = safeNumber(pct.text) / 100;
    final savings = o * p;
    final fin = o - savings;
    return InnerScaffold(
      title: AppLocalizations.of(context)!.financeDiscount,
      tool: 'discount',
      sheetLine: () => o <= 0
          ? null
          : 'Final price (${plainNumber(o)} less ${plainNumber(p * 100)}%'
              '${nonEcbNote(region.currency)}): '
              '${sheetMoney(fin, region.currency)}',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        NumberInput(
            label: 'Original (${region.currency})', controller: original),
        NumberInput(label: 'Discount %', controller: pct),
        SizedBox(height: Spacing.lg),
        ResultRow(label: 'You save', value: cur(savings)),
        ResultRow(label: 'Final price', value: cur(fin), highlight: true),
      ]),
    );
  }
}

// =================== COMPOUND ===================

class CompoundCalc extends StatefulWidget {
  const CompoundCalc({super.key});
  @override
  State<CompoundCalc> createState() => _CompoundCalcState();
}

class _CompoundCalcState extends State<CompoundCalc> {
  final principal = TextEditingController();
  final ratePct = TextEditingController(text: '7');
  final years = TextEditingController(text: '10');
  final pmt = TextEditingController();
  String freq = '12';
  @override
  void initState() {
    super.initState();
    for (final c in [principal, ratePct, years, pmt]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [principal, ratePct, years, pmt]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final region = context.watch<RegionProvider>().region;
    String cur(double n) => formatCurrency(n, region.locale, region.currency);
    final P = safeNumber(principal.text);
    final ratePctValue = safeNumber(ratePct.text);
    final t = safeNumber(years.text);
    final n = int.parse(freq);
    final payment = safeNumber(pmt.text);
    final future = compoundFutureValue(
      principal: P,
      annualRatePct: ratePctValue,
      years: t,
      monthlyContribution: payment,
      compoundsPerYear: n,
    );
    final contributed = P + payment * 12 * (t > 0 ? t : 0);
    final interest = future - contributed;
    final schedule = compoundGrowthByYear(
      principal: P,
      annualRatePct: ratePctValue,
      years: t,
      monthlyContribution: payment,
      compoundsPerYear: n,
    );
    return InnerScaffold(
      title: AppLocalizations.of(context)!.financeCompound,
      subtitle: 'Future value of an investment',
      tool: 'compound',
      sheetLine: () => (P <= 0 && payment <= 0) || t <= 0
          ? null
          : 'Future value (${plainNumber(P)} at ${plainNumber(ratePctValue)}%'
              '${payment > 0 ? ' + ${plainNumber(payment)}/month' : ''}, '
              '${plainNumber(t)} y${nonEcbNote(region.currency)}): '
              '${sheetMoney(future, region.currency)}',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        NumberInput(
            label: 'Principal (${region.currency})', controller: principal),
        NumberInput(label: 'Annual rate (%)', controller: ratePct),
        NumberInput(label: 'Years', controller: years),
        NumberInput(
            label: 'Monthly contribution (optional, ${region.currency})',
            controller: pmt),
        SizedBox(height: Spacing.md),
        Text(AppLocalizations.of(context)!.labelCompoundFreq,
            style: TextStyle(color: context.ledger.inkSoft, fontSize: 13)),
        SizedBox(height: Spacing.sm),
        ChipPicker<String>(
          options: [
            (id: '1', label: 'Annually'),
            (id: '4', label: 'Quarterly'),
            (id: '12', label: 'Monthly'),
            (id: '365', label: 'Daily')
          ],
          value: freq,
          onChange: (v) => setState(() => freq = v),
        ),
        SizedBox(height: Spacing.lg),
        ResultRow(label: 'Future value', value: cur(future), highlight: true),
        ResultRow(label: 'Total contributed', value: cur(contributed)),
        ResultRow(label: 'Interest earned', value: cur(interest)),
        if (schedule.isNotEmpty)
          YearlyBreakdown(
            currency: region.currency,
            headers: ['Year', 'Contributed', 'Interest', 'Balance'],
            rows: [
              for (final y in schedule)
                [
                  formatNumber(y.year, maxDigits: 2),
                  formatNumber(y.contributed, maxDigits: 0),
                  formatNumber(y.interest, maxDigits: 0),
                  formatNumber(y.balance, maxDigits: 0),
                ],
            ],
          ),
      ]),
    );
  }
}

// =================== EMI ===================

class EmiCalc extends StatefulWidget {
  const EmiCalc({super.key});
  @override
  State<EmiCalc> createState() => _EmiCalcState();
}

class _EmiCalcState extends State<EmiCalc> {
  final principal = TextEditingController();
  final ratePct = TextEditingController();
  final years = TextEditingController();
  @override
  void initState() {
    super.initState();
    for (final c in [principal, ratePct, years]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [principal, ratePct, years]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final region = context.watch<RegionProvider>().region;
    String cur(double n) => formatCurrency(n, region.locale, region.currency);
    final P = safeNumber(principal.text);
    final ratePctValue = safeNumber(ratePct.text);
    final termYears = safeNumber(years.text);
    final emi = emiMonthly(P, ratePctValue, termYears);
    final n = termYears * 12;
    final totalPayable = emi > 0 ? emi * n : 0.0;
    final totalInterest = emi > 0 ? totalPayable - P : 0.0;
    final schedule = amortizationByYear(P, ratePctValue, termYears);
    return InnerScaffold(
      title: AppLocalizations.of(context)!.financeEMI,
      subtitle: 'Equated monthly installment',
      tool: 'emi',
      sheetLine: () => emi <= 0
          ? null
          : 'Loan payment (${plainNumber(P)} at ${plainNumber(ratePctValue)}%, '
              '${plainNumber(termYears)} y${nonEcbNote(region.currency)}): '
              '${sheetMoney(emi, region.currency)}',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        NumberInput(
            label: 'Loan amount (${region.currency})', controller: principal),
        NumberInput(label: 'Annual rate (%)', controller: ratePct),
        NumberInput(label: 'Term (years)', controller: years),
        SizedBox(height: Spacing.lg),
        ResultRow(label: 'Monthly EMI', value: cur(emi), highlight: true),
        ResultRow(label: 'Total interest', value: cur(totalInterest)),
        ResultRow(label: 'Total payable', value: cur(totalPayable)),
        if (schedule.isNotEmpty)
          YearlyBreakdown(
            currency: region.currency,
            headers: ['Year', 'Principal', 'Interest', 'Balance'],
            rows: [
              for (final y in schedule)
                [
                  '${y.year}',
                  formatNumber(y.principalPaid, maxDigits: 0),
                  formatNumber(y.interestPaid, maxDigits: 0),
                  formatNumber(y.balance, maxDigits: 0),
                ],
            ],
          ),
      ]),
    );
  }
}

// =================== YEAR-BY-YEAR ===================

/// Year-by-year table under the EMI and compound-interest results. Free for
/// everyone: CalcMaster sells nothing.
class YearlyBreakdown extends StatelessWidget {
  final String currency;
  final List<String> headers;
  final List<List<String>> rows;

  const YearlyBreakdown({
    super.key,
    required this.currency,
    required this.headers,
    required this.rows,
  });

  static const _title = 'Year-by-year breakdown';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$_title ($currency)',
              style: TextStyle(
                  color: context.ledger.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: Spacing.sm),
          _row(context, headers, header: true),
          for (final r in rows) _row(context, r),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, List<String> cells, {bool header = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.ledger.rule)),
      ),
      child: Row(children: [
        for (var i = 0; i < cells.length; i++)
          Expanded(
            flex: i == 0 ? 2 : 3,
            child: Text(
              cells[i],
              textAlign: i == 0 ? TextAlign.start : TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: Fonts.figures,
                color: header ? context.ledger.inkSoft : context.ledger.ink,
                fontSize: header ? 12 : 13,
                fontWeight: header ? FontWeight.w600 : FontWeight.w400,
                fontFeatures: Fonts.tabular,
              ),
            ),
          ),
      ]),
    );
  }
}

// =================== CURRENCY ===================

/// Converts an amount at the European Central Bank reference rate — today's,
/// or the rate published for a date the user picks ("Rate on the day"). Only
/// the ECB's 30 currencies are offered; nothing is estimated.
class CurrencyCalc extends StatefulWidget {
  const CurrencyCalc({super.key});
  @override
  State<CurrencyCalc> createState() => _CurrencyCalcState();
}

class _CurrencyCalcState extends State<CurrencyCalc> {
  final amount = TextEditingController(text: '1');
  String? from;
  String? to;

  /// Null means today's rate (the latest table).
  DateTime? on;
  RateTableLookup? _dated;
  bool _loadingDated = false;
  RateClient? _ownClient;

  @override
  void initState() {
    super.initState();
    amount.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    amount.dispose();
    super.dispose();
  }

  RateClient get _client {
    final sheets = Provider.of<SheetsController?>(context, listen: false);
    return sheets?.rateClient ?? (_ownClient ??= RateClient());
  }

  Future<void> _loadDated() async {
    final day = on;
    final base = from;
    if (day == null || base == null) return;
    setState(() => _loadingDated = true);
    final result = await _client.fetchTableOn(day, base);
    if (!mounted || on != day || from != base) return;
    setState(() {
      _dated = result;
      _loadingDated = false;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: on ?? now,
      firstDate: DateTime(1999, 1, 4),
      lastDate: now,
      helpText: 'ECB rate on',
    );
    if (picked == null || !mounted) return;
    setState(() {
      on = picked;
      _dated = null;
    });
    _loadDated();
  }

  String? _reason(RateFailure f, DateTime day) => switch (f) {
        RateFailure.offline =>
          'Needs a connection to get the ECB rates for ${dayMonth(day)}',
        RateFailure.beforeEcb => 'ECB rates start on 4 Jan 1999',
        RateFailure.future => 'That date is in the future',
        RateFailure.unsupported => noEcbRateMessage(from ?? ''),
        RateFailure.http => 'Frankfurter returned no ECB rates for ${dayMonth(day)}',
      };

  @override
  Widget build(BuildContext context) {
    final regionState = context.watch<RegionProvider>();
    final home = regionState.region.currency;
    from ??= isEcbCurrency(home) ? home : 'USD';
    to ??= from == 'USD' ? 'EUR' : 'USD';
    final num = safeNumber(amount.text);
    final codes = ecbCurrencies;

    // Rates for 1 [from]: the latest table (cross rates) or the dated table.
    Map<String, double>? table;
    String? asOf;
    String? reason;
    if (on == null) {
      final latest = regionState.latestTable;
      if (latest != null) {
        table = {
          for (final q in codes)
            if (crossRateFrom(latest, from!, q) case final r?) q: r.rate,
        };
        asOf = latest.date;
      }
    } else if (_dated != null) {
      if (_dated!.ok) {
        table = {..._dated!.rates!, from!: 1};
        asOf = _dated!.ecbDate;
      } else {
        reason = _reason(_dated!.failure!, on!);
      }
    }

    String dateLine() {
      if (on == null) {
        if (table == null) {
          return regionState.ratesLoading
              ? 'Loading rates…'
              : 'No ECB rates yet — needs a connection';
        }
        return regionState.ratesLive
            ? 'ECB rates, $asOf'
            : 'ECB rates, $asOf (offline)';
      }
      if (_loadingDated) return 'Getting the ECB rates for ${dayMonth(on!)}…';
      if (asOf == null) return reason ?? 'ECB rates for ${dayMonth(on!)}';
      final used = DateTime.parse(asOf);
      final asked = isoDate(on!);
      return asOf == asked
          ? 'ECB rates, ${dayMonthYear(used)}'
          : 'ECB rates, ${weekdayDayMonth(used)} (no rate on ${weekdayDayMonth(on!)})';
    }

    final rate = table?[to!];
    return InnerScaffold(
      title: AppLocalizations.of(context)!.financeCurrency,
      subtitle: dateLine(),
      tool: 'currency',
      sheetLine: () {
        if (num <= 0) return null;
        final date = on == null ? '' : ' on ${isoDate(on!)}';
        return '${plainNumber(num)} ${from!}$date in ${to!}';
      },
      actions: [
        IconButton(
          tooltip: 'Refresh exchange rates',
          icon: Icon(Icons.refresh, color: context.ledger.inkSoft),
          onPressed: () => on == null
              ? context.read<RegionProvider>().refreshRates()
              : _loadDated(),
        ),
      ],
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        NumberInput(label: 'Amount', controller: amount),
        const SizedBox(height: Spacing.sm),
        Text('Rate on',
            style: TextStyle(color: context.ledger.inkSoft, fontSize: 13)),
        const SizedBox(height: Spacing.xs),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.event, size: 18),
              label: Text(on == null ? 'Today' : dayMonthYear(on!)),
            ),
          ),
          if (on != null) ...[
            const SizedBox(width: Spacing.sm),
            TextButton(
              onPressed: () => setState(() {
                on = null;
                _dated = null;
              }),
              child: const Text('Use today'),
            ),
          ],
        ]),
        const SizedBox(height: Spacing.md),
        Text(AppLocalizations.of(context)!.labelFrom,
            style: TextStyle(color: context.ledger.inkSoft, fontSize: 13)),
        const SizedBox(height: Spacing.sm),
        ChipPicker<String>(
          options: [for (final c in codes) (id: c, label: c)],
          value: from!,
          onChange: (v) {
            setState(() {
              from = v;
              _dated = null;
            });
            _loadDated();
          },
        ),
        const SizedBox(height: Spacing.sm),
        Text(AppLocalizations.of(context)!.labelTo,
            style: TextStyle(color: context.ledger.inkSoft, fontSize: 13)),
        const SizedBox(height: Spacing.sm),
        ChipPicker<String>(
          options: [for (final c in codes) (id: c, label: c)],
          value: to!,
          onChange: (v) => setState(() => to = v),
        ),
        const SizedBox(height: Spacing.lg),
        if (table == null)
          Text(
            reason ??
                (on != null
                    ? 'Getting the ECB rates for ${dayMonth(on!)}…'
                    : regionState.ratesLoading
                        ? 'Loading exchange rates…'
                        : "Needs a connection to get today's ECB rates. "
                            'Tap refresh when you are online.'),
            style: TextStyle(color: context.ledger.inkSoft, fontSize: 14),
          )
        else ...[
          if (rate != null)
            ResultRow(
              label: '${formatNumber(num)} ${from!} in ${to!}',
              caption: 'ECB ${formatRate(rate)}',
              value: '${formatNumber(num * rate, maxDigits: 2)} ${to!}',
              highlight: true,
            ),
          for (final code in codes.where((c) => c != from && c != to))
            if (table[code] case final r?)
              ResultRow(
                label: code,
                value: formatNumber(num * r),
                highlight: code == home,
              ),
          const SizedBox(height: Spacing.md),
          Text(
            'European Central Bank reference rates via Frankfurter '
            '(api.frankfurter.dev). Not the rate your bank or card charged.',
            style: TextStyle(color: context.ledger.inkSoft, fontSize: 12),
          ),
        ],
      ]),
    );
  }
}

// =================== UNIT PRICE ===================

class UnitPriceCalc extends StatefulWidget {
  const UnitPriceCalc({super.key});
  @override
  State<UnitPriceCalc> createState() => _UnitPriceCalcState();
}

class _UnitPriceCalcState extends State<UnitPriceCalc> {
  final pa = TextEditingController();
  final qa = TextEditingController();
  final pb = TextEditingController();
  final qb = TextEditingController();
  @override
  void initState() {
    super.initState();
    for (final c in [pa, qa, pb, qb]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [pa, qa, pb, qb]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final region = context.watch<RegionProvider>().region;
    String cur(double n) => formatCurrency(n, region.locale, region.currency);
    final upA = safeNumber(qa.text) > 0
        ? safeNumber(pa.text) / safeNumber(qa.text)
        : double.nan;
    final upB = safeNumber(qb.text) > 0
        ? safeNumber(pb.text) / safeNumber(qb.text)
        : double.nan;
    String? cheaper;
    if (upA.isFinite && upB.isFinite) {
      cheaper = upA < upB ? 'A' : (upB < upA ? 'B' : null);
    }
    Widget card(String name, TextEditingController p, TextEditingController q,
        double up, bool win) {
      return Expanded(
        child: Container(
          padding: EdgeInsets.all(Spacing.md),
          decoration: BoxDecoration(
            color: context.ledger.surface,
            border: Border.all(
                color: win
                    ? context.ledger.primary.withValues(alpha: 0.5)
                    : context.ledger.rule),
            borderRadius: BorderRadius.circular(Radii.button),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Option $name',
                style: TextStyle(
                    color: context.ledger.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            NumberInput(label: 'Price (${region.currency})', controller: p),
            NumberInput(label: 'Quantity', controller: q),
            SizedBox(height: Spacing.sm),
            Text(AppLocalizations.of(context)!.labelPerUnit,
                style:
                    TextStyle(color: context.ledger.inkSoft, fontSize: 13)),
            Text(up.isFinite ? cur(up) : '—',
                style: TextStyle(
                    color: win ? context.ledger.primary : context.ledger.ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w700)),
          ]),
        ),
      );
    }

    return InnerScaffold(
      title: AppLocalizations.of(context)!.financeUnitPrice,
      subtitle: 'Which pack is cheaper?',
      tool: 'unit_price',
      sheetLine: () {
        if (cheaper != null) {
          final up = cheaper == 'A' ? upA : upB;
          return 'Cheaper per unit (option $cheaper'
              '${nonEcbNote(region.currency)}): ${sheetMoney(up, region.currency)}';
        }
        if (upA.isFinite) {
          return 'Unit price A${nonEcbNote(region.currency)}: '
              '${sheetMoney(upA, region.currency)}';
        }
        return null;
      },
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          card('A', pa, qa, upA, cheaper == 'A'),
          SizedBox(width: Spacing.md),
          card('B', pb, qb, upB, cheaper == 'B'),
        ]),
        if (cheaper != null)
          Padding(
            padding: EdgeInsets.only(top: Spacing.lg),
            child: Center(
              child: Text('Option $cheaper is cheaper per unit.',
                  style: TextStyle(
                      color: context.ledger.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
            ),
          ),
      ]),
    );
  }
}
