import 'package:intl/intl.dart';

String formatNumber(double value, {int? maxDigits, int minDigits = 0}) {
  if (!value.isFinite) return '—';
  final abs = value.abs();
  int max = maxDigits ?? 6;
  if (abs != 0 && abs < 0.0001) max = 8;
  if (abs >= 10000) max = 2;
  if (abs >= 1000000) max = 0;

  // Past 15 digits a double has no more real precision (and the formatter
  // overflows past 9.2e18), so very large numbers read 1.234568e+21. Tiny
  // ones that would otherwise round to 0 read 1e-12 — unless the caller
  // asked for few decimals (money), where 0.00 is the right answer.
  if (abs >= 1e15 ||
      (abs != 0 && abs < 0.5 * _pow10(-max) && (maxDigits ?? 6) > 2)) {
    return _scientific(value);
  }

  final pattern = StringBuffer('#,##0');
  if (max > 0) {
    pattern.write('.');
    pattern.write('0' * minDigits);
    pattern.write('#' * (max - minDigits));
  }
  final f = NumberFormat(pattern.toString(), 'en_US');
  return f.format(value);
}

String formatCurrency(double value, String locale, String currency) {
  if (!value.isFinite) return '—';
  try {
    return NumberFormat.currency(
            locale: locale, name: currency, symbol: _symbolFor(currency))
        .format(value);
  } catch (_) {
    return '${value.toStringAsFixed(2)} $currency';
  }
}

String _symbolFor(String currency) {
  switch (currency) {
    case 'USD':
      return '\$';
    case 'GBP':
      return '£';
    case 'EUR':
      return '€';
    case 'CAD':
      return 'C\$';
    case 'AUD':
      return 'A\$';
    case 'INR':
      return '₹';
    case 'JPY':
      return '¥';
    default:
      return '$currency ';
  }
}

String formatPercent(double value, {int digits = 2}) {
  if (!value.isFinite) return '—';
  return '${(value * 100).toStringAsFixed(digits)}%';
}

double safeNumber(String input) {
  if (input.isEmpty) return 0;
  final cleaned = input.replaceAll(',', '').trim();
  return double.tryParse(cleaned) ?? 0;
}

/// A number a sheet line can read back: no thousands separators, at most
/// [maxDigits] decimals, trailing zeros dropped (`1580.17`, `0.5`, `12`).
String plainNumber(double value, {int maxDigits = 6}) {
  if (!value.isFinite) return '0';
  var s = value.toStringAsFixed(maxDigits);
  if (s.contains('.')) {
    s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }
  return s == '-0' ? '0' : s;
}

/// A money amount for a sheet line: two decimals, no separators (`59.00`).
String plainMoney(double value) =>
    value.isFinite ? value.toStringAsFixed(2) : '0.00';

double _pow10(int n) {
  var r = 1.0;
  for (var i = 0; i < n.abs(); i++) {
    r *= 10;
  }
  return n < 0 ? 1 / r : r;
}

/// `1.071509e+301`, `1e-20`: seven significant figures, trailing zeros
/// dropped, in a form the calculator can read back.
String _scientific(double v) {
  final s = v.toStringAsExponential(6);
  final m = RegExp(r'^(-?\d+(?:\.\d*?)?)0*(e.*)$').firstMatch(s);
  if (m == null) return s;
  return '${m.group(1)!.replaceFirst(RegExp(r'\.$'), '')}${m.group(2)}';
}
