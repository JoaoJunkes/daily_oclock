import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;

class DatabaseService {
  late final Database db;

  Future<void> init() async {
    final dbPath = await databaseFactory.getDatabasesPath();
    db = await databaseFactory.openDatabase(p.join(dbPath, 'daily_timer.db'));

    await db.execute('''
      CREATE TABLE IF NOT EXISTS entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        duration_seconds INTEGER,
        timestamp TEXT
      )
    ''');
  }

  Future<void> insertEntry(String name, int durationSeconds) async {
    final now = DateTime.now().toIso8601String();
    await db.insert('entries', {
      'name': name,
      'duration_seconds': durationSeconds,
      'timestamp': now,
    });
  }

  Future<List<Map<String, Object?>>> getRanking() async {
    return await db.rawQuery('''
      SELECT name, SUM(duration_seconds) as total
      FROM entries
      GROUP BY name
      ORDER BY total DESC
    ''');
  }
}
