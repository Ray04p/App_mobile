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
      version: 10, 
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
    // Ricrea tutto da zero eliminando le tabelle vecchie
    //await db.execute('DROP TABLE IF EXISTS recipe_ingredients');
    //await db.execute('DROP TABLE IF EXISTS recipes');
    //await _createDB(db, newVersion);
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
    // Lista delle ricette hardcoded
    final defaultRecipes = [
      {
        'name': 'Pasta al pomodoro',
        'description': 'Cuocere la pasta in abbondante acqua salata. In parallelo soffriggere aglio in olio, aggiungere la passata di pomodoro e cuocere 10 minuti. Scolare la pasta e mantecare con il sugo.',
        'category': 'Primo',
        'preparationTime': 20,
        'difficulty': 'Facile',
        'portions': 2,
        'notes': 'Aggiungere basilico fresco a fine cottura.',
        'imagePath': null,
        'isRecommended': 1,
        'isFavorite': 0,
      },
      {
        'name': 'Insalata mista',
        'description': 'Lavare e tagliare le verdure. Condire con olio, sale e aceto.',
        'category': 'Contorno',
        'preparationTime': 10,
        'difficulty': 'Facile',
        'portions': 2,
        'notes': '',
        'imagePath': null,
        'isRecommended': 1,
        'isFavorite': 0,
      },
      {
        'name': 'Pollo alla griglia',
        'description': 'Marinare il petto di pollo con olio, limone, sale e pepe per 30 minuti. Cuocere sulla piastra calda 6-7 minuti per lato.',
        'category': 'Secondo',
        'preparationTime': 45,
        'difficulty': 'Facile',
        'portions': 2,
        'notes': 'Servire con spicchi di limone.',
        'imagePath': null,
        'isRecommended': 1,
        'isFavorite': 0,
      },
    ];

    final defaultIngredients = {
      'Pasta al pomodoro': [
        {'name': 'Pasta', 'quantity': 320.0, 'unit': 'g'},
        {'name': 'Passata di pomodoro', 'quantity': 400.0, 'unit': 'g'},
        {'name': 'Aglio', 'quantity': 2.0, 'unit': 'pz'},
        {'name': 'Olio', 'quantity': 3.0, 'unit': 'cucchiaio'},
      ],
      'Insalata mista': [
        {'name': 'Lattuga', 'quantity': 1.0, 'unit': 'pz'},
        {'name': 'Pomodori', 'quantity': 2.0, 'unit': 'pz'},
        {'name': 'Olio', 'quantity': 2.0, 'unit': 'cucchiaio'},
      ],
      'Pollo alla griglia': [
        {'name': 'Petto di pollo', 'quantity': 400.0, 'unit': 'g'},
        {'name': 'Limone', 'quantity': 1.0, 'unit': 'pz'},
        {'name': 'Olio', 'quantity': 2.0, 'unit': 'cucchiaio'},
      ],
    };

    for (final recipe in defaultRecipes) {
      // Inserisce la ricetta e ottiene l'id generato
      final recipeId = await db.insert('recipes', recipe);

      // Inserisce gli ingredienti associati
      final ingredients = defaultIngredients[recipe['name']] ?? [];
      for (final ingredient in ingredients) {
        await db.insert('recipe_ingredients', {
          'recipeId': recipeId,
          'name': ingredient['name'],
          'quantity': ingredient['quantity'],
          'unit': ingredient['unit'],
        });
      }
    }
  }
}