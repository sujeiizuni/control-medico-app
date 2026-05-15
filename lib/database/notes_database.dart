import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class NotesDatabase {
  static final NotesDatabase instance = NotesDatabase._init();

  static Database? _database;

  NotesDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('notes.db');
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
CREATE TABLE notes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  date TEXT,
  note TEXT
)
''');
  }

  Future insertNote(String date, String note) async {
    final db = await instance.database;

    await db.insert('notes', {
      'date': date,
      'note': note,
    });
  }

  Future<List<Map<String, dynamic>>> getNotes() async {
    final db = await instance.database;
    return await db.query('notes');
  }
}