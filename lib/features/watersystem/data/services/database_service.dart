import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'watersystem.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Sensor Logs Table
    await db.execute('''
      CREATE TABLE sensor_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT,
        oxygenLevel REAL,
        pump1Status INTEGER,
        pump2Status INTEGER,
        isAutoMode INTEGER,
        timestamp TEXT,
        isSynced INTEGER DEFAULT 0
      )
    ''');

    // Users Table (Local cache)
    await db.execute('''
      CREATE TABLE users (
        uid TEXT PRIMARY KEY,
        email TEXT,
        displayName TEXT,
        photoURL TEXT,
        lastLogin TEXT
      )
    ''');
  }

  // Compatibility method for existing connect calls
  Future<void> connect() async {
    await database;
  }

  Future<void> saveUser(Map<String, dynamic> userData) async {
    final db = await database;
    await db.insert(
      'users',
      {
        'uid': userData['uid'],
        'email': userData['email'],
        'displayName': userData['displayName'],
        'photoURL': userData['photoURL'],
        'lastLogin': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> logSensorData(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert(
      'sensor_logs',
      {
        'userId': data['userId'] ?? 'unknown',
        'oxygenLevel': data['oxygen_level'],
        'pump1Status': (data['pump1'] ?? false) ? 1 : 0,
        'pump2Status': (data['pump2'] ?? false) ? 1 : 0,
        'isAutoMode': (data['isAutoMode'] ?? false) ? 1 : 0,
        'timestamp': DateTime.now().toIso8601String(),
        'isSynced': 0,
      },
    );
  }

  Future<List<Map<String, dynamic>>> getUnsyncedLogs() async {
    final db = await database;
    return await db.query('sensor_logs', where: 'isSynced = ?', whereArgs: [0]);
  }

  Future<void> markAsSynced(int id) async {
    final db = await database;
    await db.update(
      'sensor_logs',
      {'isSynced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getAllLogs() async {
    final db = await database;
    return await db.query('sensor_logs', orderBy: 'timestamp DESC');
  }

  Future<void> eraseAllData() async {
    final db = await database;
    await db.delete('sensor_logs');
    // We might want to keep user data, but the request said "stored data", 
    // which usually implies the logs.
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
