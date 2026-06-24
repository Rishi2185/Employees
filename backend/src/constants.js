'use strict';

/**
 * Shared enums. The integer values for status & paymentMethod MUST match the
 * patient Flutter app's enum indices exactly — the app serializes them as
 * `enum.index` and reconstructs via `Enum.values[index]`. Sending any other
 * value (or a 4th status) would crash `Appointment.fromJson` on that side.
 *
 *   patient: AppointmentStatus { upcoming, completed, cancelled }   // 0,1,2
 *   patient: PaymentMethod     { card, upi, wallet }                // 0,1,2
 */
const APPOINTMENT_STATUS = Object.freeze({
  UPCOMING: 0,
  COMPLETED: 1,
  CANCELLED: 2,
});

const APPOINTMENT_STATUS_LABELS = Object.freeze({
  0: 'upcoming',
  1: 'completed',
  2: 'cancelled',
});

const PAYMENT_METHOD = Object.freeze({
  CARD: 0,
  UPI: 1,
  WALLET: 2,
});

const PAYMENT_METHOD_LABELS = Object.freeze({
  0: 'card',
  1: 'upi',
  2: 'wallet',
});

// Where an appointment originated. Stored as a string; not sent to the patient
// app's strict fromJson (extra fields are simply ignored there).
const APPOINTMENT_SOURCE = Object.freeze({
  PATIENT_APP: 'patient_app',
  RECEPTION_WALKIN: 'reception_walkin',
  RECEPTION_BOOKING: 'reception_booking',
});

const ROLES = Object.freeze({
  ADMIN: 'admin',
  RECEPTION: 'reception',
});

module.exports = {
  APPOINTMENT_STATUS,
  APPOINTMENT_STATUS_LABELS,
  PAYMENT_METHOD,
  PAYMENT_METHOD_LABELS,
  APPOINTMENT_SOURCE,
  ROLES,
};
