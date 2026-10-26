import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class CachedClassrooms extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  TextColumn get section => text().nullable()();
  TextColumn get description => text().nullable()();
  IntColumn get ownerId => integer()();
  TextColumn get inviteCode => text()();
  TextColumn get role => text()();
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CachedUsers extends Table {
  IntColumn get id => integer()();
  TextColumn get username => text()();
  TextColumn get email => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CachedRoutines extends Table {
  IntColumn get id => integer()();
  IntColumn get classroomId => integer()();
  TextColumn get dayOfWeek => text()();
  TextColumn get subject => text()();
  TextColumn get startTime => text()();
  TextColumn get endTime => text()();
  TextColumn get room => text().nullable()();
  TextColumn get instructor => text().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CachedAttendance extends Table {
  IntColumn get id => integer()();
  IntColumn get classroomId => integer()();
  IntColumn get userId => integer()();
  DateTimeColumn get attendanceDate => dateTime()();
  TextColumn get status => text()();
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CachedNotices extends Table {
  IntColumn get id => integer()();
  IntColumn get classroomId => integer()();
  TextColumn get title => text()();
  TextColumn get content => text()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CachedTasks extends Table {
  IntColumn get id => integer()();
  IntColumn get classroomId => integer()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  TextColumn get priority => text()();
  TextColumn get status => text()();
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class SyncQueueEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType => text()();
  TextColumn get operation => text()();
  TextColumn get payload => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(
  tables: [
    CachedUsers,
    CachedClassrooms,
    CachedRoutines,
    CachedAttendance,
    CachedNotices,
    CachedTasks,
    SyncQueueEntries,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'classapp_cache'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) => m.createAll(),
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.createTable(cachedUsers);
            await m.createTable(cachedAttendance);
            await m.createTable(cachedNotices);
          }
        },
      );

  Future<List<CachedClassroom>> readCachedClassrooms() =>
      select(cachedClassrooms).get();

  Future<void> replaceClassrooms(Iterable<CachedClassroomsCompanion> values) async {
    await transaction(() async {
      await delete(cachedClassrooms).go();
      await batch((batch) => batch.insertAll(cachedClassrooms, values));
    });
  }
}
