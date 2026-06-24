'use strict';

const env = require('../config/env');

/**
 * Compute the clinic-local calendar day (YYYY-MM-DD) for a given instant.
 *
 * Every appointment is stamped with a `dayKey` derived in the clinic's timezone
 * (CLINIC_TZ). This is the single boundary used by the rolling window and the
 * end-of-day archive/summarize/purge job — computing it in UTC would push
 * appointments near midnight into the wrong day.
 *
 * Implemented with Intl (no external date library) so it stays dependency-free.
 *
 * @param {Date|string|number} [instant=now] - the instant to bucket.
 * @param {string} [tz=CLINIC_TZ] - IANA timezone.
 * @returns {string} e.g. "2026-06-22"
 */
function dayKey(instant = new Date(), tz = env.clinicTz) {
  const date = instant instanceof Date ? instant : new Date(instant);
  if (Number.isNaN(date.getTime())) {
    throw new Error(`dayKey: invalid date input "${instant}"`);
  }
  // en-CA formats as YYYY-MM-DD, which is exactly the key shape we want.
  const fmt = new Intl.DateTimeFormat('en-CA', {
    timeZone: tz,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  });
  return fmt.format(date);
}

/** Today's clinic-local dayKey. */
function todayKey(tz = env.clinicTz) {
  return dayKey(new Date(), tz);
}

/**
 * Validate a YYYY-MM-DD string and return it, or null if malformed.
 * (Range-checks the calendar, e.g. rejects 2026-13-40.)
 */
function normalizeDayKey(value) {
  if (typeof value !== 'string') return null;
  const m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(value.trim());
  if (!m) return null;
  const [, y, mo, d] = m;
  const dt = new Date(Date.UTC(+y, +mo - 1, +d));
  if (
    dt.getUTCFullYear() !== +y ||
    dt.getUTCMonth() !== +mo - 1 ||
    dt.getUTCDate() !== +d
  ) {
    return null;
  }
  return `${y}-${mo}-${d}`;
}

/** String comparison is valid ordering for YYYY-MM-DD keys. */
function isPastDay(key, tz = env.clinicTz) {
  return normalizeDayKey(key) < todayKey(tz);
}

module.exports = { dayKey, todayKey, normalizeDayKey, isPastDay };
