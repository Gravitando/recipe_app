import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recipe_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../widgets/recipe_card.dart';
import 'add_recipe_screen.dart';

class RecipeListScreen extends StatefulWidget {
  const RecipeListScreen({super.key});

  @override
  State<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load API recipes when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
      recipeProvider.loadApiRecipes();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recipeProvider = Provider.of<RecipeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipes'),
        actions: [
          IconButton(
            icon: Icon(recipeProvider.showApiRecipes
                ? Icons.cloud
                : Icons.cloud_off),
            tooltip: recipeProvider.showApiRecipes
                ? 'Hide Online Recipes'
                : 'Show Online Recipes',
            onPressed: () {
              recipeProvider.toggleApiRecipes(!recipeProvider.showApiRecipes);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              recipeProvider.loadRecipes();
              recipeProvider.loadApiRecipes();
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddRecipeScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search recipes...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    recipeProvider.searchRecipes('');
                  },
                )
                    : null,
              ),
              onChanged: (value) {
                recipeProvider.searchRecipes(value);
              },
            ),
          ),

          // Recipe Source Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Chip(
                  avatar: const Icon(Icons.phone_android, size: 16),
                  label: Text('My Recipes: ${recipeProvider.localRecipes.length}'),
                  backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                ),
                const SizedBox(width: 8),
                if (recipeProvider.showApiRecipes)
                  Chip(
                    avatar: const Icon(Icons.cloud, size: 16),
                    label: Text('Online: ${recipeProvider.apiRecipes.length}'),
                    backgroundColor: Colors.blue.withOpacity(0.1),
                  ),
              ],
            ),
          ),

          // Cuisine Filter
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: AppConstants.cuisineTypes.length,
              itemBuilder: (context, index) {
                final cuisine = AppConstants.cuisineTypes[index];
                final isSelected = recipeProvider.selectedCuisine == cuisine;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cuisine),
                    selected: isSelected,
                    onSelected: (selected) {
                      recipeProvider.filterByCuisine(cuisine);
                    },
                    backgroundColor: Colors.grey[200],
                    selectedColor: AppColors.primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),

          // Recipe List
          Expanded(
            child: recipeProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : recipeProvider.recipes.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.restaurant_menu,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No recipes found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (!recipeProvider.showApiRecipes)
                    TextButton.icon(
                      onPressed: () {
                        recipeProvider.toggleApiRecipes(true);
                        recipeProvider.loadApiRecipes();
                      },
                      icon: const Icon(Icons.cloud),
                      label: const Text('Load Online Recipes'),
                    ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddRecipeScreen(),
                        ),
                      );
                    },
                    child: const Text('Add your first recipe'),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: () async {
                await recipeProvider.loadRecipes();
                await recipeProvider.loadApiRecipes();
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: recipeProvider.recipes.length,
                itemBuilder: (context, index) {
                  final recipe = recipeProvider.recipes[index];
                  final isApiRecipe = recipe.userId == -1;

                  return Stack(
                    children: [
                      RecipeCard(
                        recipe: recipe,
                        userId: authProvider.currentUser?.id ?? 0,
                      ),
                      if (isApiRecipe)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.cloud,
                                  size: 12,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Online',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}