import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Service to manage favorites for API recipes
/// Stores API recipe IDs locally in SharedPreferences
class ApiFavoritesService {
  static const String _favoritesKey = 'api_favorites';

  /// Get list of favorite API recipe IDs
  Future<Set<int>> getFavoriteIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getString(_favoritesKey);

      if (favoritesJson == null) return {};

      final List<dynamic> favoritesList = jsonDecode(favoritesJson);
      return favoritesList.map((id) => id as int).toSet();
    } catch (e) {
      print('Error getting favorites: $e');
      return {};
    }
  }

  /// Check if a recipe is favorite
  Future<bool> isFavorite(int recipeId) async {
    final favorites = await getFavoriteIds();
    return favorites.contains(recipeId);
  }

  /// Add recipe to favorites
  Future<bool> addFavorite(int recipeId) async {
    try {
      final favorites = await getFavoriteIds();
      favorites.add(recipeId);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_favoritesKey, jsonEncode(favorites.toList()));
      return true;
    } catch (e) {
      print('Error adding favorite: $e');
      return false;
    }
  }

  /// Remove recipe from favorites
  Future<bool> removeFavorite(int recipeId) async {
    try {
      final favorites = await getFavoriteIds();
      favorites.remove(recipeId);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_favoritesKey, jsonEncode(favorites.toList()));
      return true;
    } catch (e) {
      print('Error removing favorite: $e');
      return false;
    }
  }

  /// Toggle favorite status
  Future<bool> toggleFavorite(int recipeId) async {
    final isFav = await isFavorite(recipeId);

    if (isFav) {
      return await removeFavorite(recipeId);
    } else {
      return await addFavorite(recipeId);
    }
  }

  /// Clear all favorites
  Future<void> clearFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_favoritesKey);
  }
}