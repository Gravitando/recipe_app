import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
import '../providers/recipe_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';

class AddRecipeScreen extends StatefulWidget {
  const AddRecipeScreen({super.key});

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _ingredientsController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _prepTimeController = TextEditingController();
  final _cookTimeController = TextEditingController();
  final _servingsController = TextEditingController();

  String _selectedCuisine = AppConstants.cuisineTypes[1];
  String _selectedMealType = AppConstants.mealTypes[0];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _ingredientsController.dispose();
    _instructionsController.dispose();
    _prepTimeController.dispose();
    _cookTimeController.dispose();
    _servingsController.dispose();
    super.dispose();
  }

  Future<void> _saveRecipe() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);

      final recipe = Recipe(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        ingredients: _ingredientsController.text.trim(),
        instructions: _instructionsController.text.trim(),
        cuisine: _selectedCuisine,
        mealType: _selectedMealType,
        prepTime: int.parse(_prepTimeController.text),
        cookTime: int.parse(_cookTimeController.text),
        servings: int.parse(_servingsController.text),
        userId: authProvider.currentUser!.id!,
      );

      await recipeProvider.addRecipe(recipe);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recipe added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Recipe'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Recipe Title',
                hintText: 'e.g., Spaghetti Carbonara',
              ),
              validator: (v) => Validators.validateRequired(v, 'Title'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Brief description of your recipe',
              ),
              maxLines: 2,
              validator: (v) => Validators.validateRequired(v, 'Description'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCuisine,
              decoration: const InputDecoration(
                labelText: 'Cuisine Type',
              ),
              items: AppConstants.cuisineTypes
                  .skip(1)
                  .map((cuisine) => DropdownMenuItem(
                value: cuisine,
                child: Text(cuisine),
              ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCuisine = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedMealType,
              decoration: const InputDecoration(
                labelText: 'Meal Type',
              ),
              items: AppConstants.mealTypes
                  .map((type) => DropdownMenuItem(
                value: type,
                child: Text(type),
              ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedMealType = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _prepTimeController,
                    decoration: const InputDecoration(
                      labelText: 'Prep Time (min)',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => Validators.validateRequired(v, 'Prep time'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _cookTimeController,
                    decoration: const InputDecoration(
                      labelText: 'Cook Time (min)',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => Validators.validateRequired(v, 'Cook time'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _servingsController,
              decoration: const InputDecoration(
                labelText: 'Servings',
                hintText: 'Number of servings',
              ),
              keyboardType: TextInputType.number,
              validator: (v) => Validators.validateRequired(v, 'Servings'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ingredientsController,
              decoration: const InputDecoration(
                labelText: 'Ingredients',
                hintText: 'Enter each ingredient on a new line',
                alignLabelWithHint: true,
              ),
              maxLines: 6,
              validator: (v) => Validators.validateRequired(v, 'Ingredients'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _instructionsController,
              decoration: const InputDecoration(
                labelText: 'Cooking Instructions',
                hintText: 'Step by step instructions...',
                alignLabelWithHint: true,
              ),
              maxLines: 8,
              validator: (v) => Validators.validateRequired(v, 'Instructions'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveRecipe,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text('Save Recipe'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}