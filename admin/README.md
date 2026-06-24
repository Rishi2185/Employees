# Aarvy Admin

The hospital **management dashboard** for the Aarvy healthcare system — a
Flutter **Android** app for administrators/owners. It reads live + historical
activity from the cloud and is the **single place doctors are managed**: every
edit here writes to the cloud Doctors store and is immediately reflected in the
[patient app](../../Patient). It shares one design language with the patient and
[reception](../reception) apps.

## What it does

1. **Live overview** (`GET /stats/live`, admin-only) — today's counts
   (appointments / completed / pending / cancelled), attended-vs-remaining, the
   count of future bookings, and a per-doctor **load distribution**.
2. **Historical trends** (`GET /summaries`) — per-day and per-doctor aggregate
   counts over a selectable window (7 / 30 / 90 days), as charts — *without*
   storing full past records in the cloud (the Summaries store is counts-only).
3. **Doctor roster management** (`POST` / `PATCH` / `DELETE /doctors`) — add,
   edit, deactivate, and reactivate doctors. Changes flow to the patient app.

## Admin-only access

The app is gated to administrators. A successful login with a non-admin role
(e.g. reception) is **rejected client-side** and the token is never persisted —
see `AuthProvider.login` and the test in `test/providers_test.dart`. The backend
also enforces `requireRole(admin)` on every write, so the gate is defence in
depth.

## Architecture

```
 Cloud (Atlas)        ┌──────────────── Admin (this app) ────────────────┐
 ① Doctors  ◀──write──┤  api/      dio client + auth/doctor/stats/        │
 ② Appointments ─read─┤            summary/meta/health APIs               │
 ③ Summaries  ─read───┤  state/    provider view-models + Services (DI)   │
                      │  screens/  login, shell, dashboard(live),         │
                      │            trends(charts), doctors, doctor_edit    │
                      └───────────────────────────────────────────────────┘
        admin edits ① → patient app sees the updated roster instantly
```

- **`lib/api/`** — the shared `dio` `ApiClient` (identical to reception) plus
  admin APIs. `DoctorApi` adds the write methods; `StatsApi.live()` is the
  admin-only live feed; `SummaryApi` returns either full per-day summaries
  (overall) or flattened per-doctor points (when a `doctorId` is passed).
- **`lib/models/`** — `live_stats`, `doctor`, `doctor_input` (the create/update
  payload), `daily_summary`, `doctor_trend`, `specialty`.
- **`lib/state/`** — `Services` (composition root, with an `apiOverride` test
  seam), `SettingsStore`, and the providers: auth, connectivity, live-stats,
  trends, doctors.
- **`lib/screens/`** — a bottom-nav shell over Live / Trends / Doctors, plus the
  add/edit doctor form.

## Trends data shapes

`GET /summaries` serves two shapes, both handled:
- **without `doctorId`** → full `DailySummary` docs (the overall trend),
- **with `doctorId`** → flattened `{dayKey, total, completed, …}` per day for
  that one doctor ("how many did Dr. X attend last week/month").

Charts are drawn with `fl_chart`. The look-back window is computed from the
local clock — fine here, since it only bounds a multi-day query, not an
authoritative clinic-day decision.

## Patient-app compatibility

The doctor edit form writes the backend's flat `Doctor` shape (`specialtyId` +
`specialtyName`; the icon/color mapping stays client-side in the patient app).
Deactivating a doctor is a **soft-delete** (`active: false`) so historical
appointments still resolve the doctor's name; the patient app simply stops
showing inactive doctors. `status` stays the patient enum's integer index via
the shared `StatusUi` (degrades unknown values to "Unknown").

## Running

This is an **Android** app.

```bash
flutter pub get
flutter run -d android        # emulator or a connected device
```

Start the [backend](../backend) first. The default API base URL is
`http://10.0.2.2:4000/api` — `10.0.2.2` is the **Android emulator's alias for
the host machine's localhost**, so a backend running on your dev PC is
reachable. For a physical device, change `SettingsStore.defaultBaseUrl` (or the
stored value) to the PC's LAN IP. Seeded admin login: `admin` / `admin1234`.

```bash
flutter analyze
flutter test                  # 21 tests: models, APIs, admin auth gate, trends
flutter build apk --debug     # Android build
```

## Project layout

```
lib/
  api/        api_client, auth/doctor/stats/summary/meta/health APIs
  models/     live_stats, doctor, doctor_input, daily_summary, doctor_trend, specialty
  state/      services (DI), settings_store, auth/connectivity/live_stats/trends/doctors providers
  screens/    login, app_shell (bottom nav), dashboard (live), trends (fl_chart),
              doctors (roster), doctor_edit (add/edit form)
  theme/      app_colors, app_typography, app_theme   (shared with patient + reception)
  utils/      day_key, formatters, status_ui
  widgets/    primary_button, app_text_field, avatar, stat_card, empty_state, fade_in
test/         models, api (fake client), providers (auth gate + trends), widget(status)
```

## Notes / relationship to the other apps

- **Reception** owns the end-of-day `archive → summarize → purge` job that fills
  the Summaries store this app reads for trends. Admin never writes summaries.
- **No PII leaves the cloud-summary path**: trends are counts only. Live data is
  today + future appointments, which the reception purges into summaries daily.
