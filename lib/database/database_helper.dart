import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/recipe.dart';

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
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE recipes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        category TEXT NOT NULL,
        preparationTime INTEGER NOT NULL,
        difficulty TEXT NOT NULL,
        portions INTEGER NOT NULL,
        ingredients TEXT NOT NULL,
        notes TEXT
      )
    ''');

    await _insertDefaultRecipes(db);
  }

  Future<void> _insertDefaultRecipes(Database db) async {
    final defaultRecipes = [
      {
        'name': 'Spaghetti alla Carbonara',
        'description': 'Cuoci la pasta. Prepara una crema con uova e pecorino. Rosola il guanciale e unisci tutto fuori dal fuoco.',
        'category': 'Primo',
        'preparationTime': 25,
        'difficulty': 'Media',
        'portions': 2,
        'ingredients': 'spaghetti,uova,pecorino,guanciale,pepe',
        'notes': 'Mescolare lontano dal fuoco per evitare effetto frittata.',
        'isRecommended': 1,
        'isFavorite': 1,
      },
      {
        'name': 'Pancakes',
        'description': 'Mescola farina, latte, uova e zucchero. Cuoci piccole porzioni di impasto in padella.',
        'category': 'Colazione',
        'preparationTime': 15,
        'difficulty': 'Facile',
        'portions': 4,
        'ingredients': 'farina,latte,uova,zucchero,lievito',
        'notes': 'Servire con frutta o sciroppo.',
        'isRecommended': 1,
        'isFavorite': 1,
      },
      {
        'name': 'Insalata di pollo',
        'description': 'Griglia il pollo, taglialo a strisce e uniscilo a insalata, pomodorini e mais.',
        'category': 'Secondo',
        'preparationTime': 20,
        'difficulty': 'Facile',
        'portions': 2,
        'ingredients': 'pollo,insalata,pomodorini,mais,olio',
        'notes': 'Ottima per un pranzo leggero.',
        'isRecommended': 1,
        'isFavorite': 0,
      },
      {
        'name': 'Pasta al pesto',
        'description': 'Cuoci la pasta e condiscila con pesto, parmigiano e un filo d’olio.',
        'category': 'Primo',
        'preparationTime': 15,
        'difficulty': 'Facile',
        'portions': 2,
        'ingredients': 'pasta,pesto,parmigiano,olio',
        'notes': 'Aggiungere patate o fagiolini per una versione più ricca.',
        'isRecommended': 1,
        'isFavorite': 0,
      },
    ];

    for (final recipe in defaultRecipes) {
      await db.insert('recipes', recipe);
    }
  }

  Future<int> insertRecipe(Recipe recipe) async {
    final db = await instance.database;
    return await db.insert('recipes', recipe.toMap());
  }

  Future<List<Recipe>> getRecipes() async {
    final db = await instance.database;

    final result = await db.query(
      'recipes',
      orderBy: 'name ASC',
    );

    return result.map((map) => Recipe.fromMap(map)).toList();
  }

  Future<int> updateRecipe(Recipe recipe) async {
    final db = await instance.database;

    return await db.update(
      'recipes',
      recipe.toMap(),
      where: 'id = ?',
      whereArgs: [recipe.id],
    );
  }

  Future<int> deleteRecipe(int id) async {
    final db = await instance.database;

    return await db.delete(
      'recipes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}