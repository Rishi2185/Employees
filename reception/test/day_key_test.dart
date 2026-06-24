import 'package:aarvy_reception/utils/day_key.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('isBefore uses lexical YYYY-MM-DD ordering', () {
    expect(DayKey.isBefore('2026-06-19', '2026-06-20'), isTrue);
    expect(DayKey.isBefore('2026-06-20', '2026-06-20'), isFalse);
    expect(DayKey.isBefore('2026-07-01', '2026-06-30'), isFalse);
  });

  test('previous rolls back across month boundaries', () {
    expect(DayKey.previous('2026-06-01'), '2026-05-31');
    expect(DayKey.previous('2026-01-01'), '2025-12-31');
    expect(DayKey.previous('2026-06-20'), '2026-06-19');
  });

  test('parse and format round-trip', () {
    final d = DayKey.parse('2026-06-23');
    expect(d.year, 2026);
    expect(d.month, 6);
    expect(d.day, 23);
    expect(DayKey.format(d), '2026-06-23');
  });

  test('format zero-pads month and day', () {
    expect(DayKey.format(DateTime(2026, 1, 5)), '2026-01-05');
  });
}
