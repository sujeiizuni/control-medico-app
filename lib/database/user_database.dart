import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class UserDatabase {
  static final UserDatabase instance = UserDatabase._init();

  static Database? _database;

  UserDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('users.db');
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

  Future _createDB(Database db, int version) async {
    await db.execute('''
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT,
  email TEXT,
  password TEXT
)
''');
  }

  Future insertUser(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('users', row);
  }

  Future<bool> loginUser(String email, String password) async {
    final db = await instance.database;

    final result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    return result.isNotEmpty;
  }
}