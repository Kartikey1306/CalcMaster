import 'package:flutter_test/flutter_test.dart';

import 'package:calcmaster/sheet/sheet_engine.dart';
import 'package:calcmaster/sheet/sheet_model.dart';

/// Named variables (`rent = 1200`) and PAID / PENDING stamps.
void main() {
  final today = DateTime(2026, 11, 12);

  SheetEvaluation run(List<SheetLine> lines) =>
      evaluateSheet(lines, today: today);
  SheetEvaluation runText(List<String> lines) =>
      run([for (final l in lines) SheetLine(l)]);

  group('variables', () {
    test('a defined name is usable on every line below', () {
      final e = runText(['rent = 1200', 'rent * 12', 'rent / 3 + 10']);
      expect(e.lines[0].value, 1200);
      expect(e.lines[0].label, 'rent');
      expect(e.lines[1].value, 14400);
      expect(e.lines[2].value, 410);
    });

    test('names are case-insensitive and may use underscores', () {
      final e = runText(['Per_Month = 50', 'per_month * 2']);
      expect(e.lines[1].value, 100);
    });

    test('a variable keeps its unit or currency', () {
      final e = runText(['hotel = 120 EUR', 'hotel * 3']);
      expect(e.lines[1].display, '360.00 EUR');
    });

    test('a variable can be built from other variables', () {
      final e = runText(['qty = 2', 'price = 3', 'res = qty * price + 1', 'res']);
      expect(e.lines[3].value, 7);
    });

    test('redefining a name takes over from that line on', () {
      final e = runText(['x1 = 5', 'x1 + 1', 'x1 = 10', 'x1 + 1']);
      expect(e.lines[1].value, 6);
      expect(e.lines[3].value, 11);
    });

    test('a name used above its definition is not known yet', () {
      final e = runText(['later + 1', 'later = 4']);
      expect(e.lines[0].hasValue, isFalse);
      expect(e.lines[1].value, 4);
    });

    test('units, currencies and keywords cannot be names', () {
      final e = runText(['m = 5', 'usd = 3', 'sqrt = 2']);
      for (final l in e.lines) {
        expect(l.kind, LineKind.error);
      }
      expect(e.lines[0].message, contains('unit or currency'));
      expect(e.lines[2].message, contains('reserved'));
    });

    test('using a variable whose line failed names that line', () {
      final e = runText(['bad = 1 / 0', 'bad + 1']);
      expect(e.lines[0].kind, LineKind.error);
      expect(e.lines[1].kind, LineKind.error);
      expect(e.lines[1].message, contains('line 1'));
    });

    test('a plain-number variable is a setting, not part of the total', () {
      final e = runText(['nights = 3', 'Hotel: 120 EUR * nights', 'total']);
      expect(e.total, 360);
      expect(e.excludedNote, isNull);
      expect(e.lines[2].value, 360);
      // On a sheet of plain numbers too.
      final plain = runText(['people = 4', '100 / people', '50']);
      expect(plain.total, 75);
    });

    test('a variable with a currency still counts', () {
      final e = runText(['deposit = 200 EUR', 'Hotel: 300 EUR']);
      expect(e.total, 500);
    });

    test('prose lines stay headings', () {
      final e = runText(['rent = 1200', 'Notes about the flat']);
      expect(e.lines[1].kind, LineKind.heading);
    });
  });

  group('stamps', () {
    test('footer splits paid and pending in the main currency', () {
      final e = run(const [
        SheetLine('Hotel: 300 EUR', stamp: LineStamp.paid),
        SheetLine('Dinner: 80 EUR', stamp: LineStamp.pending),
        SheetLine('Taxi: 20 EUR'),
        SheetLine('Museum: 15 EUR', stamp: LineStamp.paid),
      ]);
      expect(e.total, 415);
      expect(e.paid, 315);
      expect(e.pending, 80);
      expect(e.stampedCount, 3);
      expect(e.hasStamps, isTrue);
      expect(e.paidDisplay, '315.00 EUR');
    });

    test('no stamps, no split', () {
      final e = runText(['10', '20']);
      expect(e.hasStamps, isFalse);
      expect(e.paid, 0);
    });

    test('a stamped line in another currency is left out of the split', () {
      final e = run(const [
        SheetLine('100 EUR', stamp: LineStamp.paid),
        SheetLine('200 EUR'),
        SheetLine('50 GBP', stamp: LineStamp.paid),
      ]);
      expect(e.paid, 100);
      expect(e.stampedCount, 1);
    });

    test('stamps survive JSON and edits', () {
      const line = SheetLine('Rent: 900', stamp: LineStamp.pending);
      final back = SheetLine.fromJson(line.toJson());
      expect(back.stamp, LineStamp.pending);
      expect(back.withText('Rent: 950').stamp, LineStamp.pending);
      expect(back.withStamp(null).toJson().containsKey('stamp'), isFalse);
      expect(SheetLine.fromJson({'text': 'a', 'stamp': 'bogus'}).stamp, isNull);
    });
  });
}
