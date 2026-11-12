import 'package:flutter_test/flutter_test.dart';

import 'package:calcmaster/sheet/sheet_engine.dart';
import 'package:calcmaster/sheet/sheet_model.dart';
import 'package:calcmaster/sheet/smart_suggest.dart';

/// The smart line reader: loosely typed, misspelt lines become sheet lines.
void main() {
  final today = DateTime(2026, 11, 12);

  /// Works a suggested line out with the real sheet engine.
  LineResult work(String line) =>
      evaluateSheet([SheetLine(line)], today: today).lines.single;

  SmartSuggestion pick(List<SmartSuggestion> s, String title) =>
      s.firstWhere((x) => x.title == title,
          orElse: () => throw StateError('no "$title" in $s'));

  group('reading', () {
    test('typos everywhere: "finner 18 eurp for 2 peoer"', () {
      final r = readLine('finner 18 eurp for 2 peoer');
      expect(r.label, 'Dinner');
      expect(r.amount, 18);
      expect(r.currency, 'EUR');
      expect(r.people, 2);
    });

    test('symbols, words and codes for currencies', () {
      expect(readLine('taxi €25').currency, 'EUR');
      expect(readLine('lunch 12 dollars').currency, 'USD');
      expect(readLine('hotel 300 quid').currency, 'GBP');
      expect(readLine('groceries 1500 rupees').currency, 'INR');
      expect(readLine('coffee 4.50 gbp').amount, 4.5);
    });

    test('ways to say how many people', () {
      expect(readLine('pizza 40 split 4 ways').people, 4);
      expect(readLine('rent 2400 between 3').people, 3);
      expect(readLine('dinner 90 for 3').people, 3);
      expect(readLine('drinks 60 6 friends').people, 6);
      expect(readLine('tour 200 for 4 persons').people, 4);
    });

    test('tip, tax and discount percentages', () {
      final r = readLine('dinner 80 usd 18% tip 8% tax');
      expect(r.tipPct, 18);
      expect(r.taxPct, 8);
      expect(readLine('shoes 120 30% off').offPct, 30);
      expect(readLine('meal 50 tip 15%').tipPct, 15);
    });

    test('a target currency', () {
      expect(readLine('hotel 120 euro in dollars').target, 'USD');
      expect(readLine('flight 300 gbp to eur').target, 'EUR');
    });

    test('nothing to work out', () {
      expect(suggestLines('Trip to Rome'), isEmpty);
      expect(suggestLines(''), isEmpty);
    });
  });

  group('suggestions work on the sheet', () {
    test('per person, with tip, whole bill, in home currency', () {
      final s = suggestLines('finner 18 eurp for 2 peoer',
          homeCurrency: 'USD', customaryTip: 10);
      final each = work(pick(s, 'Per person').line);
      expect(each.display, '9.00 EUR');
      expect(each.label, 'Dinner per person');

      final withTip = work(pick(s, '+ 10% tip, each').line);
      expect(withTip.display, '9.90 EUR');

      expect(work(pick(s, 'Whole bill').line).display, '18.00 EUR');

      // Needs an ECB rate, which the sheet then fetches.
      final usd = work(pick(s, 'In USD, each').line);
      expect(usd.kind, LineKind.needsRate);
    });

    test('discount, tax and tip chain in order', () {
      final s = suggestLines('shoes 100 usd 20% off 10% tax');
      // 100 − 20% = 80, + 10% = 88.
      expect(work(s.first.line).display, '88.00 USD');
    });

    test('split with a named tip', () {
      final s = suggestLines('dinner 120 eur 15% tip split 3 ways');
      expect(work(pick(s, 'Per person').line).display, '46.00 EUR');
    });

    test('plain numbers with people', () {
      final s = suggestLines('rent 2400 between 3');
      expect(work(pick(s, 'Per person').line).value, 800);
    });

    test('a dinner on its own offers the customary tip', () {
      final s = suggestLines('dinner 50 eur', customaryTip: 18);
      expect(s.map((x) => x.title), contains('+ 18% tip'));
      expect(work(pick(s, '+ 18% tip').line).display, '59.00 EUR');
    });

    test('no home-currency suggestion when already home', () {
      final s = suggestLines('taxi 20 usd for 2', homeCurrency: 'USD');
      expect(s.any((x) => x.title.startsWith('In ')), isFalse);
    });
  });
}
