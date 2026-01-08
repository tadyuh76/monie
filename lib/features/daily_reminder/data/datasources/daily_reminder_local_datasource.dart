import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import '../models/daily_reminder_model.dart';

class DailyReminderLocalDataSource {
  static Database? _database;
  static const String tableName = 'daily_reminders';
  final _uuid = const Uuid();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'monie.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $tableName (
            id TEXT PRIMARY KEY,
            hour INTEGER NOT NULL,
            minute INTEGER NOT NULL,
            is_enabled INTEGER NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<DailyReminderModel> addReminder({
    required int hour,
    required int minute,
  }) async {
    final db = await database;
    final now = DateTime.now();
    
    final reminder = DailyReminderModel(
      id: _uuid.v4(),
      hour: hour,
      minute: minute,
      isEnabled: true,
      createdAt: now,
      updatedAt: now,
    );

    await db.insert(tableName, reminder.toJson());
    return reminder;
  }

  Future<DailyReminderModel> updateReminder({
    required String id,
    int? hour,
    int? minute,
    bool? isEnabled,
  }) async {
    final db = await database;
    final existing = await getReminder();
    
    if (existing == null) {
      throw Exception('Reminder not found');
    }

    final updated = DailyReminderModel(
      id: id,
      hour: hour ?? existing.hour,
      minute: minute ?? existing.minute,
      isEnabled: isEnabled ?? existing.isEnabled,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
    );

    await db.update(
      tableName,
      updated.toJson(),
      where: 'id = ?',
      whereArgs: [id],
    );

    return updated;
  }

  Future<void> deleteReminder(String id) async {
    final db = await database;
    await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<DailyReminderModel?> getReminder() async {
    final db = await database;
    final results = await db.query(
      tableName,
      limit: 1,
      orderBy: 'created_at DESC',
    );

    if (results.isEmpty) {
      return null;
    }

    return DailyReminderModel.fromJson(results.first);
  }

  Future<List<DailyReminderModel>> getAllReminders() async {
    final db = await database;
    final results = await db.query(
      tableName,
      orderBy: 'hour ASC, minute ASC',
    );

    return results.map((json) => DailyReminderModel.fromJson(json)).toList();
  }
}
