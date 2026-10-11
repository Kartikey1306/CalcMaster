import 'dart:math' as math;

/// Loan and investment maths shared by the EMI and compound-interest screens,
/// including the year-by-year breakdowns that CalcMaster Pro unlocks.
///
/// Pure functions only, so every number on those screens is unit-tested.

/// Longest schedule the breakdowns will produce. A 100-year loan or
/// investment is already far outside any real use; the cap keeps a typo such
/// as "3000 years" from building a 3000-row table.
const int maxScheduleYears = 100;

/// Monthly instalment for a fully amortising loan.
double emiMonthly(double principal, double annualRatePct, double years) {
  final n = years * 12;
  final r = annualRatePct / 100 / 12;
  if (principal <= 0 || n <= 0 || r < 0) return 0;
  if (r == 0) return principal / n;
  final factor = math.pow(1 + r, n).toDouble();
  return (principal * r * factor) / (factor - 1);
}

/// One year of a loan's amortisation schedule.
class AmortizationYear {
  final int year;
  final double principalPaid;
  final double interestPaid;

  /// Outstanding balance at the end of [year].
  final double balance;

  const AmortizationYear({
    required this.year,
    required this.principalPaid,
    required this.interestPaid,
    required this.balance,
  });
}

/// Year-by-year split of a loan's repayments into principal and interest,
/// with the balance left at the end of each year. Empty for invalid input.
List<AmortizationYear> amortizationByYear(
    double principal, double annualRatePct, double years) {
  final months = (years * 12).round();
  final r = annualRatePct / 100 / 12;
  if (principal <= 0 || months <= 0 || r < 0) return const [];
  final cappedMonths = math.min(months, maxScheduleYears * 12);
  final payment = emiMonthly(principal, annualRatePct, months / 12);

  final rows = <AmortizationYear>[];
  var balance = principal;
  var yearPrincipal = 0.0;
  var yearInterest = 0.0;
  for (var m = 1; m <= cappedMonths; m++) {
    final interest = balance * r;
    // The final instalment clears whatever floating-point dust is left.
    final principalPart = m == months ? balance : payment - interest;
    balance = math.max(0, balance - principalPart);
    yearPrincipal += principalPart;
    yearInterest += interest;
    if (m % 12 == 0 || m == cappedMonths) {
      rows.add(AmortizationYear(
        year: (m + 11) ~/ 12,
        principalPaid: yearPrincipal,
        interestPaid: yearInterest,
        balance: balance,
      ));
      yearPrincipal = 0;
      yearInterest = 0;
    }
  }
  return rows;
}

/// Value after [years] of [principal] growing at [annualRatePct], compounded
/// [compoundsPerYear] times a year, plus [monthlyContribution] deposited at
/// the end of every month.
///
/// Monthly deposits are grown at the monthly rate equivalent to the chosen
/// compounding, so the contribution really is monthly whatever the
/// compounding frequency.
double compoundFutureValue({
  required double principal,
  required double annualRatePct,
  required double years,
  required double monthlyContribution,
  required int compoundsPerYear,
}) {
  final r = annualRatePct / 100;
  if (years <= 0 || compoundsPerYear <= 0 || r < 0) {
    return principal + math.max(0, years) * 12 * monthlyContribution;
  }
  final growth =
      math.pow(1 + r / compoundsPerYear, compoundsPerYear * years).toDouble();
  final months = years * 12;
  double fromContributions;
  if (monthlyContribution == 0) {
    fromContributions = 0;
  } else if (r == 0) {
    fromContributions = monthlyContribution * months;
  } else {
    final monthlyRate =
        math.pow(1 + r / compoundsPerYear, compoundsPerYear / 12).toDouble() -
            1;
    fromContributions = monthlyContribution *
        ((math.pow(1 + monthlyRate, months).toDouble() - 1) / monthlyRate);
  }
  return principal * growth + fromContributions;
}

/// One year of an investment's growth.
class GrowthYear {
  /// Elapsed years at this row; fractional only for a final partial year.
  final double year;

  /// Principal plus every monthly contribution made so far.
  final double contributed;

  /// Interest earned so far.
  final double interest;

  /// Value at the end of [year].
  final double balance;

  const GrowthYear({
    required this.year,
    required this.contributed,
    required this.interest,
    required this.balance,
  });
}

/// Year-by-year value of an investment, consistent with
/// [compoundFutureValue]. A fractional final year gets its own last row.
List<GrowthYear> compoundGrowthByYear({
  required double principal,
  required double annualRatePct,
  required double years,
  required double monthlyContribution,
  required int compoundsPerYear,
}) {
  if (years <= 0 || annualRatePct < 0 || compoundsPerYear <= 0) {
    return const [];
  }
  if (principal <= 0 && monthlyContribution <= 0) return const [];
  final span = math.min(years, maxScheduleYears.toDouble());
  final points = <double>[
    for (var y = 1; y <= span.floor(); y++) y.toDouble(),
    if (span != span.floorToDouble()) span,
  ];
  return [
    for (final t in points)
      () {
        final balance = compoundFutureValue(
          principal: principal,
          annualRatePct: annualRatePct,
          years: t,
          monthlyContribution: monthlyContribution,
          compoundsPerYear: compoundsPerYear,
        );
        final contributed = principal + monthlyContribution * 12 * t;
        return GrowthYear(
          year: t,
          contributed: contributed,
          interest: balance - contributed,
          balance: balance,
        );
      }(),
  ];
}
