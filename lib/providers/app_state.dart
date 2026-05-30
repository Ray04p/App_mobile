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

  // --- 1. NUOVO STATO DEL FILTRO ---
  bool _showOnlyAvailable = false;
  bool get showOnlyAvailable => _showOnlyAvailable;
  // ---------------------------------

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
  // MOTORE DI FILTRAGGIO (NUOVO)
  // -------------------------

  void toggleAvailableFilter(bool value) {
    _showOnlyAvailable = value;
    notifyListeners();
  }

  List<Recipe> get filteredRecipes {
    // Se l'interruttore è spento, mostriamo tutto
    if (!_showOnlyAvailable) {
      return recipes;
    }

    return recipes.where((recipe) {
      // Se non ha ingredienti, la mostriamo a prescindere
      if (recipe.ingredients.isEmpty) return true;

      // Tutti gli ingredienti della ricetta devono superare il test matematico
      return recipe.ingredients.every((recipeIng) {
        
        // 1. Troviamo gli elementi in dispensa col nome corrispondente
        final matchingPantryItems = pantry.where((pantryItem) => 
          pantryItem.name.toLowerCase().trim() == recipeIng.name.toLowerCase().trim()
        );

        // Se non ne abbiamo affatto, la ricetta fallisce immediatamente
        if (matchingPantryItems.isEmpty) return false;

        // 2. Sommiamo le quantità (castiamo a num.toDouble() per sicurezza
        // nel caso il tuo PantryItem abbia quantity come int invece che double)
        final totalAvailable = matchingPantryItems.fold<double>(
          0.0, 
          (sum, item) => sum + (item.quantity as num).toDouble()
        );

        // 3. Il verdetto: ne abbiamo a sufficienza?
        return totalAvailable >= recipeIng.quantity;
      });
    }).toList();
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

    saveData(); 
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

  void addShoppingItem(String name, {double quantity = 0, String unit = ''}) {
    final normalizedName = name.toLowerCase().trim();
    final normalizedUnit = unit.toLowerCase().trim();
    final existingIndex = shoppingList.indexWhere(
      (item) =>
          item.name.toLowerCase().trim() == normalizedName &&
          item.unit.toLowerCase().trim() == normalizedUnit,
    );

    if (existingIndex != -1) {
      if (quantity > 0) {
        final existing = shoppingList[existingIndex];
        shoppingList[existingIndex] = ShoppingItem(
          id: existing.id,
          name: existing.name,
          quantity: existing.quantity + quantity,
          unit: existing.unit,
          purchased: existing.purchased,
        );
      }
    } else {
      shoppingList.add(
        ShoppingItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name.trim(),
          quantity: quantity,
          unit: unit.trim(),
        ),
      );
    }

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

  void selectAllShoppingItems() {
    for (final item in shoppingList) {
      item.purchased = true;
    }

    saveData();
    notifyListeners();
  }

  void deleteSelectedShoppingItems() {
    shoppingList.removeWhere((item) => item.purchased);

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

        if (pantryNames.contains(ingredientName)) continue;

        final ingredientUnit = ingredient.unit.toLowerCase().trim();
        final existingIndex = shoppingList.indexWhere(
          (item) =>
              item.name.toLowerCase().trim() == ingredientName &&
              item.unit.toLowerCase().trim() == ingredientUnit,
        );

        if (existingIndex != -1) {
          final existing = shoppingList[existingIndex];
          shoppingList[existingIndex] = ShoppingItem(
            id: existing.id,
            name: existing.name,
            quantity: existing.quantity + ingredient.quantity,
            unit: existing.unit,
            purchased: existing.purchased,
          );
        } else {
          shoppingList.add(
            ShoppingItem(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              name: ingredient.name,
              quantity: ingredient.quantity,
              unit: ingredient.unit,
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
    final suggested = recipes.where((recipe) {
      return recipe.isRecommended ||
          recipe.ingredients.any((ingredient) {
            return pantry.any(
              (item) =>
                  item.name.toLowerCase().trim() ==
                  ingredient.name.toLowerCase().trim(),
            );
          });
    }).toList();

    // Le ricette hardcoded (isRecommended) hanno priorità,
    // poi le ricette con ingredienti in dispensa
    suggested.sort((a, b) {
      if (a.isRecommended && !b.isRecommended) return -1;
      if (!a.isRecommended && b.isRecommended) return 1;
      return 0;
    });

    // Massimo 5 suggerimenti
    return suggested.take(5).toList();
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