import '../models/recipe.dart';
import 'database_service.dart';

class RecipeService {
  final DatabaseService _db = DatabaseService.instance;

  Future<List<Recipe>> getAllRecipes() async {
    return await _db.getAllRecipes();
  }

  Future<List<Recipe>> getUserRecipes(int userId) async {
    return await _db.getRecipesByUserId(userId);
  }

  Future<List<Recipe>> getFavorites(int userId) async {
    return await _db.getFavoriteRecipes(userId);
  }

  Future<List<Recipe>> getRecipesByCuisine(String cuisine) async {
    if (cuisine == 'All') {
      return await getAllRecipes();
    }
    return await _db.getRecipesByCuisine(cuisine);
  }

  Future<Recipe> createRecipe(Recipe recipe) async {
    return await _db.createRecipe(recipe);
  }

  Future<void> updateRecipe(Recipe recipe) async {
    await _db.updateRecipe(recipe);
  }

  Future<void> toggleFavorite(Recipe recipe) async {
    final updatedRecipe = recipe.copyWith(isFavorite: !recipe.isFavorite);
    await _db.updateRecipe(updatedRecipe);
  }

  Future<void> updateRating(Recipe recipe, double rating) async {
    final updatedRecipe = recipe.copyWith(rating: rating);
    await _db.updateRecipe(updatedRecipe);
  }

  Future<void> deleteRecipe(int recipeId) async {
    await _db.deleteRecipe(recipeId);
  }

  Future<List<Recipe>> searchRecipes(String query, List<Recipe> recipes) async {
    if (query.isEmpty) return recipes;

    final lowerQuery = query.toLowerCase();
    return recipes.where((recipe) {
      return recipe.title.toLowerCase().contains(lowerQuery) ||
          recipe.description.toLowerCase().contains(lowerQuery) ||
          recipe.ingredients.toLowerCase().contains(lowerQuery) ||
          recipe.cuisine.toLowerCase().contains(lowerQuery);
    }).toList();
  }
}