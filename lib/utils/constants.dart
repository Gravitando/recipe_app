import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryColor = Color(0xFFFF6B6B);
  static const Color accentColor = Color(0xFFFFA500);
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF636E72);
}

class AppStrings {
  static const String appName = 'Recipe App';
  static const String welcome = 'Welcome to Recipe App';
  static const String welcomeSubtitle = 'Discover delicious recipes and plan your meals';
  static const String login = 'Login';
  static const String signup = 'Sign Up';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String fullName = 'Full Name';
  static const String forgotPassword = 'Forgot Password?';
  static const String dontHaveAccount = "Don't have an account?";
  static const String alreadyHaveAccount = "Already have an account?";
}

class AppConstants {
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 12.0;
  static const double cardElevation = 4.0;

  static const List<String> cuisineTypes = [
    'All',
    'Italian',
    'Chinese',
    'Mexican',
    'Indian',
    'Japanese',
    'Thai',
    'Mediterranean',
    'American',
  ];

  static const List<String> mealTypes = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snack',
    'Dessert',
  ];

  static const List<String> dietaryNeeds = [
    'Vegetarian',
    'Vegan',
    'Gluten-Free',
    'Dairy-Free',
    'Keto',
    'Low-Carb',
    'High-Protein',
  ];
}