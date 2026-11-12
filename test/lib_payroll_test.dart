import 'package:flutter_test/flutter_test.dart';
import 'package:calcmaster/lib_currency.dart';
import 'package:calcmaster/lib_payroll.dart';
import 'package:calcmaster/lib_tax.dart';

double _social(PaycheckResult r, String label) =>
    r.social.firstWhere((d) => d.label == label).annual;

void main() {
  group('computePaycheck — US', () {
    test('100k single, bi-weekly, no state tax', () {
      final r = computePaycheck(
          100000, RegionId.US, FilingStatus.single, PayFrequency.biweekly);
      // Taxable 84250 (2025 standard deduction 15750):
      // 1192.50 + 12% × 36550 + 22% × 35775 = 13449
      expect(r.incomeTaxAnnual, closeTo(13449, 1));
      expect(_social(r, 'Social Security'), closeTo(6200, 1e-6));
      expect(_social(r, 'Medicare'), closeTo(1450, 1e-6));
      expect(r.netAnnual, closeTo(78901, 1));
      expect(r.netPerPeriod, closeTo(78901 / 26, 0.05));
      expect(r.grossPerPeriod, closeTo(100000 / 26, 1e-6));
    });

    test('Social Security stops at the wage base', () {
      final r = computePaycheck(
          200000, RegionId.US, FilingStatus.single, PayFrequency.monthly);
      expect(_social(r, 'Social Security'), closeTo(176100 * 0.062, 1e-6));
    });

    test('additional Medicare above 200k single, 250k joint', () {
      final single = computePaycheck(
          300000, RegionId.US, FilingStatus.single, PayFrequency.monthly);
      expect(_social(single, 'Medicare'), closeTo(4350 + 900, 1e-6));
      final joint = computePaycheck(
          300000, RegionId.US, FilingStatus.joint, PayFrequency.monthly);
      expect(_social(joint, 'Medicare'), closeTo(4350 + 450, 1e-6));
    });

    test('pre-tax retirement lowers income tax but not FICA', () {
      final r = computePaycheck(
          100000, RegionId.US, FilingStatus.single, PayFrequency.biweekly,
          preTaxRate: 0.10);
      expect(r.preTaxAnnual, closeTo(10000, 1e-6));
      // Taxable 74250: 1192.50 + 4386 + 22% × 25775 = 11249
      expect(r.incomeTaxAnnual, closeTo(11249, 1));
      expect(_social(r, 'Social Security'), closeTo(6200, 1e-6));
    });

    test('state rate applies to wages after pre-tax deductions', () {
      final r = computePaycheck(
          100000, RegionId.US, FilingStatus.single, PayFrequency.biweekly,
          preTaxRate: 0.10, localRate: 0.05);
      expect(r.localTaxAnnual, closeTo(4500, 1e-6));
    });
  });

  group('socialContributions — other regions', () {
    test('UK National Insurance: 8% main band, 2% above', () {
      final r = computePaycheck(
          60000, RegionId.UK, FilingStatus.single, PayFrequency.monthly);
      expect(_social(r, 'National Insurance'), closeTo(3016 + 194.6, 1e-6));
    });

    test('Canada CPP, CPP2 and EI', () {
      final r = computePaycheck(
          80000, RegionId.CA, FilingStatus.single, PayFrequency.biweekly);
      expect(_social(r, 'CPP'), closeTo(4034.1 + 348, 1e-6));
      expect(_social(r, 'EI'), closeTo(1077.48, 1e-6));
    });

    test('Brazil INSS is progressive on the monthly salary', () {
      final r = computePaycheck(
          60000, RegionId.BR, FilingStatus.single, PayFrequency.monthly);
      expect(_social(r, 'INSS'), closeTo(509.597 * 12, 0.01));
    });

    test('UAE has no income tax or employee contributions', () {
      final r = computePaycheck(
          120000, RegionId.AE, FilingStatus.single, PayFrequency.monthly);
      expect(r.netAnnual, 120000);
      expect(r.social, isEmpty);
    });
  });

  group('computePaycheck — invariants', () {
    test('zero gross gives zero everything', () {
      for (final region in RegionId.values) {
        final r = computePaycheck(
            0, region, FilingStatus.single, PayFrequency.monthly);
        expect(r.netAnnual, 0, reason: region.name);
        expect(r.deductionRate, 0, reason: region.name);
      }
    });

    test('net + deductions = gross, net never negative, every region', () {
      for (final region in RegionId.values) {
        final r = computePaycheck(
            75000, region, FilingStatus.single, PayFrequency.monthly,
            localRate: defaultLocalRate(region));
        expect(r.netAnnual, greaterThanOrEqualTo(0), reason: region.name);
        expect(r.netAnnual + r.totalDeductionsAnnual, closeTo(75000, 1e-6),
            reason: region.name);
      }
    });

    test('per-period amounts add back up to the annual figure', () {
      for (final f in PayFrequency.values) {
        final r = computePaycheck(90000, RegionId.US, FilingStatus.single, f);
        expect(r.netPerPeriod * f.periods, closeTo(r.netAnnual, 1e-6));
      }
    });
  });

  group('location defaults', () {
    test('US lists 50 states plus DC; Canada 13 provinces and territories', () {
      expect(subRegions[RegionId.US], hasLength(51));
      expect(subRegions[RegionId.CA], hasLength(13));
    });

    test('states without a wage income tax default to 0%', () {
      const noTax = ['AK', 'FL', 'NV', 'NH', 'SD', 'TN', 'TX', 'WA', 'WY'];
      for (final s in subRegions[RegionId.US]!) {
        expect(s.rate == 0, noTax.contains(s.code), reason: s.code);
      }
    });

    test('pay frequency and local rate defaults follow the region', () {
      expect(defaultPayFrequency(RegionId.US), PayFrequency.biweekly);
      expect(defaultPayFrequency(RegionId.UK), PayFrequency.monthly);
      expect(defaultLocalRate(RegionId.JP), 0.10);
      expect(defaultLocalRate(RegionId.UK), 0);
    });
  });
}
