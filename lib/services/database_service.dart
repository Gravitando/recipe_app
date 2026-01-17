import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import '../models/recipe.dart';
import '../models/meal_plan.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('recipe_app.db');
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
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE recipes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        ingredients TEXT NOT NULL,
        instructions TEXT NOT NULL,
        cuisine TEXT NOT NULL,
        meal_type TEXT NOT NULL,
        prep_time INTEGER NOT NULL,
        cook_time INTEGER NOT NULL,
        servings INTEGER NOT NULL,
        image_path TEXT,
        user_id INTEGER NOT NULL,
        is_favorite INTEGER DEFAULT 0,
        rating REAL DEFAULT 0.0,
        dietary_info TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE meal_plans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        recipe_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        meal_type TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (recipe_id) REFERENCES recipes (id) ON DELETE CASCADE
      )
    ''');
  }

  // User operations
  Future<User> createUser(User user) async {
    final db = await database;
    final id = await db.insert('users', user.toMap());
    return user.copyWith(id: id);
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<User?> getUserById(int id) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  // Recipe operations
  Future<Recipe> createRecipe(Recipe recipe) async {
    final db = await database;
    final id = await db.insert('recipes', recipe.toMap());
    return recipe.copyWith(id: id);
  }

  Future<List<Recipe>> getAllRecipes() async {
    final db = await database;
    final maps = await db.query('recipes', orderBy: 'created_at DESC');
    return maps.map((map) => Recipe.fromMap(map)).toList();
  }

  Future<List<Recipe>> getRecipesByUserId(int userId) async {
    final db = await database;
    final maps = await db.query(
      'recipes',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Recipe.fromMap(map)).toList();
  }

  Future<List<Recipe>> getFavoriteRecipes(int userId) async {
    final db = await database;
    final maps = await db.query(
      'recipes',
      where: 'user_id = ? AND is_favorite = 1',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Recipe.fromMap(map)).toList();
  }

  Future<List<Recipe>> getRecipesByCuisine(String cuisine) async {
    final db = await database;
    final maps = await db.query(
      'recipes',
      where: 'cuisine = ?',
      whereArgs: [cuisine],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Recipe.fromMap(map)).toList();
  }

  Future<int> updateRecipe(Recipe recipe) async {
    final db = await database;
    return db.update(
      'recipes',
      recipe.toMap(),
      where: 'id = ?',
      whereArgs: [recipe.id],
    );
  }

  Future<int> deleteRecipe(int id) async {
    final db = await database;
    return await db.delete(
      'recipes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Meal Plan operations
  Future<MealPlan> createMealPlan(MealPlan mealPlan) async {
    final db = await database;
    final id = await db.insert('meal_plans', mealPlan.toMap());
    return mealPlan.copyWith(id: id);
  }

  Future<List<MealPlan>> getMealPlansByUserId(int userId) async {
    final db = await database;
    final maps = await db.query(
      'meal_plans',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date ASC',
    );
    return maps.map((map) => MealPlan.fromMap(map)).toList();
  }

  Future<List<MealPlan>> getMealPlansByDate(int userId, DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final maps = await db.query(
      'meal_plans',
      where: 'user_id = ? AND date >= ? AND date < ?',
      whereArgs: [userId, startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'date ASC',
    );
    return maps.map((map) => MealPlan.fromMap(map)).toList();
  }

  Future<int> deleteMealPlan(int id) async {
    final db = await database;
    return await db.delete(
      'meal_plans',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}