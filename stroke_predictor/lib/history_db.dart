import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class HistoryDatabase {
  static final HistoryDatabase instance = HistoryDatabase._init();
  static Database? _database;

  /// Optional override used only for tests (e.g., in-memory DB)
  final Future<Database> Function()? openDbOverride;

  HistoryDatabase._init({this.openDbOverride});

  /// Create a DB instance for tests
  factory HistoryDatabase.forTest(Future<Database> Function() openDbOverride) {
    return HistoryDatabase._init(openDbOverride: openDbOverride);
  }

  Future<Database> get database async {
    if (_database != null) return _database!;

    // Use override in tests, otherwise use normal file DB
    _database = openDbOverride != null
        ? await openDbOverride!()
        : await _initDB('history.db');

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
    await db.execute('''
      CREATE TABLE predictions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        probability REAL,
        riskLevel TEXT,
        age REAL,
        bmi REAL,
        glucose REAL,
        createdAt TEXT
      )
    ''');
  }

  Future<int> insertPrediction({
    required double probability,
    required String riskLevel,
    required double age,
    required double bmi,
    required double glucose,
  }) async {
    final db = await database; //use this.database (works for both app & tests)
    final data = {
      'probability': probability,
      'riskLevel': riskLevel,
      'age': age,
      'bmi': bmi,
      'glucose': glucose,
      'createdAt': DateTime.now().toIso8601String(),
    };
    return await db.insert('predictions', data);
  }

  Future<List<Map<String, dynamic>>> getPredictions() async {
    final db = await database; // use this.database
    return await db.query('predictions', orderBy: 'createdAt DESC');
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
