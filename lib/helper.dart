// helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final _databaseName = "MyDatabase.db";
  static final _databaseVersion = 1;

  static final table = 'users';

  static final columnId = '_id';
  static final columnName = 'name';
  static final columnAge = 'age';

  late Database _database;

  Future<Database> get database async {
    return _database;
  }

  Future<void> init() async {
    final documentsDirectory = await getDatabasesPath();
    final path = join(documentsDirectory, _databaseName);
    _database = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $table (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnName TEXT NOT NULL,
        $columnAge INTEGER NOT NULL
      )
      ''');
  }

  Future<int> insert(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert(table, row);
  }

  Future<List<Map<String, dynamic>>> queryAllRows() async {
    Database db = await database;
    return await db.query(table);
  }

  Future<int> delete(int id) async {
    Database db = await database;
    return await db.delete(
      table,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  Future<int> update(Map<String, dynamic> row) async {
    Database db = await database;
    int id = row[columnId];
    return await db.update(
      table,
      row,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }
}