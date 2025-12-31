import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/mood_entry_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  static Database? _database;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'wellbeing_database.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        // Buat tabel Mood
        return db.execute('''
          CREATE TABLE mood_entries(
            id INTEGER PRIMARY KEY AUTOINCREMENT, 
            timestamp INTEGER, 
            mood TEXT, 
            notes TEXT
          )
          ''');
      },
    );
  }

  // Operasi Database: Masukkan Entri Mood
  Future<int> insertMoodEntry(MoodEntryModel entry) async {
    final db = await database;
    return await db.insert(
      'mood_entries',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Operasi Database: Dapatkan Semua Entri Mood
  Future<List<MoodEntryModel>> getMoodEntries() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'mood_entries',
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) {
      return MoodEntryModel.fromMap(maps[i]);
    });
  }
}
