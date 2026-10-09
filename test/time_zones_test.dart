import 'package:flutter_test/flutter_test.dart';

import 'package:calcmaster/screens/tools/tools_screens.dart';

void main() {
  DateTime u(int y, int m, int d, [int h = 0, int min = 0]) =>
      DateTime.utc(y, m, d, h, min);

  group('utcOffsetHours', () {
    test('places without daylight saving keep their standard offset', () {
      expect(utcOffsetHours(5.5, DstRule.none, u(2026, 1, 15)), 5.5);
      expect(utcOffsetHours(5.5, DstRule.none, u(2026, 7, 15)), 5.5);
    });

    test('New York: EST in winter, EDT in summer, switching on 2026 dates', () {
      expect(utcOffsetHours(-5, DstRule.us, u(2026, 1, 15)), -5);
      expect(utcOffsetHours(-5, DstRule.us, u(2026, 7, 15)), -4);
      // 2026-03-08 02:00 EST = 07:00 UTC; 2026-11-01 02:00 EDT = 06:00 UTC.
      expect(utcOffsetHours(-5, DstRule.us, u(2026, 3, 8, 6, 59)), -5);
      expect(utcOffsetHours(-5, DstRule.us, u(2026, 3, 8, 7)), -4);
      expect(utcOffsetHours(-5, DstRule.us, u(2026, 11, 1, 5, 59)), -4);
      expect(utcOffsetHours(-5, DstRule.us, u(2026, 11, 1, 6)), -5);
    });

    test('Cupertino switches at 02:00 Pacific', () {
      expect(utcOffsetHours(-8, DstRule.us, u(2026, 3, 8, 9, 59)), -8);
      expect(utcOffsetHours(-8, DstRule.us, u(2026, 3, 8, 10)), -7);
    });

    test('London and Berlin follow the EU 01:00 UTC switch', () {
      // 2026: last Sundays are 29 March and 25 October.
      expect(utcOffsetHours(0, DstRule.eu, u(2026, 3, 29, 0, 59)), 0);
      expect(utcOffsetHours(0, DstRule.eu, u(2026, 3, 29, 1)), 1);
      expect(utcOffsetHours(1, DstRule.eu, u(2026, 10, 25, 0, 59)), 2);
      expect(utcOffsetHours(1, DstRule.eu, u(2026, 10, 25, 1)), 1);
      expect(utcOffsetHours(0, DstRule.eu, u(2026, 12, 1)), 0);
    });

    test('Sydney is on AEDT (+11) from the first Sunday of October', () {
      // 2026-10-04 02:00 AEST = 2026-10-03 16:00 UTC.
      expect(
          utcOffsetHours(10, DstRule.auSoutheast, u(2026, 10, 3, 15, 59)), 10);
      expect(utcOffsetHours(10, DstRule.auSoutheast, u(2026, 10, 3, 16)), 11);
      expect(utcOffsetHours(10, DstRule.auSoutheast, u(2026, 10, 9)), 11);
      // 2026-04-05 03:00 AEDT = 2026-04-04 16:00 UTC.
      expect(
          utcOffsetHours(10, DstRule.auSoutheast, u(2026, 4, 4, 15, 59)), 11);
      expect(utcOffsetHours(10, DstRule.auSoutheast, u(2026, 4, 4, 16)), 10);
      expect(utcOffsetHours(10, DstRule.auSoutheast, u(2026, 7, 1)), 10);
    });
  });
}
