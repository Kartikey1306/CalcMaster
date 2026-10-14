import 'package:flutter_test/flutter_test.dart';

import 'package:calcmaster/lib_currency.dart';
import 'package:calcmaster/sheet/sheet_engine.dart';
import 'package:calcmaster/sheet/sheet_model.dart';

/// The sheet's line grammar (spec M1), worked through the pure-Dart engine.
final _today = DateTime(2026, 10, 13);

SheetEvaluation _eval(List<String> lines,
        {RateBook rates = const RateBook(), List<RatePin?>? pins}) =>
    evaluateSheet([
      for (var i = 0; i < lines.length; i++)
        SheetLine(lines[i], pin: pins == null ? null : pins[i]),
    ], rates: rates, today: _today);

LineResult _one(String line, {RateBook rates = const RateBook()}) =>
    _eval([line], rates: rates).lines.single;

const _table = RatesResult(
  rates: {'USD': 1, 'EUR': 0.89437, 'GBP': 0.75555, 'JPY': 151.2},
  fetchedAt: 1,
  date: '2026-10-12',
  live: true,
);

void main() {
  group('line kinds', () {
    test('blank and heading lines have no result', () {
      final e = _eval(['', 'Trip to Lisbon', 'Q3 receipts 2026', 'Dinner:']);
      expect(e.lines.map((l) => l.kind), [
        LineKind.blank,
        LineKind.heading,
        LineKind.heading,
        LineKind.heading,
      ]);
      expect(e.lines.every((l) => l.display == null), isTrue);
    });

    test('arithmetic goes through lib_calc', () {
      expect(_one('12 * (3 + 4)').display, '84');
      expect(_one('2^10').display, '1,024');
      expect(_one('sqrt(16) + 1').display, '5');
      expect(_one('7 ÷ 2 × 3 − 1').display, '9.5');
      expect(_one('1,250.50 + 10').display, '1,260.5');
      expect(_one('5 x 3').display, '15');
    });

    test('a label sits left of the result', () {
      final r = _one('Hotel: 120 + 30');
      expect(r.label, 'Hotel');
      expect(r.display, '150');
    });
  });

  group('references', () {
    test('#n and prev read other lines', () {
      final e = _eval(['10', '#1 * 3', 'prev + 2', '#2 + #3']);
      expect(e.lines.map((l) => l.display), ['10', '30', '32', '62']);
    });

    test('a reference to a line without a result is an error on the '
        'referencing line', () {
      final e = _eval(['Heading', '#1 + 1', '#9', '#4', 'prev']);
      expect(e.lines[1].kind, LineKind.error);
      expect(e.lines[1].message, 'Line 1 has no result');
      expect(e.lines[2].message, '#9: there is no line 9');
      expect(e.lines[3].message, '#4 refers to this line');
      expect(e.lines[4].kind, LineKind.error);
    });

    test('a reference carries its currency', () {
      final e = _eval(['20 EUR', '#1 * 2']);
      expect(e.lines[1].display, '40.00 EUR');
    });
  });

  group('percentages', () {
    test('expr + N%, expr - N%, N% of expr', () {
      final e = _eval(['200', '#1 + 18%', '#1 - 10%', '18% of #1', '50%']);
      expect(e.lines.map((l) => l.display),
          ['200', '236', '180', '36', '0.5']);
    });

    test('a percentage keeps the amount\'s currency', () {
      expect(_one('80 USD + 15%').display, '92.00 USD');
    });
  });

  group('units', () {
    test('12 ft in m is 3.6576 m', () {
      final r = _one('12 ft in m');
      expect(r.display, '3.6576 m');
      expect(r.tag!.label, 'm');
    });

    test('aliases across categories', () {
      expect(_one('5 feet to metres').display, '1.524 m');
      expect(_one("6' in cm").display, '182.88 cm');
      expect(_one('10 kg in lb').display, '22.0462 lb');
      expect(_one('100 °C in F').display, '212 °F');
      expect(_one('2 gal in l').display, '7.5708 L');
      expect(_one('60 mph in km/h').display, '96.5606 km/h');
      expect(_one('12 in in cm').display, '30.48 cm');
    });

    test('same-kind units are combined in the first unit', () {
      expect(_one('2 m + 30 cm').display, '2.3 m');
    });

    test('an incompatible pair says so', () {
      final r = _one('3 kg in m');
      expect(r.kind, LineKind.error);
      expect(r.message, "Can't convert kg to m");
    });
  });

  group('currencies', () {
    test('codes and symbols tag an amount', () {
      expect(_one('38.50 EUR').display, '38.50 EUR');
      expect(_one('€12 * 3').display, '36.00 EUR');
      expect(_one('£5 + 2').display, '7.00 GBP');
    });

    test('an undated conversion uses today\'s ECB table and is pinned', () {
      final r = _one('38.50 EUR in USD', rates: const RateBook(latest: _table));
      expect(r.display, '43.05 USD');
      expect(r.rate!.caption, 'ECB 1.1181 · 12 Oct 2026');
      expect(r.newPin, isNotNull);
      expect(r.newPin!.date, '2026-10-12');
    });

    test('a non-ECB currency is refused with the reason, never a number', () {
      for (final line in ['50 AED in USD', '100 USD in AED', '50 AED']) {
        final r = _one(line, rates: const RateBook(latest: _table));
        expect(r.kind, LineKind.error, reason: line);
        expect(r.message, 'The ECB publishes no reference rate for AED');
        expect(r.display, isNull);
      }
    });

    test('mixing currencies on one line is an error', () {
      final r = _one('10 EUR + 5 GBP');
      expect(r.message, contains("Can't mix EUR and GBP"));
    });

    test('without any rate the line waits and asks for one', () {
      final e = _eval(['38.50 EUR in USD']);
      expect(e.lines.single.kind, LineKind.needsRate);
      expect(e.needs.single.date, isNull);
    });
  });

  group('dates', () {
    test('formats and the most recent past day', () {
      DateTime? d(String s) => parseSheetDate(s, _today);
      expect(d('2026-09-14'), DateTime.utc(2026, 9, 14));
      expect(d('14 Sep'), DateTime.utc(2026, 9, 14));
      expect(d('Sep 14, 2025'), DateTime.utc(2025, 9, 14));
      // 20 December has not happened yet this year: last year's.
      expect(d('20 Dec'), DateTime.utc(2025, 12, 20));
      expect(d('today'), DateTime.utc(2026, 10, 13));
      expect(d('31 Feb 2026'), isNull);
      expect(d('someday'), isNull);
    });

    test('before the ECB started and in the future are reasons', () {
      expect(_one('38 EUR on 1998-12-01 in USD').message,
          'ECB rates start on 4 Jan 1999');
      expect(_one('38 EUR on 2030-01-01 in USD').message,
          'That date is in the future');
    });

    test('a dated line without a target says what to add', () {
      expect(_one('100 EUR on 14 Sep').message,
          'Add the currency to convert to, e.g. "… on 14 Sep in USD"');
    });
  });

  group('errors', () {
    test('never NaN or Infinity, never a crash', () {
      for (final line in ['10/0', '0/0', '(2 + 3', 'sqrt(-1)', '5 +', '#0']) {
        final r = _one(line);
        expect(r.kind, LineKind.error, reason: line);
        expect(r.message, isNotEmpty);
        expect(r.display, isNull);
      }
      expect(_one('10/0').message, 'Not a number (division by zero?)');
    });
  });

  group('total', () {
    test('the footer adds the main currency and names what it left out', () {
      final e = _eval([
        'Taxi: 20 USD',
        'Lunch: 12.50 USD',
        'Hotel: 90 GBP',
        'Museum: 15 GBP',
        'Boxes: 3',
        'Train: 30 USD',
      ]);
      expect(e.mainTag!.label, 'USD');
      expect(e.totalDisplay, '62.50 USD');
      expect(e.excludedCount, 3);
      expect(e.excludedNote, 'Total excludes 3 lines');
    });

    test('lines in one other currency are named', () {
      final e = _eval(['20 USD', '30 USD', '90 GBP', '15 GBP']);
      expect(e.excludedNote, 'Total excludes 2 lines in GBP');
    });

    test('plain numbers total when nothing carries a tag', () {
      final e = _eval(['10', '20', 'Heading', '5']);
      expect(e.mainTag, isNull);
      expect(e.totalDisplay, '35');
      expect(e.excludedNote, isNull);
    });

    test('a total line sums the footer\'s tag above it', () {
      final e = _eval(['12 ft in m', '2.5 m', '4 kg', 'total']);
      expect(e.lines[3].isTotal, isTrue);
      expect(e.lines[3].display, '6.1576 m');
      // The total line itself is not counted twice.
      expect(e.totalDisplay, '6.1576 m');
      expect(e.excludedNote, 'Total excludes 1 line in kg');
    });

    test('a waiting currency line is left out of the total and counted', () {
      final e = _eval(['20 USD', '38.50 EUR on 14 Sep in USD']);
      expect(e.totalDisplay, '20.00 USD');
      expect(e.excludedNote, 'Total excludes 1 line');
    });
  });

  test('formatRate keeps five significant figures', () {
    expect(formatRate(1.1551), '1.1551');
    expect(formatRate(0.85598), '0.85598');
    expect(formatRate(162.391), '162.39');
    expect(formatRate(1.12), '1.12');
  });
}
