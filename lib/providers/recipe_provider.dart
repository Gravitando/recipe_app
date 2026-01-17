import 'package:flutter/foundation.dart';
import '../models/recipe.dart';
import '../services/recipe_service.dart';
import '../services/hybrid_api_service.dart';
import '../services/api_favorites_service.dart';

class RecipeProvider with ChangeNotifier {
  final RecipeService _recipeService = RecipeService();
  final HybridApiService _apiService = HybridApiService();
  final ApiFavoritesService _apiFavoritesService = ApiFavoritesService();

  List<Recipe> _localRecipes = [];
  List<Recipe> _apiRecipes = [];
  List<Recipe> _filteredRecipes = [];
  List<Recipe> _favorites = [];
  List<Recipe> _apiFavorites = [];
  Set<int> _apiFavoriteIds = {};
  bool _isLoading = false;
  bool _isLoadingApi = false;
  String _selectedCuisine = 'All';
  String _searchQuery = '';
  bool _showApiRecipes = true;

  List<Recipe> get recipes => _filteredRecipes;
  List<Recipe> get localRecipes => _localRecipes;
  List<Recipe> get apiRecipes => _apiRecipes;
  List<Recipe> get favorites => [..._favorites, ..._apiFavorites];
  List<Recipe> get localFavorites => _favorites;
  List<Recipe> get apiFavorites => _apiFavorites;
  bool get isLoading => _isLoading || _isLoadingApi;
  String get selectedCuisine => _selectedCuisine;
  bool get showApiRecipes => _showApiRecipes;

  Future<void> loadRecipes() async {
    _isLoading = true;
    notifyListeners();

    try {
      _localRecipes = await _recipeService.getAllRecipes();
      _applyFilters();
    } catch (e) {
      debugPrint('Error loading local recipes: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadApiRecipes() async {
    _isLoadingApi = true;
    notifyListeners();

    try {
      final hasInternet = await _apiService.hasInternetConnection();
      if (!hasInternet) {
        debugPrint('No internet connection');
        _isLoadingApi = false;
        notifyListeners();
        return;
      }

      _apiRecipes = await _apiService.fetchSharedRecipes();

      // Load favorite status for API recipes
      _apiFavoriteIds = await _apiFavoritesService.getFavoriteIds();

      // Update favorite status
      _apiRecipes = _apiRecipes.map((recipe) {
        return recipe.copyWith(
          isFavorite: _apiFavoriteIds.contains(recipe.id),
        );
      }).toList();

      _applyFilters();
    } catch (e) {
      debugPrint('Error loading API recipes: $e');
    }

    _isLoadingApi = false;
    notifyListeners();
  }

  Future<void> searchApiRecipes(String query) async {
    if (query.isEmpty) {
      await loadApiRecipes();
      return;
    }

    _isLoadingApi = true;
    notifyListeners();

    try {
      _apiRecipes = await _apiService.searchRecipes(query);

      // Update favorite status
      _apiFavoriteIds = await _apiFavoritesService.getFavoriteIds();
      _apiRecipes = _apiRecipes.map((recipe) {
        return recipe.copyWith(
          isFavorite: _apiFavoriteIds.contains(recipe.id),
        );
      }).toList();

      _applyFilters();
    } catch (e) {
      debugPrint('Error searching API recipes: $e');
    }

    _isLoadingApi = false;
    notifyListeners();
  }

  void toggleApiRecipes(bool show) {
    _showApiRecipes = show;
    _applyFilters();
    notifyListeners();
  }

  Future<void> loadFavorites(int userId) async {
    try {
      // Load local favorites
      _favorites = await _recipeService.getFavorites(userId);

      // Load API favorites
      _apiFavoriteIds = await _apiFavoritesService.getFavoriteIds();
      _apiFavorites = _apiRecipes
          .where((recipe) => _apiFavoriteIds.contains(recipe.id))
          .toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    }
  }

  Future<void> addRecipe(Recipe recipe) async {
    try {
      final newRecipe = await _recipeService.createRecipe(recipe);
      _localRecipes.insert(0, newRecipe);
      _applyFilters();
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding recipe: $e');
    }
  }

  Future<void> updateRecipe(Recipe recipe) async {
    try {
      await _recipeService.updateRecipe(recipe);
      final index = _localRecipes.indexWhere((r) => r.id == recipe.id);
      if (index != -1) {
        _localRecipes[index] = recipe;
        _applyFilters();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating recipe: $e');
    }
  }

  Future<void> deleteRecipe(int recipeId) async {
    try {
      await _recipeService.deleteRecipe(recipeId);
      _localRecipes.removeWhere((r) => r.id == recipeId);
      _favorites.removeWhere((r) => r.id == recipeId);
      _applyFilters();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting recipe: $e');
    }
  }

  Future<void> toggleFavorite(Recipe recipe, int userId) async {
    try {
      // Check if it's an API recipe (negative or very large ID)
      if (recipe.userId == -1) {
        // Handle API recipe favorite
        await _apiFavoritesService.toggleFavorite(recipe.id!);

        // Update the recipe in the list
        final index = _apiRecipes.indexWhere((r) => r.id == recipe.id);
        if (index != -1) {
          _apiRecipes[index] = recipe.copyWith(isFavorite: !recipe.isFavorite);
        }

        // Reload favorites
        await loadFavorites(userId);
        _applyFilters();
      } else {
        // Handle local recipe favorite
        await _recipeService.toggleFavorite(recipe);
        final index = _localRecipes.indexWhere((r) => r.id == recipe.id);
        if (index != -1) {
          _localRecipes[index] = recipe.copyWith(isFavorite: !recipe.isFavorite);
          _applyFilters();
        }
        await loadFavorites(userId);
      }
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
    }
  }

  Future<void> updateRating(Recipe recipe, double rating) async {
    try {
      await _recipeService.updateRating(recipe, rating);
      final index = _localRecipes.indexWhere((r) => r.id == recipe.id);
      if (index != -1) {
        _localRecipes[index] = recipe.copyWith(rating: rating);
        _applyFilters();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating rating: $e');
    }
  }

  void filterByCuisine(String cuisine) {
    _selectedCuisine = cuisine;
    _applyFilters();
    notifyListeners();
  }

  void searchRecipes(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    // Combine local and API recipes
    List<Recipe> allRecipes = [
      ..._localRecipes,
      if (_showApiRecipes) ..._apiRecipes,
    ];

    _filteredRecipes = allRecipes;

    if (_selectedCuisine != 'All') {
      _filteredRecipes = _filteredRecipes
          .where((recipe) => recipe.cuisine == _selectedCuisine)
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      final lowerQuery = _searchQuery.toLowerCase();
      _filteredRecipes = _filteredRecipes.where((recipe) {
        return recipe.title.toLowerCase().contains(lowerQuery) ||
            recipe.description.toLowerCase().contains(lowerQuery) ||
            recipe.ingredients.toLowerCase().contains(lowerQuery);
      }).toList();
    }
  }
}