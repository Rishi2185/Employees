'use strict';

const Appointment = require('../models/Appointment');
const DailySummary = require('../models/DailySummary');
const { APPOINTMENT_STATUS, APPOINTMENT_SOURCE } = require('../constants');
const { todayKey } = require('../utils/dayKey');

const { UPCOMING, COMPLETED, CANCELLED } = APPOINTMENT_STATUS;

// Shared $group stage that turns a set of appointments into overall counts.
// "pending" == still upcoming (not yet completed/cancelled) within the window.
const OVERALL_GROUP = {
  _id: null,
  total: { $sum: 1 },
  completed: { $sum: { $cond: [{ $eq: ['$status', COMPLETED] }, 1, 0] } },
  cancelled: { $sum: { $cond: [{ $eq: ['$status', CANCELLED] }, 1, 0] } },
  pending: { $sum: { $cond: [{ $eq: ['$status', UPCOMING] }, 1, 0] } },
  walkIns: {
    $sum: {
      $cond: [{ $eq: ['$source', APPOINTMENT_SOURCE.RECEPTION_WALKIN] }, 1, 0],
    },
  },
  revenue: { $sum: { $cond: [{ $eq: ['$status', COMPLETED] }, '$fee', 0] } },
};

const EMPTY_OVERALL = {
  total: 0,
  completed: 0,
  cancelled: 0,
  pending: 0,
  walkIns: 0,
  revenue: 0,
};

async function overallFor(match) {
  const [row] = await Appointment.aggregate([
    { $match: match },
    { $group: OVERALL_GROUP },
  ]);
  if (!row) return { ...EMPTY_OVERALL };
  const { _id, ...counts } = row;
  return counts;
}

async function perDoctorFor(match) {
  const rows = await Appointment.aggregate([
    { $match: match },
    {
      $group: {
        _id: '$doctorId',
        doctorName: { $first: '$doctorName' },
        total: { $sum: 1 },
        completed: { $sum: { $cond: [{ $eq: ['$status', COMPLETED] }, 1, 0] } },
        cancelled: { $sum: { $cond: [{ $eq: ['$status', CANCELLED] }, 1, 0] } },
        pending: { $sum: { $cond: [{ $eq: ['$status', UPCOMING] }, 1, 0] } },
      },
    },
    { $sort: { total: -1, doctorName: 1 } },
  ]);
  return rows.map((r) => ({
    doctorId: r._id,
    doctorName: r.doctorName,
    total: r.total,
    completed: r.completed,
    cancelled: r.cancelled,
    pending: r.pending,
  }));
}

/**
 * Compute overall + per-doctor counts for a single day. Shared by the live
 * dashboard and by the end-of-day summary writer (single source of truth).
 */
async function computeDay(dayKey) {
  const match = { dayKey };
  const [overall, perDoctor] = await Promise.all([
    overallFor(match),
    perDoctorFor(match),
  ]);
  return { overall, perDoctor };
}

/** GET /stats/today — reception dashboard header counts for today. */
async function today() {
  const key = todayKey();
  const overall = await overallFor({ dayKey: key });
  return {
    dayKey: key,
    todaysAppointments: overall.total,
    completed: overall.completed,
    pending: overall.pending,
    cancelled: overall.cancelled,
    walkIns: overall.walkIns,
  };
}

/** GET /stats/doctors?date= — per-doctor breakdown for a day (default today). */
async function doctorsForDay(dayKey) {
  const key = dayKey || todayKey();
  return { dayKey: key, perDoctor: await perDoctorFor({ dayKey: key }) };
}

/** GET /stats/live (admin) — today's counts + per-doctor + future appointments. */
async function live() {
  const key = todayKey();
  const [overall, perDoctor, future] = await Promise.all([
    overallFor({ dayKey: key }),
    perDoctorFor({ dayKey: key }),
    overallFor({ dayKey: { $gt: key }, status: UPCOMING }),
  ]);
  return {
    dayKey: key,
    today: {
      todaysAppointments: overall.total,
      completed: overall.completed,
      pending: overall.pending,
      cancelled: overall.cancelled,
      walkIns: overall.walkIns,
    },
    perDoctor,
    future: { upcoming: future.total },
  };
}

/**
 * GET /stats/overview — dashboard tiles. "Total Patients" is derived from the
 * DailySummaries store (past days) PLUS today's live total, because the
 * appointments store only holds today + future. NOTE: this counts visits, not
 * unique patients (there is no patient master record). The reception app's own
 * SQLite archive is the more precise per-terminal source.
 */
async function overview() {
  const key = todayKey();
  const [summaryAgg] = await DailySummary.aggregate([
    { $group: { _id: null, historicalVisits: { $sum: '$overall.total' } } },
  ]);
  const historicalVisits = summaryAgg ? summaryAgg.historicalVisits : 0;
  const todayOverall = await overallFor({ dayKey: key });

  return {
    dayKey: key,
    totalPatientsAllTime: historicalVisits + todayOverall.total, // visits, not unique
    historicalVisits,
    todaysAppointments: todayOverall.total,
    completed: todayOverall.completed,
    pending: todayOverall.pending,
    cancelled: todayOverall.cancelled,
    note: 'totalPatientsAllTime counts visits (appointments), not unique patients.',
  };
}

module.exports = { computeDay, today, doctorsForDay, live, overview };
