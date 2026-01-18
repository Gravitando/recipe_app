import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Service to manage favorites for API recipes
/// Stores API recipe IDs per user in SharedPreferences
class ApiFavoritesService {
  // Store favorites per user using userId in the key
  String _getFavoritesKey(int userId) => 'api_favorites_user_$userId';

  /// Get list of favorite API recipe IDs for specific user
  Future<Set<int>> getFavoriteIds(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getString(_getFavoritesKey(userId));

      if (favoritesJson == null) return {};

      final List<dynamic> favoritesList = jsonDecode(favoritesJson);
      return favoritesList.map((id) => id as int).toSet();
    } catch (e) {
      debugPrint('Error getting favorites: $e');
      return {};
    }
  }

  /// Check if a recipe is favorite for specific user
  Future<bool> isFavorite(int recipeId, int userId) async {
    final favorites = await getFavoriteIds(userId);
    return favorites.contains(recipeId);
  }

  /// Add recipe to favorites for specific user
  Future<bool> addFavorite(int recipeId, int userId) async {
    try {
      final favorites = await getFavoriteIds(userId);
      favorites.add(recipeId);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _getFavoritesKey(userId),
        jsonEncode(favorites.toList()),
      );
      return true;
    } catch (e) {
      debugPrint('Error adding favorite: $e');
      return false;
    }
  }

  /// Remove recipe from favorites for specific user
  Future<bool> removeFavorite(int recipeId, int userId) async {
    try {
      final favorites = await getFavoriteIds(userId);
      favorites.remove(recipeId);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _getFavoritesKey(userId),
        jsonEncode(favorites.toList()),
      );
      return true;
    } catch (e) {
      debugPrint('Error removing favorite: $e');
      return false;
    }
  }

  /// Toggle favorite status for specific user
  Future<bool> toggleFavorite(int recipeId, int userId) async {
    final isFav = await isFavorite(recipeId, userId);

    if (isFav) {
      return await removeFavorite(recipeId, userId);
    } else {
      return await addFavorite(recipeId, userId);
    }
  }

  /// Clear all favorites for specific user
  Future<void> clearFavorites(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_getFavoritesKey(userId));
  }

  /// Clear all favorites for all users (admin/debug only)
  Future<void> clearAllUsersFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('api_favorites_user_')) {
        await prefs.remove(key);
      }
    }
  }
}