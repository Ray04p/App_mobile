import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/database_helper.dart';
import '../models/recipe.dart';
import '../models/pantry_item.dart';
import '../models/meal_plan_item.dart';
import '../models/shopping_item.dart';

class AppState extends ChangeNotifier {
  List<Recipe> recipes = [];
  List<PantryItem> pantry = [];
  List<MealPlanItem> mealPlan = [];
  List<ShoppingItem> shoppingList = [];

  AppState() {
    loadData();
    loadRecipesFromDatabase();
  }

  // -------------------------
  // CARICAMENTO DATI
  // -------------------------

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final pantryString = prefs.getString('pantry');
    final mealPlanString = prefs.getString('mealPlan');
    final shoppingString = prefs.getString('shoppingList');

    if (pantryString != null) {
      final List decoded = jsonDecode(pantryString);
      pantry = decoded.map((e) => PantryItem.fromJson(e)).toList();
    }

    if (mealPlanString != null) {
      final List decoded = jsonDecode(mealPlanString);
      mealPlan = decoded.map((e) => MealPlanItem.fromJson(e)).toList();
    }

    if (shoppingString != null) {
      final List decoded = jsonDecode(shoppingString);
      shoppingList = decoded.map((e) => ShoppingItem.fromJson(e)).toList();
    }

    notifyListeners();
  }

  Future<void> loadRecipesFromDatabase() async {
    recipes = await DatabaseHelper.instance.getRecipes();
    notifyListeners();
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'pantry',
      jsonEncode(pantry.map((e) => e.toJson()).toList()),
    );

    await prefs.setString(
      'mealPlan',
      jsonEncode(mealPlan.map((e) => e.toJson()).toList()),
    );

    await prefs.setString(
      'shoppingList',
      jsonEncode(shoppingList.map((e) => e.toJson()).toList()),
    );
  }

  // -------------------------
  // RICETTE - SQLITE
  // -------------------------

  Future<void> addRecipe(Recipe recipe) async {
    await DatabaseHelper.instance.insertRecipe(recipe);
    await loadRecipesFromDatabase();
  }

  Future<void> updateRecipe(Recipe recipe) async {
    await DatabaseHelper.instance.updateRecipe(recipe);
    await loadRecipesFromDatabase();
  }

  Future<void> deleteRecipe(int id) async {
    await DatabaseHelper.instance.deleteRecipe(id);

    mealPlan.removeWhere((item) => item.recipeId == id.toString());

    await saveData();
    await loadRecipesFromDatabase();
  }

  Recipe? recipeById(String id) {
    try {
      return recipes.firstWhere((recipe) => recipe.id.toString() == id);
    } catch (_) {
      return null;
    }
  }

  // -------------------------
  // DISPENSA
  // -------------------------

  void addPantryItem(PantryItem item) {
    pantry.add(item);
    saveData();
    notifyListeners();
  }

  void updatePantryItem(PantryItem item) {
    final index = pantry.indexWhere((e) => e.id == item.id);

    if (index != -1) {
      pantry[index] = item;
      saveData();
      notifyListeners();
    }
  }

  void deletePantryItem(String id) {
    pantry.removeWhere((item) => item.id == id);
    saveData();
    notifyListeners();
  }

  void reorderPantryItems(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final item = pantry.removeAt(oldIndex);
    pantry.insert(newIndex, item);

    saveData(); // Fondamentale per salvare il nuovo ordine in SharedPreferences!
    notifyListeners();
  }

  // -------------------------
  // MEAL PLAN
  // -------------------------

  void addMealPlanItem(MealPlanItem item) {
    mealPlan.add(item);
    saveData();
    notifyListeners();
  }

  void deleteMealPlanItem(String id) {
    mealPlan.removeWhere((item) => item.id == id);
    saveData();
    notifyListeners();
  }

  void reorderMealPlanItems(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = mealPlan.removeAt(oldIndex);
    mealPlan.insert(newIndex, item);
    notifyListeners();
  }
  
  // ------------------------
  // RICETTE PREFERITE
  // ------------------------
  Future<void> toggleFavoriteRecipe(Recipe recipe) async {
    recipe.isFavorite = !recipe.isFavorite;
    await DatabaseHelper.instance.updateRecipe(recipe);
    await loadRecipesFromDatabase();
  }

  List<Recipe> favoriteRecipes() {
    return recipes.where((recipe) => recipe.isFavorite).toList();
  }

  // -------------------------
  // LISTA SPESA
  // -------------------------

  void addShoppingItem(String name) {
    shoppingList.add(
      ShoppingItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
      ),
    );

    saveData();
    notifyListeners();
  }

  void toggleShoppingItem(String id) {
    final index = shoppingList.indexWhere((item) => item.id == id);

    if (index != -1) {
      shoppingList[index].purchased = !shoppingList[index].purchased;
      saveData();
      notifyListeners();
    }
  }

  void deleteShoppingItem(String id) {
    shoppingList.removeWhere((item) => item.id == id);
    saveData();
    notifyListeners();
  }

  void generateShoppingListFromMealPlan() {
    final pantryNames = pantry
        .map((item) => item.name.toLowerCase().trim())
        .toList();

    for (final planItem in mealPlan) {
      final recipe = recipeById(planItem.recipeId);

      if (recipe == null) continue;

      for (final ingredient in recipe.ingredients) {
        final ingredientName = ingredient.name.toLowerCase().trim();

        final alreadyInPantry = pantryNames.contains(ingredientName);

        final alreadyInShoppingList = shoppingList.any(
          (item) => item.name.toLowerCase().trim() == ingredientName,
        );

        if (!alreadyInPantry && !alreadyInShoppingList) {
          shoppingList.add(
            ShoppingItem(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              name: ingredient.displayText,
            ),
          );
        }
      }
    }

    saveData();
    notifyListeners();
  }

  // -------------------------
  // FEATURE AVANZATE / STATISTICHE
  // -------------------------

  List<Recipe> suggestedRecipes() {
    return recipes.where((recipe) {
      return recipe.isRecommended ||
          recipe.ingredients.any((ingredient) {
            return pantry.any(
              (item) =>
                  item.name.toLowerCase().trim() ==
                  ingredient.name.toLowerCase().trim(),
            );
          });
    }).toList();
  }
  

  List<PantryItem> expiringItems() {
    return pantry.where((item) => item.isExpiringSoon).toList();
  }

  List<PantryItem> expiredItems() {
    return pantry.where((item) => item.isExpired).toList();
  }

  int get totalRecipes => recipes.length;

  int get totalPantryItems => pantry.length;

  int get totalPlannedMeals => mealPlan.length;

  int get totalShoppingItems => shoppingList.length;

  int get averagePreparationTime {
    if (recipes.isEmpty) return 0;

    final total = recipes
        .map((recipe) => recipe.preparationTime)
        .reduce((a, b) => a + b);

    return total ~/ recipes.length;
  }
}
