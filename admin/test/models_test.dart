import 'package:aarvy_admin/models/doctor.dart';
import 'package:aarvy_admin/models/doctor_input.dart';
import 'package:aarvy_admin/models/live_stats.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LiveStats', () {
    final json = {
      'dayKey': '2026-06-23',
      'today': {
        'todaysAppointments': 10,
        'completed': 4,
        'pending': 5,
        'cancelled': 1,
        'walkIns': 2,
      },
      'perDoctor': [
        {'doctorId': 'd1', 'doctorName': 'Dr. A', 'total': 6, 'completed': 3, 'cancelled': 0, 'pending': 3},
        {'doctorId': 'd2', 'doctorName': 'Dr. B', 'total': 4, 'completed': 1, 'cancelled': 1, 'pending': 2},
      ],
      'future': {'upcoming': 7},
    };

    test('parses nested today/perDoctor/future', () {
      final s = LiveStats.fromJson(json);
      expect(s.dayKey, '2026-06-23');
      expect(s.today.completed, 4);
      expect(s.perDoctor.length, 2);
      expect(s.futureUpcoming, 7);
    });

    test('attended and remaining sum across doctors', () {
      final s = LiveStats.fromJson(json);
      expect(s.attended, 4); // 3 + 1
      expect(s.remaining, 5); // 3 + 2
    });

    test('per-doctor progress is completed/total', () {
      final s = LiveStats.fromJson(json);
      expect(s.perDoctor[0].progress, closeTo(0.5, 1e-9));
    });

    test('tolerates missing future / empty perDoctor', () {
      final s = LiveStats.fromJson({'dayKey': '2026-06-23', 'today': {}});
      expect(s.futureUpcoming, 0);
      expect(s.perDoctor, isEmpty);
      expect(s.attended, 0);
    });
  });

  group('DoctorInput', () {
    test('round-trips from a Doctor and serializes required fields', () {
      const doc = Doctor(
        id: 'd1',
        name: 'Dr. Asha Rao',
        specialtyId: 'cardiology',
        specialtyName: 'Cardiology',
        consultationFee: 600,
        experienceYears: 12,
        availableToday: true,
      );
      final input = DoctorInput.fromDoctor(doc);
      final json = input.toJson();
      expect(json['name'], 'Dr. Asha Rao');
      expect(json['specialtyId'], 'cardiology');
      expect(json['consultationFee'], 600);
      expect(json['availableToday'], true);
      expect(json['active'], true);
    });

    test('validate() rejects missing name and specialty', () {
      expect(DoctorInput(name: '', specialtyId: 'x', specialtyName: 'X').validate(),
          isNotNull);
      expect(DoctorInput(name: 'Dr. X', specialtyId: '', specialtyName: '').validate(),
          isNotNull);
    });

    test('validate() passes a complete input', () {
      final ok = DoctorInput(
        name: 'Dr. X',
        specialtyId: 'derm',
        specialtyName: 'Dermatology',
        consultationFee: 400,
      );
      expect(ok.validate(), isNull);
    });

    test('validate() rejects out-of-range rating', () {
      final bad = DoctorInput(
        name: 'Dr. X',
        specialtyId: 'derm',
        specialtyName: 'Dermatology',
        rating: 7,
      );
      expect(bad.validate(), isNotNull);
    });
  });

  group('Doctor.copyWith', () {
    test('replaces only the given field', () {
      const doc = Doctor(
          id: 'd1', name: 'Dr. A', specialtyId: 's', specialtyName: 'S', active: true);
      final off = doc.copyWith(active: false);
      expect(off.active, isFalse);
      expect(off.name, 'Dr. A');
      expect(off.id, 'd1');
    });
  });
}
