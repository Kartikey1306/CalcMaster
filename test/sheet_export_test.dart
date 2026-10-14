import 'package:flutter_test/flutter_test.dart';

import 'package:calcmaster/lib_currency.dart';
import 'package:calcmaster/sheet/sheet_engine.dart';
import 'package:calcmaster/sheet/sheet_export.dart';
import 'package:calcmaster/sheet/sheet_model.dart';

/// Share as text and Export CSV (spec M4) for one mixed sheet: a heading,
/// units, a dated EUR line, a pinned GBP line and an error line.
void main() {
  final sheet = Sheet(
    id: 's1',
    title: 'Lisbon expenses',
    createdAt: 0,
    updatedAt: 0,
    lines: const [
      SheetLine('Trip to Lisbon'),
      SheetLine('Shelf: 12 ft in m'),
      SheetLine('Dinner: 38.50 EUR on 2026-09-14 in USD'),
      SheetLine('Hotel: 120 GBP in USD',
          pin: RatePin(
              base: 'GBP', quote: 'USD', rate: 1.3524, date: '2026-10-09')),
      SheetLine('Ferry: 30 AED in USD'),
    ],
  );
  final eval = evaluateSheet(
    sheet.lines,
    rates: RateBook(dated: {
      datedRateKey('2026-09-14', 'EUR', 'USD'): const EcbRate(
          base: 'EUR', quote: 'USD', rate: 1.1551, ecbDate: '2026-09-14'),
    }),
    today: DateTime(2026, 10, 13),
  );

  test('text: one line per sheet line, rates with their dates, the total and '
      'the source', () {
    expect(
      sheetAsText(sheet, eval),
      'Lisbon expenses\n'
      '\n'
      'Trip to Lisbon\n'
      'Shelf: 12 ft in m  →  3.6576 m\n'
      'Dinner: 38.50 EUR on 2026-09-14 in USD  →  44.47 USD (ECB 1.1551, 2026-09-14)\n'
      'Hotel: 120 GBP in USD  →  162.29 USD (ECB 1.3524, 2026-10-09)\n'
      'Ferry: 30 AED in USD  →  The ECB publishes no reference rate for AED\n'
      '\n'
      'Total  →  206.76 USD (Total excludes 1 line in m)\n'
      '\n'
      'Reference rates: European Central Bank, via Frankfurter '
      '(api.frankfurter.dev). Reference rates are not the rate your bank or '
      'card charged.',
    );
  });

  test('CSV: the documented columns, rate and date per currency line', () {
    expect(
      sheetAsCsv(sheet, eval),
      'line,label,input,result,unit_or_currency,ecb_rate,ecb_date\n'
      '1,,Trip to Lisbon,,,,\n'
      '2,Shelf,12 ft in m,3.6576,m,,\n'
      '3,Dinner,38.50 EUR on 2026-09-14 in USD,44.47,USD,1.1551,2026-09-14\n'
      '4,Hotel,120 GBP in USD,162.29,USD,1.3524,2026-10-09\n'
      '5,Ferry,30 AED in USD,The ECB publishes no reference rate for AED,,,\n'
      ',Total,Total excludes 1 line in m,206.76,USD,,\n'
      ',"Reference rates: European Central Bank, via Frankfurter '
      '(api.frankfurter.dev). Reference rates are not the rate your bank or '
      'card charged.",,,,,',
    );
  });

  test('an error line exports its reason, never a number', () {
    final err = Sheet(
        id: 'e',
        title: 'E',
        createdAt: 0,
        updatedAt: 0,
        lines: const [SheetLine('10 / 0')]);
    final e = evaluateSheet(err.lines, today: DateTime(2026, 10, 13));
    final csv = sheetAsCsv(err, e).split('\n');
    expect(csv[1], '1,,10 / 0,Not a number (division by zero?),,,');
    expect(sheetAsText(err, e), contains('10 / 0  →  Not a number'));
    expect(sheetAsText(err, e), isNot(contains('Infinity')));
    expect(sheetAsText(err, e), isNot(contains('Total')));
  });

  test('a field with a comma or quote is quoted', () {
    final s = Sheet(
        id: 'q',
        title: 'Q',
        createdAt: 0,
        updatedAt: 0,
        lines: const [SheetLine('Paint, "matt": 2 * 14')]);
    final e = evaluateSheet(s.lines, today: DateTime(2026, 10, 13));
    expect(sheetAsCsv(s, e).split('\n')[1], '1,"Paint, ""matt""",2 * 14,28,,,');
  });
}
