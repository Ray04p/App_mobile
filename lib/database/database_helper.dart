import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/recipe.dart';
import '../models/recipe_ingredient.dart'; 

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('mealmate.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    
    return await openDatabase(
      path,
      version: 7, 
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onConfigure: _onConfigure, // Necessario per abilitare le Foreign Keys in SQLite
    );
  }

  
  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Creazione Tabella Ricette 
    await db.execute('''
      CREATE TABLE recipes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        category TEXT NOT NULL,
        preparationTime INTEGER NOT NULL,
        difficulty TEXT NOT NULL,
        portions INTEGER NOT NULL,
        notes TEXT,
        imagePath TEXT,
        isRecommended INTEGER NOT NULL DEFAULT 0,
        isFavorite INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // 2. Creazione Tabella Ingredienti 
    await db.execute('''
      CREATE TABLE recipe_ingredients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recipeId INTEGER NOT NULL,
        name TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        FOREIGN KEY (recipeId) REFERENCES recipes (id) ON DELETE CASCADE
      )
    ''');

    await _insertDefaultRecipes(db);
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Gestione degli aggiornamenti
    if (oldVersion < 6) {
      
    }
  }

  // INSERIMENTO
  Future<int> insertRecipe(Recipe recipe) async {
    final db = await instance.database;
    
    // Step 1: Salva la ricetta
    final recipeId = await db.insert('recipes', recipe.toMap());
    
    // Step 2: Salva ogni ingrediente associandolo a quell'ID
    for (final ingredient in recipe.ingredients) {
      await db.insert('recipe_ingredients', ingredient.toMap(recipeId));
    }
    
    return recipeId;
  }

  // LETTURA: L'operazione di ricongiungimento
  Future<List<Recipe>> getRecipes() async {
    final db = await instance.database;

    final recipeMaps = await db.query('recipes', orderBy: 'name ASC');
    List<Recipe> recipes = [];

    for (final map in recipeMaps) {
      
      Recipe recipe = Recipe.fromMap(map);
      
      final ingredientMaps = await db.query(
        'recipe_ingredients',
        where: 'recipeId = ?',
        whereArgs: [recipe.id],
      );
      
      recipe.ingredients = ingredientMaps
          .map((ingMap) => RecipeIngredient.fromMap(ingMap))
          .toList();
          
      recipes.add(recipe);
    }

    return recipes;
  }

  
  Future<int> updateRecipe(Recipe recipe) async {
    final db = await instance.database;

    final result = await db.update(
      'recipes',
      recipe.toMap(),
      where: 'id = ?',
      whereArgs: [recipe.id],
    );

    await db.delete('recipe_ingredients', where: 'recipeId = ?', whereArgs: [recipe.id]);
    
    for (final ingredient in recipe.ingredients) {
      await db.insert('recipe_ingredients', ingredient.toMap(recipe.id!));
    }

    return result;
  }

  // ELIMINAZIONE
  Future<int> deleteRecipe(int id) async {
    final db = await instance.database;
    
    return await db.delete(
      'recipes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

Future<void> _insertDefaultRecipes(Database db) async {
    
    
  }
}