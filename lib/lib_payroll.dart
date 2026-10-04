import 'dart:math' as math;

import 'lib_currency.dart';
import 'lib_tax.dart';

/// Paycheck (take-home pay) estimates per region: income tax from
/// [computeIncomeTax], a state / provincial / local rate, and the employee
/// share of each region's social-insurance contributions. All figures are
/// simplified 2025 estimates — not payroll or tax advice.

enum PayFrequency {
  weekly(52, 'Weekly'),
  biweekly(26, 'Bi-weekly'),
  semimonthly(24, 'Semi-monthly'),
  monthly(12, 'Monthly');

  final int periods;
  final String label;
  const PayFrequency(this.periods, this.label);
}

/// The frequency most employers in a region pay on.
PayFrequency defaultPayFrequency(RegionId region) => switch (region) {
      RegionId.US => PayFrequency.biweekly,
      RegionId.CA => PayFrequency.biweekly,
      RegionId.AU => PayFrequency.biweekly,
      _ => PayFrequency.monthly,
    };

/// A state, province or territory with an approximate effective income-tax
/// rate for a mid-income (~75k) salary. Used only to prefill the editable
/// "state / local rate" field.
class SubRegion {
  final String code;
  final String name;
  final double rate;
  const SubRegion(this.code, this.name, this.rate);
}

const _usStates = [
  SubRegion('AL', 'Alabama', 0.042),
  SubRegion('AK', 'Alaska', 0),
  SubRegion('AZ', 'Arizona', 0.023),
  SubRegion('AR', 'Arkansas', 0.035),
  SubRegion('CA', 'California', 0.045),
  SubRegion('CO', 'Colorado', 0.039),
  SubRegion('CT', 'Connecticut', 0.048),
  SubRegion('DE', 'Delaware', 0.048),
  SubRegion('DC', 'District of Columbia', 0.055),
  SubRegion('FL', 'Florida', 0),
  SubRegion('GA', 'Georgia', 0.047),
  SubRegion('HI', 'Hawaii', 0.065),
  SubRegion('ID', 'Idaho', 0.048),
  SubRegion('IL', 'Illinois', 0.048),
  SubRegion('IN', 'Indiana', 0.030),
  SubRegion('IA', 'Iowa', 0.036),
  SubRegion('KS', 'Kansas', 0.048),
  SubRegion('KY', 'Kentucky', 0.038),
  SubRegion('LA', 'Louisiana', 0.029),
  SubRegion('ME', 'Maine', 0.055),
  SubRegion('MD', 'Maryland', 0.045),
  SubRegion('MA', 'Massachusetts', 0.050),
  SubRegion('MI', 'Michigan', 0.041),
  SubRegion('MN', 'Minnesota', 0.055),
  SubRegion('MS', 'Mississippi', 0.038),
  SubRegion('MO', 'Missouri', 0.040),
  SubRegion('MT', 'Montana', 0.049),
  SubRegion('NE', 'Nebraska', 0.046),
  SubRegion('NV', 'Nevada', 0),
  SubRegion('NH', 'New Hampshire', 0),
  SubRegion('NJ', 'New Jersey', 0.040),
  SubRegion('NM', 'New Mexico', 0.040),
  SubRegion('NY', 'New York', 0.053),
  SubRegion('NC', 'North Carolina', 0.040),
  SubRegion('ND', 'North Dakota', 0.015),
  SubRegion('OH', 'Ohio', 0.026),
  SubRegion('OK', 'Oklahoma', 0.040),
  SubRegion('OR', 'Oregon', 0.078),
  SubRegion('PA', 'Pennsylvania', 0.0307),
  SubRegion('RI', 'Rhode Island', 0.043),
  SubRegion('SC', 'South Carolina', 0.046),
  SubRegion('SD', 'South Dakota', 0),
  SubRegion('TN', 'Tennessee', 0),
  SubRegion('TX', 'Texas', 0),
  SubRegion('UT', 'Utah', 0.044),
  SubRegion('VT', 'Vermont', 0.050),
  SubRegion('VA', 'Virginia', 0.048),
  SubRegion('WA', 'Washington', 0),
  SubRegion('WV', 'West Virginia', 0.042),
  SubRegion('WI', 'Wisconsin', 0.049),
  SubRegion('WY', 'Wyoming', 0),
];

const _caProvinces = [
  SubRegion('AB', 'Alberta', 0.070),
  SubRegion('BC', 'British Columbia', 0.051),
  SubRegion('MB', 'Manitoba', 0.093),
  SubRegion('NB', 'New Brunswick', 0.092),
  SubRegion('NL', 'Newfoundland and Labrador', 0.098),
  SubRegion('NS', 'Nova Scotia', 0.114),
  SubRegion('NT', 'Northwest Territories', 0.053),
  SubRegion('NU', 'Nunavut', 0.038),
  SubRegion('ON', 'Ontario', 0.056),
  SubRegion('PE', 'Prince Edward Island', 0.103),
  SubRegion('QC', 'Quebec', 0.120),
  SubRegion('SK', 'Saskatchewan', 0.084),
  SubRegion('YT', 'Yukon', 0.056),
];

const Map<RegionId, List<SubRegion>> subRegions = {
  RegionId.US: _usStates,
  RegionId.CA: _caProvinces,
};

/// Default local rate for regions without a sub-region picker. Japan levies a
/// ~10% municipal + prefectural resident tax on salary income.
double defaultLocalRate(RegionId region) => region == RegionId.JP ? 0.10 : 0;

class Deduction {
  final String label;
  final double annual;
  const Deduction(this.label, this.annual);
}

double _capped(double wages, double rate, double cap, [double floor = 0]) =>
    (math.min(wages, cap) - floor).clamp(0, double.infinity) * rate;

/// Employee share of mandatory social-insurance contributions on [gross]
/// annual wages.
List<Deduction> socialContributions(
    double gross, RegionId region, FilingStatus status) {
  if (gross <= 0) return const [];
  switch (region) {
    case RegionId.US:
      final addlThreshold = status == FilingStatus.joint ? 250000.0 : 200000.0;
      return [
        Deduction('Social Security', _capped(gross, 0.062, 176100)),
        Deduction(
            'Medicare',
            gross * 0.0145 +
                (gross - addlThreshold).clamp(0, double.infinity) * 0.009),
      ];
    case RegionId.UK:
      return [
        Deduction(
            'National Insurance',
            _capped(gross, 0.08, 50270, 12570) +
                (gross - 50270).clamp(0, double.infinity) * 0.02),
      ];
    case RegionId.CA:
      return [
        Deduction(
            'CPP',
            _capped(gross, 0.0595, 71300, 3500) +
                _capped(gross, 0.04, 81200, 71300)),
        Deduction('EI', _capped(gross, 0.0164, 65700)),
      ];
    case RegionId.AU:
      return [
        Deduction('Medicare levy', gross > 27222 ? gross * 0.02 : 0),
      ];
    case RegionId.EU:
      // Germany, matching the EU income-tax brackets in lib_tax.dart.
      return [
        Deduction('Pension', _capped(gross, 0.093, 96600)),
        Deduction('Health', _capped(gross, 0.0855, 66150)),
        Deduction('Long-term care', _capped(gross, 0.018, 66150)),
        Deduction('Unemployment', _capped(gross, 0.013, 96600)),
      ];
    case RegionId.IN:
      // EPF: 12% of basic pay, assumed to be half of gross, on the statutory
      // ₹15,000/month wage ceiling.
      return [
        Deduction('EPF', math.min(gross * 0.5, 180000) * 0.12),
      ];
    case RegionId.JP:
      return [
        Deduction('Health insurance', gross * 0.04955),
        Deduction('Pension', _capped(gross, 0.0915, 7800000)),
        Deduction('Employment insurance', gross * 0.0055),
      ];
    case RegionId.KR:
      final health = gross * 0.03545;
      return [
        Deduction('National pension', _capped(gross, 0.045, 76440000)),
        Deduction('Health insurance', health),
        Deduction('Long-term care', health * 0.1295),
        Deduction('Employment insurance', gross * 0.009),
      ];
    case RegionId.BR:
      return [Deduction('INSS', _inssMonthly(gross / 12) * 12)];
    case RegionId.MX:
      return [Deduction('IMSS', gross * 0.02375)];
    case RegionId.AE:
      return const [];
  }
}

/// Brazil's progressive INSS on a monthly salary (2025 table, capped at the
/// ceiling).
double _inssMonthly(double monthly) {
  const bands = [
    Bracket(1518.00, 0.075),
    Bracket(2793.88, 0.09),
    Bracket(4190.83, 0.12),
    Bracket(8157.41, 0.14),
  ];
  double owed = 0;
  double prev = 0;
  for (final b in bands) {
    if (monthly <= prev) break;
    owed += (math.min(monthly, b.upTo) - prev) * b.rate;
    prev = b.upTo;
  }
  return owed;
}

class PaycheckResult {
  final PayFrequency frequency;
  final double grossAnnual;
  final double preTaxAnnual;
  final double incomeTaxAnnual;
  final double localTaxAnnual;
  final List<Deduction> social;
  final double netAnnual;

  const PaycheckResult({
    required this.frequency,
    required this.grossAnnual,
    required this.preTaxAnnual,
    required this.incomeTaxAnnual,
    required this.localTaxAnnual,
    required this.social,
    required this.netAnnual,
  });

  double perPeriod(double annual) => annual / frequency.periods;
  double get grossPerPeriod => perPeriod(grossAnnual);
  double get netPerPeriod => perPeriod(netAnnual);
  double get totalDeductionsAnnual => grossAnnual - netAnnual;
  double get deductionRate =>
      grossAnnual > 0 ? totalDeductionsAnnual / grossAnnual : 0;
}

/// Take-home pay for [grossAnnual] wages. [preTaxRate] (e.g. 401(k) /
/// pension) reduces income-taxable wages but not social contributions;
/// [localRate] is the state / provincial / local rate applied to those same
/// taxable wages.
PaycheckResult computePaycheck(
  double grossAnnual,
  RegionId region,
  FilingStatus status,
  PayFrequency frequency, {
  double preTaxRate = 0,
  double localRate = 0,
}) {
  final gross = grossAnnual.clamp(0, double.infinity).toDouble();
  final preTax = gross * preTaxRate.clamp(0, 1);
  final taxableWages = gross - preTax;
  final incomeTax = computeIncomeTax(taxableWages, region, status).taxOwed;
  final localTax = taxableWages * localRate.clamp(0, 1);
  final social = socialContributions(gross, region, status);
  final socialTotal = social.fold<double>(0, (sum, d) => sum + d.annual);
  final net = (gross - preTax - incomeTax - localTax - socialTotal)
      .clamp(0, double.infinity)
      .toDouble();
  return PaycheckResult(
    frequency: frequency,
    grossAnnual: gross,
    preTaxAnnual: preTax,
    incomeTaxAnnual: incomeTax,
    localTaxAnnual: localTax,
    social: social,
    netAnnual: net,
  );
}
