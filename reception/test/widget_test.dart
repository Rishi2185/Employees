// Model + serialization tests for the reception app. (The full UI needs a live
// database and backend, so widget smoke tests live closer to integration; these
// guard the data contracts the screens rely on.)

import 'package:aarvy_reception/models/reception_appointment.dart';
import 'package:aarvy_reception/utils/status_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ReceptionAppointment round-trips through the SQLite map', () {
    final original = ReceptionAppointment(
      id: 'apt1',
      doctorId: 'd1',
      doctorName: 'Dr. Asha Rao',
      doctorPhotoUrl: 'http://x/p.png',
      specialtyName: 'Cardiology',
      hospitalName: 'Aarvy Hospital',
      dateTime: DateTime.parse('2026-06-20T10:30:00.000'),
      slotLabel: '10:30 AM',
      fee: 500,
      paymentMethod: 1,
      status: 1,
      reviewed: false,
      dayKey: '2026-06-20',
      patientName: 'Anita Sharma',
      patientPhone: '9990001112',
      patientAge: 34,
      patientGender: 'Female',
      tokenNumber: 12,
      checkedIn: true,
      source: 'walk_in',
      createdBy: 'reception',
    );

    final restored = ReceptionAppointment.fromDbMap(original.toDbMap());

    expect(restored.id, original.id);
    expect(restored.dayKey, original.dayKey);
    expect(restored.status, original.status);
    expect(restored.paymentMethod, original.paymentMethod);
    expect(restored.checkedIn, isTrue);
    expect(restored.tokenNumber, 12);
    expect(restored.patientName, 'Anita Sharma');
    expect(restored.dateTime, original.dateTime);
  });

  test('status integer enum stays patient-app compatible (0/1/2)', () {
    expect(StatusUi.label(0), 'Upcoming');
    expect(StatusUi.label(1), 'Completed');
    expect(StatusUi.label(2), 'Cancelled');
    // Unknown values degrade gracefully instead of crashing.
    expect(StatusUi.label(9), 'Unknown');
  });

  test('fromJson tolerates _id and missing optional fields', () {
    final a = ReceptionAppointment.fromJson({
      '_id': 'apt2',
      'doctorId': 'd2',
      'dateTime': '2026-06-21T09:00:00.000Z',
      'dayKey': '2026-06-21',
      'status': 0,
    });
    expect(a.id, 'apt2');
    expect(a.doctorName, '');
    expect(a.status, 0);
    expect(a.paymentMethod, 1); // default
  });
}
