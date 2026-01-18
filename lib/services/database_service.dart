import 'package:flutter/foundation.dart';
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
    if (_database != null) {
      debugPrint('✅ Using existing database connection');
      return _database!;
    }
    debugPrint('🔵 Initializing new database...');
    _database = await _initDB('recipe_app.db');
    debugPrint('✅ Database initialized successfully');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    debugPrint('📁 Database path: $path');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onOpen: (db) {
        debugPrint('✅ Database opened successfully');
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
    debugPrint('🔨 Creating database tables...');

    try {
      await db.execute('''
        CREATE TABLE users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          email TEXT NOT NULL UNIQUE,
          password TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
      debugPrint('✅ Users table created');

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
      debugPrint('✅ Recipes table created');

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
      debugPrint('✅ Meal plans table created');
      debugPrint('✅ All tables created successfully!');
    } catch (e) {
      debugPrint('❌ Error creating tables: $e');
      rethrow;
    }
  }

  // ===== USER OPERATIONS =====

  Future<User> createUser(User user) async {
    try {
      debugPrint('🔵 Creating user: ${user.name} (${user.email})');
      final db = await database;

      final existing = await getUserByEmail(user.email);
      if (existing != null) {
        debugPrint('❌ User already exists: ${user.email}');
        throw Exception('User with email ${user.email} already exists');
      }

      final userMap = user.toMap();
      debugPrint('🔵 User data to insert: $userMap');

      final id = await db.insert(
        'users',
        userMap,
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      debugPrint('✅ User created successfully with ID: $id');

      final insertedUser = await getUserById(id);
      if (insertedUser != null) {
        debugPrint('✅ User verified in database: ${insertedUser.name}');
        return insertedUser;
      } else {
        debugPrint('❌ User not found after insertion!');
        throw Exception('User creation verification failed');
      }
    } catch (e) {
      debugPrint('❌ Error creating user: $e');
      rethrow;
    }
  }

  Future<User?> getUserByEmail(String email) async {
    try {
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
    } catch (e) {
      debugPrint('❌ Error getting user by email: $e');
      return null;
    }
  }

  Future<User?> getUserById(int id) async {
    try {
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
    } catch (e) {
      debugPrint('❌ Error getting user by id: $e');
      return null;
    }
  }

  // ===== RECIPE OPERATIONS =====

  Future<Recipe> createRecipe(Recipe recipe) async {
    try {
      debugPrint('🔵 Creating recipe: ${recipe.title} for user ${recipe.userId}');
      final db = await database;
      final recipeMap = recipe.toMap();

      final id = await db.insert('recipes', recipeMap);
      debugPrint('✅ Recipe created with ID: $id');

      return recipe.copyWith(id: id);
    } catch (e) {
      debugPrint('❌ Error creating recipe: $e');
      rethrow;
    }
  }

  Future<List<Recipe>> getAllRecipes() async {
    try {
      final db = await database;
      final maps = await db.query('recipes', orderBy: 'created_at DESC');
      debugPrint('📊 Total recipes in database: ${maps.length}');
      return maps.map((map) => Recipe.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ Error getting all recipes: $e');
      return [];
    }
  }

  // OLD NAME - Keep for compatibility
  Future<List<Recipe>> getRecipesByUserId(int userId) async {
    return await getRecipesByUser(userId);
  }

  // NEW NAME
  Future<List<Recipe>> getRecipesByUser(int userId) async {
    try {
      final db = await database;
      final maps = await db.query(
        'recipes',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
      );
      debugPrint('📊 User $userId has ${maps.length} recipes');
      return maps.map((map) => Recipe.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ Error getting user recipes: $e');
      return [];
    }
  }

  // OLD NAME - Keep for compatibility
  Future<List<Recipe>> getFavoriteRecipes(int userId) async {
    return await getFavorites(userId);
  }

  // NEW NAME
  Future<List<Recipe>> getFavorites(int userId) async {
    try {
      final db = await database;
      final maps = await db.query(
        'recipes',
        where: 'user_id = ? AND is_favorite = 1',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
      );
      debugPrint('📊 User $userId has ${maps.length} favorite recipes');
      return maps.map((map) => Recipe.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ Error getting favorites: $e');
      return [];
    }
  }

  Future<List<Recipe>> getRecipesByCuisine(String cuisine) async {
    try {
      final db = await database;
      final maps = await db.query(
        'recipes',
        where: 'cuisine = ?',
        whereArgs: [cuisine],
        orderBy: 'created_at DESC',
      );
      debugPrint('📊 Found ${maps.length} recipes for cuisine: $cuisine');
      return maps.map((map) => Recipe.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ Error getting recipes by cuisine: $e');
      return [];
    }
  }

  Future<int> updateRecipe(Recipe recipe) async {
    try {
      debugPrint('🔵 Updating recipe ${recipe.id}: ${recipe.title}');
      final db = await database;
      final result = await db.update(
        'recipes',
        recipe.toMap(),
        where: 'id = ?',
        whereArgs: [recipe.id],
      );
      debugPrint('✅ Recipe updated (rows affected: $result)');
      return result;
    } catch (e) {
      debugPrint('❌ Error updating recipe: $e');
      return 0;
    }
  }

  Future<int> deleteRecipe(int id) async {
    try {
      debugPrint('🔵 Deleting recipe $id');
      final db = await database;
      final result = await db.delete(
        'recipes',
        where: 'id = ?',
        whereArgs: [id],
      );
      debugPrint('✅ Recipe deleted (rows affected: $result)');
      return result;
    } catch (e) {
      debugPrint('❌ Error deleting recipe: $e');
      return 0;
    }
  }

  Future<int> toggleFavorite(Recipe recipe) async {
    try {
      final db = await database;
      final newFavoriteStatus = recipe.isFavorite ? 0 : 1;
      debugPrint('🔵 Toggling favorite for recipe ${recipe.id} to $newFavoriteStatus');

      final result = await db.update(
        'recipes',
        {'is_favorite': newFavoriteStatus},
        where: 'id = ?',
        whereArgs: [recipe.id],
      );
      debugPrint('✅ Favorite toggled (rows affected: $result)');
      return result;
    } catch (e) {
      debugPrint('❌ Error toggling favorite: $e');
      return 0;
    }
  }

  Future<int> updateRating(Recipe recipe, double rating) async {
    try {
      debugPrint('🔵 Updating rating for recipe ${recipe.id} to $rating');
      final db = await database;
      final result = await db.update(
        'recipes',
        {'rating': rating},
        where: 'id = ?',
        whereArgs: [recipe.id],
      );
      debugPrint('✅ Rating updated (rows affected: $result)');
      return result;
    } catch (e) {
      debugPrint('❌ Error updating rating: $e');
      return 0;
    }
  }

  // ===== MEAL PLAN OPERATIONS =====

  Future<MealPlan> createMealPlan(MealPlan mealPlan) async {
    try {
      debugPrint('🔵 Creating meal plan for user ${mealPlan.userId}');
      final db = await database;
      final id = await db.insert('meal_plans', mealPlan.toMap());
      debugPrint('✅ Meal plan created with ID: $id');
      return mealPlan.copyWith(id: id);
    } catch (e) {
      debugPrint('❌ Error creating meal plan: $e');
      rethrow;
    }
  }

  Future<List<MealPlan>> getMealPlansByUserId(int userId) async {
    try {
      final db = await database;
      final maps = await db.query(
        'meal_plans',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'date ASC',
      );
      debugPrint('📊 User $userId has ${maps.length} meal plans');
      return maps.map((map) => MealPlan.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ Error getting meal plans: $e');
      return [];
    }
  }

  Future<List<MealPlan>> getMealPlansByDate(int userId, DateTime date) async {
    try {
      final db = await database;
      final dateStr = date.toIso8601String().split('T')[0]; // Get YYYY-MM-DD

      final maps = await db.query(
        'meal_plans',
        where: 'user_id = ? AND date LIKE ?',
        whereArgs: [userId, '$dateStr%'],
        orderBy: 'date ASC',
      );
      debugPrint('📊 Found ${maps.length} meal plans for $dateStr');
      return maps.map((map) => MealPlan.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ Error getting meal plans by date: $e');
      return [];
    }
  }

  Future<int> deleteMealPlan(int id) async {
    try {
      debugPrint('🔵 Deleting meal plan $id');
      final db = await database;
      final result = await db.delete(
        'meal_plans',
        where: 'id = ?',
        whereArgs: [id],
      );
      debugPrint('✅ Meal plan deleted (rows affected: $result)');
      return result;
    } catch (e) {
      debugPrint('❌ Error deleting meal plan: $e');
      return 0;
    }
  }

  // ===== UTILITY METHODS =====

  Future<void> printDatabaseStats() async {
    try {
      final db = await database;

      final userCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM users'),
      );
      final recipeCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM recipes'),
      );
      final mealPlanCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM meal_plans'),
      );

      debugPrint('📊 DATABASE STATS:');
      debugPrint('   Users: $userCount');
      debugPrint('   Recipes: $recipeCount');
      debugPrint('   Meal Plans: $mealPlanCount');
    } catch (e) {
      debugPrint('❌ Error getting database stats: $e');
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    debugPrint('✅ Database closed');
  }
}