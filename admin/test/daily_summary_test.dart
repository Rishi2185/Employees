import 'package:aarvy_admin/models/daily_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DailySummary.fromJson hardening', () {
    test('parses a full summary', () {
      final s = DailySummary.fromJson({
        'dayKey': '2026-06-20',
        'date': '2026-06-20T00:00:00.000Z',
        'overall': {'total': 9, 'completed': 7, 'cancelled': 2, 'pending': 0},
        'perDoctor': [
          {'doctorId': 'd1', 'doctorName': 'Dr. A', 'total': 5, 'completed': 4},
        ],
      });
      expect(s.dayKey, '2026-06-20');
      expect(s.overall.total, 9);
      expect(s.perDoctor.single.doctorName, 'Dr. A');
    });

    test('does not crash when overall/perDoctor are absent', () {
      // Regression: a missing `overall` used to throw on the const {} cast.
      final s = DailySummary.fromJson({
        '_id': '2026-06-21',
        'date': '2026-06-21T00:00:00.000Z',
      });
      expect(s.dayKey, '2026-06-21');
      expect(s.overall.total, 0);
      expect(s.perDoctor, isEmpty);
    });

    test('does not crash on a missing/invalid date', () {
      final s = DailySummary.fromJson({'dayKey': '2026-06-22'});
      expect(s.dayKey, '2026-06-22');
      expect(s.date, DateTime.fromMillisecondsSinceEpoch(0));
    });
  });
}
