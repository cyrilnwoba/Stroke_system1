import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stroke_predictor/history_db.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late HistoryDatabase db;

  setUp(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    db = HistoryDatabase.forTest(() async {
      return await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (Database db, int version) async {
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
        },
      );
    });
  });

  tearDown(() async {
    await db.close();
  });

  test('SQLite insert and retrieve prediction', () async {
    await db.insertPrediction(
      probability: 0.42,
      riskLevel: 'Moderate estimated stroke risk',
      age: 55,
      bmi: 26.4,
      glucose: 118,
    );

    final results = await db.getPredictions();

    expect(results.length, 1);
    expect(results.first['probability'], 0.42);
    expect(results.first['riskLevel'], 'Moderate estimated stroke risk');
  });
}
