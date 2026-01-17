class MealPlan {
  final int? id;
  final int userId;
  final int recipeId;
  final DateTime date;
  final String mealType;
  final String? notes;
  final DateTime createdAt;

  MealPlan({
    this.id,
    required this.userId,
    required this.recipeId,
    required this.date,
    required this.mealType,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'recipe_id': recipeId,
      'date': date.toIso8601String(),
      'meal_type': mealType,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MealPlan.fromMap(Map<String, dynamic> map) {
    return MealPlan(
      id: map['id'],
      userId: map['user_id'],
      recipeId: map['recipe_id'],
      date: DateTime.parse(map['date']),
      mealType: map['meal_type'],
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  MealPlan copyWith({
    int? id,
    int? userId,
    int? recipeId,
    DateTime? date,
    String? mealType,
    String? notes,
    DateTime? createdAt,
  }) {
    return MealPlan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      recipeId: recipeId ?? this.recipeId,
      date: date ?? this.date,
      mealType: mealType ?? this.mealType,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}