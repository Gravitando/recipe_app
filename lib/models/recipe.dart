class Recipe {
  final int? id;
  final String title;
  final String description;
  final String ingredients;
  final String instructions;
  final String cuisine;
  final String mealType;
  final int prepTime;
  final int cookTime;
  final int servings;
  final String? imagePath;
  final int userId;
  final bool isFavorite;
  final double rating;
  final String? dietaryInfo;
  final DateTime createdAt;

  Recipe({
    this.id,
    required this.title,
    required this.description,
    required this.ingredients,
    required this.instructions,
    required this.cuisine,
    required this.mealType,
    required this.prepTime,
    required this.cookTime,
    required this.servings,
    this.imagePath,
    required this.userId,
    this.isFavorite = false,
    this.rating = 0.0,
    this.dietaryInfo,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  int get totalTime => prepTime + cookTime;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'ingredients': ingredients,
      'instructions': instructions,
      'cuisine': cuisine,
      'meal_type': mealType,
      'prep_time': prepTime,
      'cook_time': cookTime,
      'servings': servings,
      'image_path': imagePath,
      'user_id': userId,
      'is_favorite': isFavorite ? 1 : 0,
      'rating': rating,
      'dietary_info': dietaryInfo,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      ingredients: map['ingredients'],
      instructions: map['instructions'],
      cuisine: map['cuisine'],
      mealType: map['meal_type'],
      prepTime: map['prep_time'],
      cookTime: map['cook_time'],
      servings: map['servings'],
      imagePath: map['image_path'],
      userId: map['user_id'],
      isFavorite: map['is_favorite'] == 1,
      rating: map['rating']?.toDouble() ?? 0.0,
      dietaryInfo: map['dietary_info'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Recipe copyWith({
    int? id,
    String? title,
    String? description,
    String? ingredients,
    String? instructions,
    String? cuisine,
    String? mealType,
    int? prepTime,
    int? cookTime,
    int? servings,
    String? imagePath,
    int? userId,
    bool? isFavorite,
    double? rating,
    String? dietaryInfo,
    DateTime? createdAt,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      cuisine: cuisine ?? this.cuisine,
      mealType: mealType ?? this.mealType,
      prepTime: prepTime ?? this.prepTime,
      cookTime: cookTime ?? this.cookTime,
      servings: servings ?? this.servings,
      imagePath: imagePath ?? this.imagePath,
      userId: userId ?? this.userId,
      isFavorite: isFavorite ?? this.isFavorite,
      rating: rating ?? this.rating,
      dietaryInfo: dietaryInfo ?? this.dietaryInfo,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}