import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/meal_plan_provider.dart';
import '../providers/recipe_provider.dart';
import '../providers/auth_provider.dart';
import '../models/meal_plan.dart';
import '../utils/constants.dart';

class MealPlannerScreen extends StatefulWidget {
  const MealPlannerScreen({super.key});

  @override
  State<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends State<MealPlannerScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final mealPlanProvider = Provider.of<MealPlanProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final recipeProvider = Provider.of<RecipeProvider>(context);

    final mealsForDay = mealPlanProvider.getMealPlansForDate(_selectedDay);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Planner'),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            calendarStyle: CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: AppColors.primaryColor,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: AppColors.accentColor,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: AppColors.primaryColor,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            eventLoader: (day) {
              return mealPlanProvider.getMealPlansForDate(day);
            },
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Meals for ${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle),
                  color: AppColors.primaryColor,
                  iconSize: 32,
                  onPressed: () => _showAddMealDialog(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: mealsForDay.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 60,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No meals planned for this day',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => _showAddMealDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Meal'),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: mealsForDay.length,
              itemBuilder: (context, index) {
                final mealPlan = mealsForDay[index];
                final recipe = recipeProvider.recipes.firstWhere(
                      (r) => r.id == mealPlan.recipeId,
                  orElse: () => recipeProvider.recipes.first,
                );

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                      child: Icon(
                        Icons.restaurant_menu,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    title: Text(
                      mealPlan.mealType,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(recipe.title),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Remove Meal'),
                            content: const Text('Remove this meal from your plan?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  mealPlanProvider.deleteMealPlan(mealPlan.id!);
                                  Navigator.pop(context);
                                },
                                child: const Text(
                                  'Remove',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddMealDialog(BuildContext context) {
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
    final mealPlanProvider = Provider.of<MealPlanProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (recipeProvider.recipes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add some recipes first!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    String selectedMealType = AppConstants.mealTypes[0];
    int? selectedRecipeId = recipeProvider.recipes.first.id;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Meal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedMealType,
                  decoration: const InputDecoration(
                    labelText: 'Meal Type',
                    border: OutlineInputBorder(),
                  ),
                  items: AppConstants.mealTypes
                      .map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedMealType = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: selectedRecipeId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Recipe',
                    border: OutlineInputBorder(),
                  ),
                  items: recipeProvider.recipes
                      .map((recipe) => DropdownMenuItem(
                    value: recipe.id,
                    child: Text(
                      recipe.title,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedRecipeId = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedRecipeId != null) {
                  final mealPlan = MealPlan(
                    userId: authProvider.currentUser!.id!,
                    recipeId: selectedRecipeId!,
                    date: _selectedDay,
                    mealType: selectedMealType,
                  );
                  mealPlanProvider.addMealPlan(mealPlan);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Meal added to plan!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}