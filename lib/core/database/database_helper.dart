import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('gps_tracking.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // GPS Points table
    await db.execute('''
      CREATE TABLE gps_points (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        accuracy REAL,
        timestamp TEXT NOT NULL,
        battery_level INTEGER,
        network_type TEXT,
        device_id TEXT,
        is_synced INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Agents table (for offline storage)
    await db.execute('''
      CREATE TABLE agents_offline (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        advertisement_id INTEGER,
        name TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        registration_date TEXT,
        status TEXT DEFAULT 'pending',
        is_synced INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Settings table
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Create indexes
    await db.execute('CREATE INDEX idx_gps_timestamp ON gps_points(timestamp)');
    await db.execute('CREATE INDEX idx_gps_synced ON gps_points(is_synced)');
    await db.execute('CREATE INDEX idx_agents_synced ON agents_offline(is_synced)');
  }

  // GPS Points methods
  Future<int> insertGpsPoint(Map<String, dynamic> point) async {
    final db = await database;
    return await db.insert('gps_points', point);
  }

  Future<List<Map<String, dynamic>>> getUnsyncedGpsPoints() async {
    final db = await database;
    return await db.query(
      'gps_points',
      where: 'is_synced = ?',
      whereArgs: [0],
      orderBy: 'timestamp ASC',
    );
  }

  Future<void> markGpsPointAsSynced(int id) async {
    final db = await database;
    await db.update(
      'gps_points',
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getGpsPoints({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    final db = await database;
    String where = '1=1';
    List<dynamic> whereArgs = [];

    if (startDate != null) {
      where += ' AND timestamp >= ?';
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      where += ' AND timestamp <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    return await db.query(
      'gps_points',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'timestamp DESC',
      limit: limit,
    );
  }

  Future<int> getGpsPointsCount({DateTime? startDate, DateTime? endDate}) async {
    final db = await database;
    String where = '1=1';
    List<dynamic> whereArgs = [];

    if (startDate != null) {
      where += ' AND timestamp >= ?';
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      where += ' AND timestamp <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM gps_points WHERE $where',
      whereArgs,
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Agents methods
  Future<int> insertAgentOffline(Map<String, dynamic> agent) async {
    final db = await database;
    return await db.insert('agents_offline', agent);
  }

  Future<List<Map<String, dynamic>>> getUnsyncedAgents() async {
    final db = await database;
    return await db.query(
      'agents_offline',
      where: 'is_synced = ?',
      whereArgs: [0],
    );
  }

  Future<void> markAgentAsSynced(int id) async {
    final db = await database;
    await db.update(
      'agents_offline',
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Settings methods
  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final result = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return result.first['value'] as String?;
  }
}

