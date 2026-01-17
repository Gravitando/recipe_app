import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recipe.dart';

/// Fast Recipe API Service using Spoonacular
/// FREE tier: 150 requests/day
/// Sign up at: https://spoonacular.com/food-api
class SpoonacularApiService {
  // Your Spoonacular API Key
  static const String apiKey = '17087e92e86040eca15fbb452726ff7b';
  static const String baseUrl = 'https://api.spoonacular.com/recipes';

  /// Fetch random recipes (fast and diverse)
  Future<List<Recipe>> fetchRandomRecipes({int number = 50}) async {
    try {
      print('🔄 Fetching $number recipes from Spoonacular...');

      final response = await http.get(
        Uri.parse('$baseUrl/random?apiKey=$apiKey&number=$number'),
      ).timeout(const Duration(seconds: 15));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final recipes = data['recipes'] as List;
        final convertedRecipes = recipes.map((recipe) => _convertToRecipe(recipe)).toList();

        print('✅ Successfully loaded ${convertedRecipes.length} recipes from Spoonacular');
        return convertedRecipes;
      } else if (response.statusCode == 401) {
        print('❌ Error 401: Invalid API key');
        return [];
      } else if (response.statusCode == 402) {
        print('❌ Error 402: Daily limit exceeded (150 requests/day)');
        return [];
      } else {
        print('❌ Error ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error fetching random recipes: $e');
      return [];
    }
  }

  /// Search recipes by query
  Future<List<Recipe>> searchRecipes(String query, {int number = 20}) async {
    try {
      print('🔍 Searching Spoonacular for: $query');

      final response = await http.get(
        Uri.parse('$baseUrl/complexSearch?apiKey=$apiKey&query=$query&number=$number&addRecipeInformation=true&fillIngredients=true'),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List;
        print('✅ Found ${results.length} results');
        return results.map((recipe) => _convertToRecipe(recipe)).toList();
      }
      return [];
    } catch (e) {
      print('❌ Error searching recipes: $e');
      return [];
    }
  }

  /// Fetch recipes by cuisine
  Future<List<Recipe>> fetchByCuisine(String cuisine, {int number = 20}) async {
    try {
      print('🌍 Fetching $cuisine recipes from Spoonacular...');

      final response = await http.get(
        Uri.parse('$baseUrl/complexSearch?apiKey=$apiKey&cuisine=$cuisine&number=$number&addRecipeInformation=true&fillIngredients=true'),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List;
        print('✅ Got ${results.length} $cuisine recipes');
        return results.map((recipe) => _convertToRecipe(recipe)).toList();
      }
      return [];
    } catch (e) {
      print('❌ Error fetching by cuisine: $e');
      return [];
    }
  }

  /// Get recipe details by ID
  Future<Recipe?> getRecipeById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$id/information?apiKey=$apiKey&includeNutrition=false'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _convertToRecipe(data);
      }
      return null;
    } catch (e) {
      print('❌ Error getting recipe by ID: $e');
      return null;
    }
  }

  /// Convert Spoonacular format to our Recipe model
  Recipe _convertToRecipe(Map<String, dynamic> json) {
    // Extract ingredients
    String ingredients = '';
    if (json['extendedIngredients'] != null) {
      final ingredientsList = json['extendedIngredients'] as List;
      ingredients = ingredientsList
          .map((ing) => ing['original'] as String)
          .join('\n');
    }

    // Get instructions
    String instructions = '';
    if (json['instructions'] != null) {
      instructions = json['instructions'].toString().replaceAll(RegExp(r'<[^>]*>'), '');
    } else if (json['analyzedInstructions'] != null && (json['analyzedInstructions'] as List).isNotEmpty) {
      final steps = json['analyzedInstructions'][0]['steps'] as List;
      instructions = steps
          .map((step) => '${step['number']}. ${step['step']}')
          .join('\n\n');
    }

    // Map cuisines
    String cuisine = 'International';
    if (json['cuisines'] != null && (json['cuisines'] as List).isNotEmpty) {
      final cuisineList = json['cuisines'] as List;
      final firstCuisine = cuisineList.first.toString();

      if (firstCuisine.contains('Italian')) cuisine = 'Italian';
      else if (firstCuisine.contains('Mexican')) cuisine = 'Mexican';
      else if (firstCuisine.contains('Chinese')) cuisine = 'Chinese';
      else if (firstCuisine.contains('Indian')) cuisine = 'Indian';
      else if (firstCuisine.contains('Japanese')) cuisine = 'Japanese';
      else if (firstCuisine.contains('Thai')) cuisine = 'Thai';
      else if (firstCuisine.contains('Mediterranean') || firstCuisine.contains('Greek')) cuisine = 'Mediterranean';
      else if (firstCuisine.contains('American')) cuisine = 'American';
    }

    // Map meal type
    String mealType = 'Dinner';
    if (json['dishTypes'] != null && (json['dishTypes'] as List).isNotEmpty) {
      final types = json['dishTypes'] as List;
      final typeStr = types.first.toString().toLowerCase();

      if (typeStr.contains('breakfast') || typeStr.contains('brunch')) {
        mealType = 'Breakfast';
      } else if (typeStr.contains('lunch') || typeStr.contains('main course')) {
        mealType = 'Lunch';
      } else if (typeStr.contains('dinner')) {
        mealType = 'Dinner';
      } else if (typeStr.contains('dessert')) {
        mealType = 'Dessert';
      } else if (typeStr.contains('snack') || typeStr.contains('appetizer')) {
        mealType = 'Snack';
      }
    }

    return Recipe(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Untitled Recipe',
      description: json['summary']?.toString().replaceAll(RegExp(r'<[^>]*>'), '') ?? 'Delicious recipe',
      ingredients: ingredients.isNotEmpty ? ingredients : 'No ingredients listed',
      instructions: instructions.isNotEmpty ? instructions : 'No instructions available',
      cuisine: cuisine,
      mealType: mealType,
      prepTime: json['preparationMinutes'] ?? 15,
      cookTime: json['cookingMinutes'] ?? 30,
      servings: json['servings'] ?? 4,
      imagePath: json['image'],
      userId: -1, // API recipe indicator
      isFavorite: false,
      rating: (json['spoonacularScore'] ?? 50.0) / 20.0, // Convert to 0-5 scale
      dietaryInfo: (json['diets'] as List?)?.join(', '),
    );
  }

  /// Check API availability
  Future<bool> isApiAvailable() async {
    try {
      print('🔍 Checking Spoonacular API availability...');
      final response = await http.get(
        Uri.parse('$baseUrl/random?apiKey=$apiKey&number=1'),
      ).timeout(const Duration(seconds: 5));

      final isAvailable = response.statusCode == 200;
      print(isAvailable ? '✅ Spoonacular API is available' : '❌ Spoonacular API not available');
      return isAvailable;
    } catch (e) {
      print('❌ API check failed: $e');
      return false;
    }
  }
}