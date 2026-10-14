/// Share-as-text and CSV for a sheet. Pure Dart.
///
/// Every currency line carries its ECB rate, the date of that rate, and the
/// source, so the export can stand as the working for an expense claim or an
/// invoice note. An error line exports its reason — never a number.
library;

import 'sheet_engine.dart';
import 'sheet_model.dart';

const String rateAttribution =
    'Reference rates: European Central Bank, via Frankfurter '
    '(api.frankfurter.dev). Reference rates are not the rate your bank or '
    'card charged.';

String _body(String text, String? label) {
  final t = text.trim();
  if (label == null) return t;
  final colon = t.indexOf(': ');
  return colon > 0 ? t.substring(colon + 2).trim() : t;
}

String _rateNote(RateUse r) => '(ECB ${r.rate.rate}, ${r.rate.ecbDate})';

String _numberOnly(LineResult r) =>
    formatAmount(r.value!, r.tag).replaceAll(',', '');

/// The sheet as plain text:
///
///     Trip to Lisbon
///     Dinner: 38.50 EUR on 14 Sep in USD  →  44.47 USD (ECB 1.1551, 2026-09-14)
///     Total  →  44.47 USD
///
///     Reference rates: European Central Bank, via Frankfurter …
String sheetAsText(Sheet sheet, SheetEvaluation eval) {
  final b = StringBuffer()..writeln(sheet.displayTitle)..writeln();
  var usedRates = false;
  for (var i = 0; i < sheet.lines.length; i++) {
    final text = sheet.lines[i].text.trim();
    final r = i < eval.lines.length ? eval.lines[i] : null;
    if (r == null || r.kind == LineKind.blank) {
      b.writeln();
      continue;
    }
    switch (r.kind) {
      case LineKind.heading:
        b.writeln(text);
      case LineKind.value:
        final rate = r.rate;
        if (rate != null) usedRates = true;
        b.writeln('$text  →  ${r.display}'
            '${rate == null ? '' : ' ${_rateNote(rate)}'}');
      case LineKind.error:
      case LineKind.needsRate:
        b.writeln('$text  →  ${r.message}');
      case LineKind.blank:
        b.writeln();
    }
  }
  if (eval.hasValues) {
    b.writeln();
    b.writeln('Total  →  ${eval.totalDisplay}'
        '${eval.excludedNote == null ? '' : ' (${eval.excludedNote})'}');
  }
  if (usedRates) {
    b.writeln();
    b.writeln(rateAttribution);
  }
  return b.toString().trimRight();
}

String _csvField(String s) {
  if (s.contains(',') || s.contains('"') || s.contains('\n')) {
    return '"${s.replaceAll('"', '""')}"';
  }
  return s;
}

const csvHeader = 'line,label,input,result,unit_or_currency,ecb_rate,ecb_date';

/// The sheet as CSV with the columns in [csvHeader]: one row per non-blank
/// line, then the total, then the rate source when any rate was used.
String sheetAsCsv(Sheet sheet, SheetEvaluation eval) {
  final rows = <List<String>>[];
  var usedRates = false;
  for (var i = 0; i < sheet.lines.length && i < eval.lines.length; i++) {
    final r = eval.lines[i];
    if (r.kind == LineKind.blank) continue;
    final text = sheet.lines[i].text;
    switch (r.kind) {
      case LineKind.heading:
        rows.add(['${r.number}', '', text.trim(), '', '', '', '']);
      case LineKind.value:
        final rate = r.rate;
        if (rate != null) usedRates = true;
        rows.add([
          '${r.number}',
          r.label ?? '',
          r.isTotal && r.label == 'Total' ? 'total' : _body(text, r.label),
          _numberOnly(r),
          r.tag?.label ?? '',
          rate == null ? '' : '${rate.rate.rate}',
          rate == null ? '' : rate.rate.ecbDate,
        ]);
      case LineKind.error:
      case LineKind.needsRate:
        rows.add([
          '${r.number}',
          r.label ?? '',
          _body(text, r.label),
          r.message ?? '',
          '',
          '',
          '',
        ]);
      case LineKind.blank:
        break;
    }
  }
  if (eval.hasValues) {
    rows.add([
      '',
      'Total',
      eval.excludedNote ?? '',
      formatAmount(eval.total, eval.mainTag).replaceAll(',', ''),
      eval.mainTag?.label ?? '',
      '',
      '',
    ]);
  }
  if (usedRates) rows.add(['', rateAttribution, '', '', '', '', '']);
  return [
    csvHeader,
    for (final row in rows) row.map(_csvField).join(','),
  ].join('\n');
}
