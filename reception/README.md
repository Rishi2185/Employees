# Aarvy Reception

The hospital **front-desk desktop app** for the Aarvy healthcare system — a
Flutter **Windows** application that runs on the single reception terminal. It
pairs with the [backend](../backend) and shares one design language with the
[patient app](../../Patient).

It does four jobs:

1. **Manage today's appointments** booked from the patient app — check-in,
   complete, cancel, search.
2. **Register walk-ins** — patients who arrive without booking — and print their
   slips.
3. **Own the durable long-term record** — every completed day's full
   appointment records are archived to a local SQLite file on the reception
   laptop's disk, searchable and available offline.
4. **Run the end-of-day job** — `archive → summarize → purge` — which keeps the
   cloud (Atlas free tier) tiny by moving completed days out of it.

## Architecture

```
                 ┌─────────────────────── Reception (this app) ───────────────────────┐
 Cloud (Atlas)   │  api/        dio client + per-resource APIs (auth/doctor/appt/...)  │
 ① Doctors       │  db/         SQLite: archive_dao, day_state_dao, backup_service     │
 ② Appointments ─┼─▶ state/     ChangeNotifier providers (auth, appointments, eod, …)  │
 ③ Summaries     │  services/   eod_service (state machine) + slip_printer (PDF)       │
                 │  screens/    login, dashboard, appointments, walk-in, doctors,      │
                 │              archive, end-of-day, settings                          │
                 └────────────────────────────────────────────────────────────────────┘
                          │                                   │
                  reads ②(live) / writes walk-ins      local SQLite archive
                  writes ③ + purges ② at EOD           (permanent, offline, encrypted-at-rest)
```

- **`lib/api/`** — a thin `dio` client (`ApiClient`) plus one API class per
  resource. Mirrors the backend's REST surface; a 401 triggers auto-logout.
- **`lib/db/`** — the local store. `AppDatabase` opens the SQLite file under
  `%APPDATA%/Aarvy/Reception/`; `ArchiveDao` is the indexed permanent record;
  `DayStateDao` tracks end-of-day progress; `BackupService` does CSV export +
  full-file backup.
- **`lib/services/eod_service.dart`** — the end-of-day state machine (below).
- **`lib/state/`** — `provider`-based view models. `Services` is the composition
  root that wires APIs + DAOs + the EOD service together.
- **`lib/screens/`** — the desktop UI (left nav rail + sections).

## End-of-day contract (`archive → summarize → purge`)

This app owns the lifecycle that keeps the cloud small. For each **past** day:

1. **ARCHIVE** — `GET /appointments?date=<dayKey>` (all pages) → write the full
   records into local SQLite. Pure read; safe to retry.
2. **SUMMARIZE** — `POST /summaries {dayKey}` → the **server** computes the
   counts and upserts one tiny summary doc. Reception never supplies counts.
3. **PURGE** — `DELETE /appointments?date=&confirm=` → delete that day's cloud
   records. Gated server-side: the summary must exist and the day must be
   strictly in the past.

Every step is **idempotent**, and `day_state` persists the furthest stage each
day has durably reached. A crash or dropped connection **resumes from the last
completed stage** instead of repeating a destructive step — purging an
already-empty day is a no-op. The clinic `dayKey` is always the server's
(`/stats/today`), never derived from the local clock, so appointments near
midnight bucket into the correct clinic day.

See `EodService` and the tests in `test/eod_service_test.dart`.

## Data & privacy

- The **local SQLite file is the system of long-term record** — it holds full
  patient PII permanently (configurable retention window in Settings). It relies
  on **OS disk encryption (BitLocker)** on the reception PC for encryption at
  rest; `sqflite_ffi` has no built-in cipher.
- The cloud **Summaries store is counts-only** — after a day is purged, the
  cloud holds no PII for it.
- Backup/export (Settings → Local archive) writes a `.db` copy or a CSV to a
  location you choose, for off-site backup.

## Patient-app compatibility

`status` and `paymentMethod` are kept as the patient app's **integer enum
indices** end-to-end (`status` 0 upcoming / 1 completed / 2 cancelled;
`paymentMethod` 0 card / 1 upi / 2 wallet). `StatusUi` maps them to labels and
**degrades unknown values to "Unknown"** rather than crashing. The `Doctor`
model is the backend's flat shape (`specialtyId` + `specialtyName`).

## Running

This is a **Windows desktop** Flutter app.

```bash
flutter pub get
flutter run -d windows          # against a backend on http://localhost:4000/api
```

Start the [backend](../backend) first (`npm run dev` boots a zero-config
in-memory Mongo and prints seeded logins — `reception` / `reception1234`). Set a
different API base URL any time in **Settings → Connection** (persisted via
`shared_preferences`).

```bash
flutter analyze
flutter test                    # 26 unit tests: DAOs, EOD state machine, CSV, dayKey
flutter build windows           # release build
```

## Project layout

```
lib/
  api/        api_client, auth/doctor/appointment/stats/summary/health APIs
  db/         app_database, archive_dao, day_state_dao, backup_service
  models/     reception_appointment, doctor, daily_summary, day_state, slip, …
  services/   eod_service (state machine), slip_printer (PDF)
  state/      services (DI), settings_store, + providers
  screens/    login, app_shell, dashboard, appointments(+detail sheet),
              walk_in, doctors, archive, eod, settings
  theme/      app_colors, app_typography, app_theme   (shared with patient app)
  utils/      day_key, formatters, slot_generator, status_ui
  widgets/    primary_button, app_text_field, appointment_tile, stat_card, …
test/         archive_dao, day_state_dao, eod_service, backup_service,
              day_key, widget(models) — all in-memory, no backend needed
```

## Notes / future phases

- **Connectivity** is polled via `GET /health`; the rail shows online/offline.
  The local archive screen works fully offline; cloud actions (walk-in, EOD)
  need the backend.
- **Retention pruning** (deleting local days beyond the configured window) is
  wired in the DAO (`daysBeyondRetention`/`deleteDay`) and surfaced in Settings;
  an automatic scheduler can be added later.
- The **admin Android app** is the next phase and reuses the same backend and
  design tokens.
