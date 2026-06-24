import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Owns the reception station's durable local archive — the **system of
/// long-term record**. Past days' full appointment records are pulled from the
/// cloud and written here permanently before the cloud copy is purged.
///
/// Backed by SQLite via `sqflite_common_ffi` (desktop). One database file lives
/// under the OS application-support directory; on Windows that's
/// `%APPDATA%/Aarvy/Reception/aarvy_reception.db`.
///
/// On encryption: the file itself relies on OS-level disk encryption
/// (BitLocker on the reception PC) per the deployment guide — `sqflite_ffi`
/// has no built-in cipher. The schema deliberately keeps PII in this local
/// store only; the cloud Summaries store stays counts-only.
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static const _dbName = 'aarvy_reception.db';
  static const _schemaVersion = 1;

  Database? _db;
  String? _path;

  bool get isOpen => _db != null;
  String? get path => _path;

  /// Initialize the ffi backend exactly once, then open the database.
  /// Pass [overridePath] (or `inMemoryDatabasePath`) for tests.
  Future<Database> open({String? overridePath}) async {
    if (_db != null) return _db!;

    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final path = overridePath ?? await _defaultPath();
    _path = path;

    _db = await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _schemaVersion,
        onConfigure: _onConfigure,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
    return _db!;
  }

  Database get db {
    final d = _db;
    if (d == null) {
      throw StateError('AppDatabase.open() must be awaited before use.');
    }
    return d;
  }

  /// Open a fresh, isolated in-memory database with the real schema — used by
  /// unit tests. Each call returns an independent database (ffi `:memory:`
  /// connections don't share state), and the singleton is left untouched.
  static Future<Database> openInMemoryForTesting() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    return databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: _schemaVersion,
        onConfigure: instance._onConfigure,
        onCreate: instance._onCreate,
        onUpgrade: instance._onUpgrade,
      ),
    );
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  Future<String> _defaultPath() async {
    final dir = await getApplicationSupportDirectory();
    final root = Directory(p.join(dir.path, 'Aarvy', 'Reception'));
    if (!root.existsSync()) root.createSync(recursive: true);
    return p.join(root.path, _dbName);
  }

  Future<void> _onConfigure(Database db) async {
    // Durability + concurrency for a single-station desktop app.
    await db.execute('PRAGMA foreign_keys = ON');
    await db.execute('PRAGMA journal_mode = WAL');
    await db.execute('PRAGMA synchronous = NORMAL');
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE archived_appointments (
        id              TEXT PRIMARY KEY,
        day_key         TEXT NOT NULL,
        date_time       TEXT NOT NULL,
        doctor_id       TEXT NOT NULL,
        doctor_name     TEXT NOT NULL DEFAULT '',
        doctor_photo_url TEXT NOT NULL DEFAULT '',
        specialty_name  TEXT NOT NULL DEFAULT '',
        hospital_name   TEXT NOT NULL DEFAULT '',
        slot_label      TEXT NOT NULL DEFAULT '',
        fee             INTEGER NOT NULL DEFAULT 0,
        payment_method  INTEGER NOT NULL DEFAULT 1,
        status          INTEGER NOT NULL DEFAULT 0,
        reviewed        INTEGER NOT NULL DEFAULT 0,
        patient_name    TEXT,
        patient_phone   TEXT,
        patient_age     INTEGER,
        patient_gender  TEXT,
        token_number    INTEGER,
        checked_in      INTEGER NOT NULL DEFAULT 0,
        source          TEXT,
        created_by      TEXT,
        archived_at     TEXT NOT NULL
      )
    ''');

    // Fast search/filter as the archive grows.
    await db.execute(
        'CREATE INDEX idx_arch_day ON archived_appointments(day_key)');
    await db.execute(
        'CREATE INDEX idx_arch_doctor ON archived_appointments(doctor_id)');
    await db.execute(
        'CREATE INDEX idx_arch_status ON archived_appointments(status)');
    await db.execute(
        'CREATE INDEX idx_arch_datetime ON archived_appointments(date_time)');
    await db.execute(
        'CREATE INDEX idx_arch_patient_name ON archived_appointments(patient_name)');
    await db.execute(
        'CREATE INDEX idx_arch_patient_phone ON archived_appointments(patient_phone)');

    // One row per calendar day tracking end-of-day progress (resumable).
    await db.execute('''
      CREATE TABLE day_state (
        day_key        TEXT PRIMARY KEY,
        stage          TEXT NOT NULL DEFAULT 'pending',
        archived_count INTEGER NOT NULL DEFAULT 0,
        purged_count   INTEGER NOT NULL DEFAULT 0,
        archived_at    TEXT,
        summarized_at  TEXT,
        purged_at      TEXT,
        last_error     TEXT,
        updated_at     TEXT NOT NULL
      )
    ''');
    await db
        .execute('CREATE INDEX idx_day_state_stage ON day_state(stage)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // First versioned schema — no migrations yet. Future ALTERs go here,
    // guarded by `if (oldVersion < N)`.
  }
}
