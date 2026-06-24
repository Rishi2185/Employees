# Aarvy Hospital Backend

The Node.js + MongoDB backend for the **hospital side** of the Aarvy healthcare
system. It pairs with the existing **patient Flutter app** (`../../Patient`) and
will power two apps built later:

- **Reception desktop app** (Flutter Windows) — manages appointments, registers
  walk-ins, prints slips, and runs the end-of-day **archive → summarize → purge**
  job (the durable long-term archive lives in the reception's local SQLite).
- **Admin Android app** (Flutter) — live stats, historical trends, doctor roster
  management.

This is the **backend foundation only**. The reception and admin apps are future
phases; the patient app is left untouched but the API is a non-breaking superset
of its data model so it can adopt this API later.

## Architecture — the cloud holds three small stores

| Store | Collection | Written by | Read by | Lifecycle |
|-------|-----------|-----------|---------|-----------|
| ① Doctors | `doctors` | admin | patient + reception + admin | persistent; source of truth for the roster |
| ② Appointments | `appointments` | patient app + reception | reception + admin | **rolling window: today + future only** |
| ③ Daily Summaries | `dailysummaries` | reception (end-of-day) | admin | one tiny **counts-only** doc per day; permanent |

Supporting collections: `users` (admin/reception accounts), `specialties` and
`hospitals` (reference data ported from the patient app).

```
Patient app ──book──▶ ② Appointments (today + future)
     ▲                        │
 reads ①                      │  reception: archive → summarize → purge
     │                        ▼
 ① Doctors ◀─add/edit─ Admin   Reception ──archive──▶ local SQLite (future app)
                │  reads ②(live)        │
                └─ reads ③(history) ◀── writes daily summary ──┘  ③ Daily Summaries
```

**Why it stays on the Atlas free tier (M0):** the appointments collection is
bounded to today+future; past days are summarized into one tiny doc each and the
full records are purged. A TTL index is a backstop in case a purge is missed.
Denormalized doctor/specialty/hospital names avoid `$lookup` on hot paths.

**Privacy:** Daily Summaries contain **counts only — no patient PII**. After a
day is purged, the cloud holds no personal data for that day; the full records
live only in the reception's local archive. Atlas provides encryption-at-rest at
the cluster level.

## Quick start (zero secrets)

```bash
npm install
npm run dev
```

With no `MONGODB_URI` set, the server boots an **in-memory MongoDB** and
auto-seeds demo data. You'll see the seeded login credentials in the console.
API base: `http://localhost:4000/api`.

> The in-memory DB is **ephemeral per process** — `npm run seed` in a separate
> process won't share it. For persistence, set `MONGODB_URI` (local mongod or an
> Atlas free-tier URI) in `.env`, then `npm run seed` once.

```bash
cp .env.example .env          # then edit MONGODB_URI / secrets
npm run seed                  # seed a persistent DB
npm start                     # production-style start
npm test                      # Jest + supertest (own in-memory Mongo)
```

### Default seeded logins (change before real use — see `.env.example`)

| Role | Username | Password |
|------|----------|----------|
| admin | `admin` | `admin1234` |
| reception | `reception` | `reception1234` |

## API

All routes are under `/api`. Auth is `Authorization: Bearer <jwt>`. List
endpoints return `{ data, page, limit, total }`.

### Auth
- `POST /auth/login` `{username,password}` → `{token, role, displayName, userId}` (rate-limited)
- `GET /auth/me` — current principal

### Doctors (① store)
- `GET /doctors` — public. Query: `q`, `specialtyId`, `availableToday`,
  `minRating`, `sort` (`relevance|ratingHigh|feeLow|feeHigh|experience`),
  `page`, `limit`. Mirrors the patient app's `DoctorProvider` filter/sort.
- `GET /doctors/:id`
- `GET /doctors/:id/availability?date=YYYY-MM-DD` → window + days + `bookedSlots`
- `POST /doctors` · `PATCH /doctors/:id` · `DELETE /doctors/:id` — **admin only**
  (delete is a soft-delete; edits reflect in the patient roster)

### Appointments (② store)
- `GET /appointments` — reception/admin. Query: `date`, `from`/`to`, `doctorId`,
  `status` (0/1/2), `q` (name/phone/doctor), `checkedIn`, `page`, `limit`
- `GET /appointments/:id` · `GET /appointments/:id/slip`
- `POST /appointments` — reception walk-in (**requires** `patientName` +
  `patientPhone`) or anonymous patient-app booking (identity optional). Rejects
  past-dated bookings; the slot is guarded by a partial-unique index.
- `PATCH /appointments/:id` — reception: `status`, `checkedIn`, identity backfill
- `DELETE /appointments/:id` — reception: manual cancel/remove
- `DELETE /appointments?date=YYYY-MM-DD&confirm=YYYY-MM-DD` — **end-of-day purge**

### Stats (server-side aggregation)
- `GET /stats/today` — reception dashboard tiles for today
- `GET /stats/doctors?date=` — per-doctor breakdown
- `GET /stats/overview` — dashboard incl. all-time totals (from summaries)
- `GET /stats/live` — **admin only**: today + per-doctor + future counts

### Summaries (③ store)
- `POST /summaries` `{dayKey}` — **reception**: end-of-day write (server-computed)
- `GET /summaries?from=&to=&doctorId=` — historical trends
- `GET /summaries/:dayKey`

### Reference / health
- `GET /specialties` · `GET /hospitals` · `GET /health`

## End-of-day contract (archive → summarize → purge)

Three idempotent steps the reception app runs after a day completes:

1. **PULL** `GET /appointments?date=<dayKey>` → reception writes the full records
   to its local SQLite archive. Pure read; safe to retry.
2. **SUMMARIZE** `POST /summaries {dayKey}` → the **server** aggregates that day's
   counts and **upserts** the summary keyed by `dayKey`. Reception never supplies
   counts, so clock skew/bugs can't corrupt history. Rejects today/future.
3. **PURGE** `DELETE /appointments?date=<dayKey>&confirm=<dayKey>` → deletes the
   day's full records. **Gated**: a summary for that day must already exist;
   `confirm` must equal the date; the day must be strictly in the past. Purging
   an already-empty day returns `{deleted: 0}` (idempotent).

`dayKey` (YYYY-MM-DD) is computed in `CLINIC_TZ` (default `Asia/Kolkata`) so
appointments near midnight bucket into the correct clinic day.

## Patient-app compatibility contract

The `appointments` documents are a **non-breaking superset** of the patient
app's `Appointment` model (`../../Patient/lib/models/appointment.dart`):

- `status` and `paymentMethod` are stored and emitted as the patient enum's
  **integer index** (`status`: 0 upcoming / 1 completed / 2 cancelled;
  `paymentMethod`: 0 card / 1 upi / 2 wallet). **Never** emit a 4th status — the
  app reconstructs via `Enum.values[index]` and would crash. "Pending" is derived
  (`upcoming` + today), not a stored status.
- The patient-facing keys (`id`, `doctorId`, `doctorName`, `doctorPhotoUrl`,
  `specialtyName`, `hospitalName`, `dateTime` ISO, `slotLabel`, `fee`,
  `paymentMethod`, `status`, `reviewed`) are preserved verbatim. Extra fields
  (`statusLabel`, `patientName`, `source`, …) are ignored by the app's strict
  `fromJson`.
- Doctors expose `specialtyId` + `specialtyName`; the icon/color mapping stays
  client-side via `Specialties.byId(id)`. Doctor ids (`d1`…`d12`) are preserved.

`test/contract.test.js` round-trips a live appointment payload through the
patient model's `fromJson` expectations to guard against drift.

## Project layout

```
src/
  config/      env.js, db.js (Atlas / in-memory fallback)
  models/      User, Specialty, Hospital, Doctor, Appointment, DailySummary
  validators/  zod schemas (strict; block mass-assignment)
  middleware/  auth (JWT + requireRole), validate, errorHandler, rateLimiters
  services/    doctor / appointment / stats / summary (aggregations live here)
  controllers/ thin HTTP handlers
  routes/      auth, doctors, appointments, stats, summaries, meta, health
  utils/       dayKey (TZ-aware), apiError, asyncHandler, pagination
  seed/        data.js (ported roster) + seed.js (CLI + auto-seed function)
  app.js       express app factory       server.js  bootstrap + auto-seed
test/          jest suites + in-memory Mongo harness
```

## Notes / future phases

- **"Total Patients"** is derived from Daily Summaries (`sum(overall.total)`) plus
  today's live count — this counts **visits, not unique patients** (there is no
  patient master record). The reception app's local SQLite is the more precise
  per-terminal source and will override this tile.
- Reception-user provisioning (`POST /users`) is intentionally out of scope here;
  accounts are seeded. Add an admin-only user route when needed.
- Wiring the patient app from mock data to this API is a separate, opt-in phase.
