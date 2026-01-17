import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recipe.dart';

/// Fast and Reliable Recipe API Service
/// Uses TheMealDB - 100% FREE, no API key required
/// 600+ recipes with high-quality images
class HybridApiService {
  static const String baseUrl = 'https://www.themealdb.com/api/json/v1/1';

  /// Fetch diverse recipes from multiple cuisines (FAST)
  Future<List<Recipe>> fetchSharedRecipes() async {
    try {
      List<Recipe> allRecipes = [];

      // Fetch multiple categories in parallel for speed
      final futures = [
        _fetchByCategory('Seafood'),
        _fetchByCategory('Pasta'),
        _fetchByCategory('Chicken'),
        _fetchByCategory('Beef'),
        _fetchByCategory('Vegetarian'),
        _fetchByCategory('Dessert'),
        _fetchByArea('Italian'),
        _fetchByArea('Mexican'),
        _fetchByArea('Indian'),
        _fetchByArea('Chinese'),
        _fetchByArea('Japanese'),
      ];

      final results = await Future.wait(futures);
      for (var recipes in results) {
        allRecipes.addAll(recipes.take(5)); // Take 5 from each
      }

      return allRecipes..shuffle(); // Shuffle for variety
    } catch (e) {
      print('Error fetching shared recipes: $e');
      return [];
    }
  }

  /// Fast category fetch (internal)
  Future<List<Recipe>> _fetchByCategory(String category) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/filter.php?c=$category'),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final meals = data['meals'] as List?;
        if (meals == null) return [];

        // Get full details for first 5 meals
        List<Recipe> recipes = [];
        for (var meal in meals.take(5)) {
          final recipe = await fetchRecipeById(meal['idMeal']);
          if (recipe != null) recipes.add(recipe);
        }
        return recipes;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Fast area/cuisine fetch (internal)
  Future<List<Recipe>> _fetchByArea(String area) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/filter.php?a=$area'),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final meals = data['meals'] as List?;
        if (meals == null) return [];

        List<Recipe> recipes = [];
        for (var meal in meals.take(5)) {
          final recipe = await fetchRecipeById(meal['idMeal']);
          if (recipe != null) recipes.add(recipe);
        }
        return recipes;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Search recipes by name
  Future<List<Recipe>> searchRecipes(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/search.php?s=$query'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final meals = data['meals'] as List?;
        if (meals == null) return [];
        return meals.map((meal) => _convertMealToRecipe(meal)).toList();
      }
      return [];
    } catch (e) {
      print('Error searching recipes: $e');
      return [];
    }
  }

  /// Get single recipe by ID
  Future<Recipe?> fetchRecipeById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/lookup.php?i=$id'),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final meals = data['meals'] as List?;
        if (meals != null && meals.isNotEmpty) {
          return _convertMealToRecipe(meals[0]);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Filter by cuisine
  Future<List<Recipe>> fetchRecipesByArea(String area) async {
    return await _fetchByArea(area);
  }

  /// Convert API data to Recipe model
  Recipe _convertMealToRecipe(Map<String, dynamic> meal) {
    // Extract ingredients with measurements
    List<String> ingredients = [];
    for (int i = 1; i <= 20; i++) {
      final ingredient = meal['strIngredient$i'];
      final measure = meal['strMeasure$i'];
      if (ingredient != null && ingredient.toString().trim().isNotEmpty) {
        ingredients.add('${measure ?? ''} $ingredient'.trim());
      }
    }

    // Map cuisine
    String cuisine = _mapCuisine(meal['strArea'] ?? 'International');

    // Map meal type
    String mealType = _mapMealType(meal['strCategory'] ?? '');

    return Recipe(
      id: int.parse(meal['idMeal'] ?? '0'),
      title: meal['strMeal'] ?? 'Unknown Recipe',
      description: '${meal['strCategory'] ?? 'Delicious'} dish from ${meal['strArea'] ?? 'around the world'}',
      ingredients: ingredients.join('\n'),
      instructions: meal['strInstructions'] ?? 'No instructions available',
      cuisine: cuisine,
      mealType: mealType,
      prepTime: 15,
      cookTime: 30,
      servings: 4,
      imagePath: meal['strMealThumb'],
      userId: -1, // API recipe
      isFavorite: false,
      rating: 4.5,
      dietaryInfo: meal['strTags'],
    );
  }

  /// Map API cuisine to app cuisines
  String _mapCuisine(String apiCuisine) {
    final cuisine = apiCuisine.toLowerCase();
    if (cuisine.contains('italian')) return 'Italian';
    if (cuisine.contains('mexican')) return 'Mexican';
    if (cuisine.contains('chinese')) return 'Chinese';
    if (cuisine.contains('indian')) return 'Indian';
    if (cuisine.contains('japanese')) return 'Japanese';
    if (cuisine.contains('thai')) return 'Thai';
    if (cuisine.contains('american') || cuisine.contains('british') || cuisine.contains('canadian')) {
      return 'American';
    }
    if (cuisine.contains('french') || cuisine.contains('greek') || cuisine.contains('spanish')) {
      return 'Mediterranean';
    }
    return 'International';
  }

  /// Map API category to meal types
  String _mapMealType(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('breakfast')) return 'Breakfast';
    if (cat.contains('dessert')) return 'Dessert';
    if (cat.contains('starter') || cat.contains('side')) return 'Snack';
    return 'Dinner';
  }

  /// Check internet connection
  Future<bool> hasInternetConnection() async {
    try {
      final response = await http.get(
        Uri.parse('https://www.google.com'),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}