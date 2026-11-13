import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

import 'package:calcmaster/lib_calc.dart';
import 'package:calcmaster/lib_format.dart';
import 'package:calcmaster/sheet/sheet_engine.dart';
import 'package:calcmaster/sheet/sheet_model.dart';

/// Higher-end maths: exact where the true answer is exact, a clear reason
/// where there is no answer, and never a wrong number on screen.
void main() {
  LineResult line(String s) =>
      evaluateSheet([SheetLine(s)], today: DateTime(2026, 11, 13)).lines.single;

  Matcher fails(String message) =>
      throwsA(isA<CalcError>().having((e) => e.message, 'message', message));

  group('no floating-point noise', () {
    test('decimals add up exactly', () {
      expect(evaluate('0.1+0.2'), 0.3);
      expect(evaluate('1.1+2.2'), 3.3);
      expect(evaluate('1-0.9'), 0.1);
      expect(evaluate('3.3*3'), 9.9);
      expect(evaluate('0.1+0.2-0.3'), 0);
    });
    test('logs and roots land on whole numbers', () {
      expect(evaluate('log(1000)'), 3);
      expect(evaluate('log2(8)'), 3);
      expect(evaluate('root(27,3)'), 3);
      expect(evaluate('sin(30°)'), 0.5);
    });
    test('never shows minus zero', () {
      expect(evaluate('-0').isNegative, isFalse);
      expect(line('-0').display, '0');
    });
  });

  group('written the way people write maths', () {
    test('implicit multiplication', () {
      expect(evaluate('2pi'), closeTo(2 * math.pi, 1e-12));
      expect(evaluate('2(3+4)'), 14);
      expect(evaluate('(1+2)(3+4)'), 21);
      expect(evaluate('2sqrt(9)'), 6);
      expect(evaluate('2√9'), 6);
    });
    test('scientific notation', () {
      expect(evaluate('1e3'), 1000);
      expect(evaluate('1.5e-3'), 0.0015);
      expect(evaluate('6.02e23*2'), 1.204e24);
      expect(evaluate('1.5e3 + 2'), 1502);
    });
    test('unary plus, ** for powers, brackets', () {
      expect(evaluate('+3'), 3);
      expect(evaluate('2*+3'), 6);
      expect(evaluate('2**10'), 1024);
      expect(evaluate('[2+3]*2'), 10);
    });
    test('precedence and associativity', () {
      expect(evaluate('2^3^2'), 512);
      expect(evaluate('-2^2'), -4);
      expect(evaluate('2^-1'), 0.5);
      expect(evaluate('3!2'), 12);
      expect(evaluate('5 mod 3'), 2);
    });
  });

  group('functions', () {
    test('degrees with ° or deg, in radian mode', () {
      expect(evaluate('sin(30°)'), 0.5);
      expect(evaluate('cos(60 deg)'), 0.5);
      expect(evaluate('tan(45°)'), 1);
    });
    test('exact trig at the special angles', () {
      expect(evaluate('sin(pi)'), 0);
      expect(evaluate('cos(pi/2)'), 0);
      expect(evaluate('sin(180)', angle: AngleUnit.deg), 0);
      expect(evaluate('cos(90)', angle: AngleUnit.deg), 0);
      expect(evaluate('sin(-90)', angle: AngleUnit.deg), -1);
    });
    test('two-argument functions', () {
      expect(evaluate('log(8,2)'), 3);
      expect(evaluate('nCr(52,5)'), 2598960);
      expect(evaluate('nPr(5,2)'), 20);
      expect(evaluate('max(3,9,4)'), 9);
      expect(evaluate('min(3,9,4)'), 3);
      expect(evaluate('gcd(12,18)'), 6);
      expect(evaluate('lcm(4,6)'), 12);
      expect(evaluate('mod(10,4)'), 2);
      expect(evaluate('round(3.14159,2)'), 3.14);
      expect(evaluate('hypot(3,4)'), 5);
      expect(evaluate('atan2(1,1)', angle: AngleUnit.deg), 45);
    });
    test('factorial and gamma', () {
      expect(evaluate('20!'), 2432902008176640000);
      expect(evaluate('0.5!'), closeTo(math.sqrt(math.pi) / 2, 1e-12));
      expect(evaluate('gamma(5)'), 24);
    });
    test('real odd roots of negative numbers', () {
      expect(evaluate('(-8)^(1/3)'), -2);
      expect(evaluate('(-27)^(1/3)'), -3);
      expect(evaluate('cbrt(-8)'), -2);
      expect(evaluate('root(-32,5)'), -2);
    });
  });

  group('no answer gets a reason, never NaN or infinity', () {
    test('each case says why', () {
      expect(() => evaluate('1/0'), fails('Division by zero'));
      expect(() => evaluate('5 mod 0'), fails('Division by zero'));
      expect(() => evaluate('0^-1'), fails('Division by zero'));
      expect(() => evaluate('sqrt(-1)'),
          fails('No real square root of a negative number'));
      expect(() => evaluate('ln(0)'), fails('A logarithm needs a number above 0'));
      expect(() => evaluate('asin(2)'), fails('asin needs a number from −1 to 1'));
      expect(() => evaluate('tan(90°)'), fails('tan is undefined at this angle'));
      expect(() => evaluate('tan(pi/2)'), fails('tan is undefined at this angle'));
      expect(() => evaluate('171!'), fails('Too large to work out'));
      expect(() => evaluate('(-3)!'), fails('No factorial for a negative whole number'));
      expect(() => evaluate('(-4)^0.5'),
          fails('No real answer (a negative number to a fractional power)'));
      expect(() => evaluate('1.2.3'), throwsA(isA<CalcError>()));
    });
    test('the sheet shows the same reason', () {
      expect(line('sqrt(-1)').message, 'No real square root of a negative number');
      expect(line('tan(90°)').kind, LineKind.error);
    });
  });

  group('the sheet', () {
    test('maths with no digits is worked out, not a heading', () {
      expect(line('sin(pi)').display, '0');
      expect(line('e^2').display, '7.389056');
      expect(line('sqrt(pi)').display, '1.772454');
    });
    test('commas inside a function separate its numbers', () {
      expect(line('log(8,2)').display, '3');
      expect(line('nCr(10,100)').display, '0');
      expect(line('max(1,200, 3)').display, '200');
      // …and outside a function they are still thousands separators.
      expect(line('1,000*2').display, '2,000');
    });
    test('prose with a number in it is still a heading', () {
      expect(line('Q3 receipts 2026').kind, LineKind.heading);
      expect(line('hotel 2 nights').kind, isNot(LineKind.value));
    });
  });

  group('very large and very small numbers display truthfully', () {
    test('past 15 digits, scientific notation instead of a wrong number', () {
      expect(formatNumber(1e20), '1e+20');
      expect(formatNumber(math.pow(2.0, 1000).toDouble()), '1.071509e+301');
      expect(line('100000000000000000000').display, '1e+20');
      expect(line('6.02e23*2').display, '1.204e+24');
    });
    test('tiny numbers are not rounded to 0', () {
      expect(formatNumber(1e-20), '1e-20');
      expect(line('10^-20').display, '1e-20');
    });
    test('the scientific form reads back in', () {
      expect(evaluate(formatNumber(1.234e21)), 1.234e21);
      expect(evaluate(formatNumber(1e-20)), 1e-20);
    });
  });
}
