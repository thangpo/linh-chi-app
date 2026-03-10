import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  late Database _database;
  bool _isInitialized = false;

  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Future<void> init() async {
    if (_isInitialized) return;
    final docDir = await getApplicationDocumentsDirectory();
    final dbPath = '${docDir.path}/angel_linh_chi.db';
    _database = await openDatabase(dbPath, version: 1, onCreate: _createTables);
    _isInitialized = true;
  }

  void _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        price TEXT,
        description TEXT,
        imageUrl TEXT,
        category TEXT,
        isFavorite INTEGER DEFAULT 0,
        createdAt TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS stores (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        address TEXT,
        phone TEXT,
        hours TEXT,
        latitude REAL,
        longitude REAL,
        createdAt TEXT
      )
    ''');
  }

  Future<void> saveProducts(List<Map<String, dynamic>> products) async {
    await _database.delete('products');
    for (var p in products) {
      await _database.insert('products', p,
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> saveStores(List<Map<String, dynamic>> stores) async {
    await _database.delete('stores');
    for (var s in stores) {
      await _database.insert('stores', s,
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<List<Map<String, dynamic>>> getProducts({String? search}) async {
    if (search != null && search.isNotEmpty) {
      return await _database.query('products',
          where: 'name LIKE ?', whereArgs: ['%$search%']);
    }
    return await _database.query('products');
  }

  Future<List<Map<String, dynamic>>> getStores() async {
    return await _database.query('stores');
  }

  Future<List<Map<String, dynamic>>> getFavorites() async {
    return await _database
        .query('products', where: 'isFavorite = ?', whereArgs: [1]);
  }

  Future<void> toggleFavorite(String id, bool isFavorite) async {
    await _database.update(
      'products',
      {'isFavorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> countProducts() async {
    final r = await _database.rawQuery('SELECT COUNT(*) as c FROM products');
    return Sqflite.firstIntValue(r) ?? 0;
  }

  Future<int> countStores() async {
    final r = await _database.rawQuery('SELECT COUNT(*) as c FROM stores');
    return Sqflite.firstIntValue(r) ?? 0;
  }

  Future<String?> getLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('lastSync');
  }

  Future<void> setLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastSync', DateTime.now().toIso8601String());
  }

  Future<bool> needsSync() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString('lastSync');
    if (s == null) return true;
    return DateTime.now().difference(DateTime.parse(s)).inDays > 7;
  }
}
