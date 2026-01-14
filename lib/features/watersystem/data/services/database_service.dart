import 'dart:developer';
import 'package:mongo_dart/mongo_dart.dart';

class DatabaseService {
  // Connection String provided by user
  static const String _connectionString =
      "mongodb+srv://midyarudranil447_db_user:KCI6l9EAWbH70AVc@watersystem.yoauejz.mongodb.net/watersystem?retryWrites=true&w=majority";

  Db? _db;
  DbCollection? _usersCollection;
  DbCollection? _sensorLogsCollection;

  bool get isConnected => _db?.isConnected == true;

  Future<void> connect() async {
    try {
      _db = await Db.create(_connectionString);
      await _db!.open();
      
      _usersCollection = _db!.collection('users');
      _sensorLogsCollection = _db!.collection('sensor_logs');
      
      log("Connected to MongoDB");
    } catch (e) {
      log("MongoDB Connection Error: $e");
    }
  }

  Future<void> saveUser(Map<String, dynamic> userData) async {
    if (!isConnected) return;
    try {
      // Upsert user based on email (or uid)
      await _usersCollection!.updateOne(
        where.eq('uid', userData['uid']),
        modify.set('email', userData['email'])
              .set('displayName', userData['displayName'])
              .set('lastLogin', DateTime.now().toIso8601String()),
        upsert: true,
      );
      log("User saved/updated: ${userData['email']}");
    } catch (e) {
      log("Error saving user: $e");
    }
  }

  Future<void> logSensorData(Map<String, dynamic> data) async {
    if (!isConnected) return;
    try {
      data['timestamp'] = DateTime.now().toIso8601String();
      await _sensorLogsCollection!.insert(data);
      // log("Sensor data logged to MongoDB"); 
    } catch (e) {
      log("Error logging sensor data: $e");
    }
  }

  Future<void> close() async {
    await _db?.close();
  }
}
