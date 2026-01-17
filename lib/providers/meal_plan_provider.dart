import 'package:flutter/foundation.dart';
import '../models/meal_plan.dart';
import '../services/database_service.dart';

class MealPlanProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  List<MealPlan> _mealPlans = [];
  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now();

  List<MealPlan> get mealPlans => _mealPlans;
  bool get isLoading => _isLoading;
  DateTime get selectedDate => _selectedDate;

  Future<void> loadMealPlans(int userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _mealPlans = await _db.getMealPlansByUserId(userId);
    } catch (e) {
      debugPrint('Error loading meal plans: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMealPlansByDate(int userId, DateTime date) async {
    try {
      _selectedDate = date;
      _mealPlans = await _db.getMealPlansByDate(userId, date);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading meal plans by date: $e');
    }
  }

  Future<void> addMealPlan(MealPlan mealPlan) async {
    try {
      final newMealPlan = await _db.createMealPlan(mealPlan);
      _mealPlans.add(newMealPlan);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding meal plan: $e');
    }
  }

  Future<void> deleteMealPlan(int mealPlanId) async {
    try {
      await _db.deleteMealPlan(mealPlanId);
      _mealPlans.removeWhere((mp) => mp.id == mealPlanId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting meal plan: $e');
    }
  }

  List<MealPlan> getMealPlansForDate(DateTime date) {
    return _mealPlans.where((mp) {
      return mp.date.year == date.year &&
          mp.date.month == date.month &&
          mp.date.day == date.day;
    }).toList();
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }
}