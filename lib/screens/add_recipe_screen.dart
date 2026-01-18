import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../models/recipe.dart';
import '../providers/recipe_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';

class AddRecipeScreen extends StatefulWidget {
  final Recipe? recipe;

  const AddRecipeScreen({super.key, this.recipe});

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

  String _selectedCuisine = 'Italian';
  String _selectedMealType = 'Breakfast';
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  final List<String> _cuisines = [
    'Italian', 'Mexican', 'Chinese', 'Indian', 'Japanese', 'Thai',
    'Mediterranean', 'American', 'French', 'Korean', 'Vietnamese',
    'Greek', 'Spanish', 'Middle Eastern', 'International',
  ];

  final List<String> _mealTypes = [
    'Breakfast', 'Lunch', 'Dinner', 'Snack', 'Dessert', 'Appetizer',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.recipe != null) {
      _titleController.text = widget.recipe!.title;
      _descriptionController.text = widget.recipe!.description;
      _ingredientsController.text = widget.recipe!.ingredients;
      _instructionsController.text = widget.recipe!.instructions;
      _prepTimeController.text = widget.recipe!.prepTime.toString();
      _cookTimeController.text = widget.recipe!.cookTime.toString();
      _servingsController.text = widget.recipe!.servings.toString();
      _selectedCuisine = widget.recipe!.cuisine;
      _selectedMealType = widget.recipe!.mealType;
    }
  }

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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (pickedFile != null && mounted) {
        setState(() => _imageFile = File(pickedFile.path));
      }
    } catch (e) {
      debugPrint('Image error: $e');
    }
  }

  void _showImageDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera, color: AppColors.primaryColor),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primaryColor),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_imageFile != null || widget.recipe?.imagePath != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Remove', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _imageFile = null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final recipes = Provider.of<RecipeProvider>(context, listen: false);

    if (auth.currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login')),
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    try {
      final recipe = Recipe(
        id: widget.recipe?.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        ingredients: _ingredientsController.text.trim(),
        instructions: _instructionsController.text.trim(),
        cuisine: _selectedCuisine,
        mealType: _selectedMealType,
        prepTime: int.tryParse(_prepTimeController.text) ?? 0,
        cookTime: int.tryParse(_cookTimeController.text) ?? 0,
        servings: int.tryParse(_servingsController.text) ?? 1,
        imagePath: _imageFile?.path ?? widget.recipe?.imagePath,
        userId: auth.currentUser!.id!,
        isFavorite: widget.recipe?.isFavorite ?? false,
        rating: widget.recipe?.rating ?? 0.0,
      );

      if (widget.recipe == null) {
        await recipes.addRecipe(recipe);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✓ Recipe added!'), backgroundColor: Colors.green),
          );
        }
      } else {
        await recipes.updateRecipe(recipe);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✓ Recipe updated!'), backgroundColor: Colors.green),
          );
        }
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error saving')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.recipe != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Recipe' : 'Add Recipe')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Image
            GestureDetector(
              onTap: _showImageDialog,
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: _imageFile != null
                      ? Image.file(_imageFile!, fit: BoxFit.cover)
                      : widget.recipe?.imagePath != null && !widget.recipe!.imagePath!.startsWith('http')
                      ? Image.file(File(widget.recipe!.imagePath!), fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder())
                      : _placeholder(),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            _field(_titleController, 'Recipe Title', Icons.restaurant, validator: true),
            const SizedBox(height: 16),

            // Description
            _field(_descriptionController, 'Description', Icons.description, lines: 2, validator: true),
            const SizedBox(height: 16),

            // Dropdowns
            Row(
              children: [
                Expanded(child: _dropdown(Icons.public, _selectedCuisine, _cuisines, (v) => setState(() => _selectedCuisine = v!))),
                const SizedBox(width: 12),
                Expanded(child: _dropdown(Icons.restaurant_menu, _selectedMealType, _mealTypes, (v) => setState(() => _selectedMealType = v!))),
              ],
            ),
            const SizedBox(height: 16),

            // Times
            Row(
              children: [
                Expanded(child: _field(_prepTimeController, 'Prep (min)', Icons.timer, number: true, validator: true)),
                const SizedBox(width: 12),
                Expanded(child: _field(_cookTimeController, 'Cook (min)', Icons.local_fire_department, number: true, validator: true)),
              ],
            ),
            const SizedBox(height: 16),

            // Servings
            _field(_servingsController, 'Servings', Icons.people, number: true, validator: true),
            const SizedBox(height: 16),

            // Ingredients
            _field(_ingredientsController, 'Ingredients', Icons.list, lines: 6, validator: true),
            const SizedBox(height: 16),

            // Instructions
            _field(_instructionsController, 'Instructions', Icons.format_list_numbered, lines: 8, validator: true),
            const SizedBox(height: 24),

            // Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : Text(isEdit ? 'Update' : 'Save', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon, {int lines = 1, bool number = false, bool validator = false}) {
    return TextFormField(
      controller: c,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: lines > 1 ? Padding(padding: EdgeInsets.only(bottom: lines * 15.0), child: Icon(icon)) : Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
        alignLabelWithHint: lines > 1,
      ),
      maxLines: lines,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      textCapitalization: number ? TextCapitalization.none : TextCapitalization.sentences,
      validator: validator ? (v) => v?.trim().isEmpty ?? true ? 'Required' : (number && int.tryParse(v!) == null ? 'Number' : null) : null,
    );
  }

  Widget _dropdown(IconData icon, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_outlined, size: 56, color: Colors.grey[400]),
        const SizedBox(height: 12),
        Text('Tap to add image', style: TextStyle(color: Colors.grey[600], fontSize: 15)),
      ],
    );
  }
}