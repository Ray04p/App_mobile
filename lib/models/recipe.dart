import 'recipe_ingredient.dart';

class Recipe {
  int? id;
  String name;
  String description;
  String category;
  int preparationTime;
  String difficulty;
  int portions;
  List<RecipeIngredient> ingredients; 
  String notes;
  String? imagePath;
  bool isRecommended;
  bool isFavorite;

  Recipe({
    this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.preparationTime,
    required this.difficulty,
    required this.portions,
    required this.ingredients,
    this.notes = '',
    this.imagePath,
    this.isRecommended = false,
    this.isFavorite = false,
  });


  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'category': category,
      'preparationTime': preparationTime,
      'difficulty': difficulty,
      'portions': portions,
      // RIMOSSO IL CAMPO 'ingredients'
      'notes': notes,
      'imagePath': imagePath,
      'isRecommended': isRecommended ? 1 : 0,
      'isFavorite': isFavorite ? 1 : 0,
    };
  }

  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      category: map['category'],
      preparationTime: map['preparationTime'],
      difficulty: map['difficulty'],
      portions: map['portions'],
      ingredients: [], // Inizializzata vuota di default
      notes: map['notes'] ?? '',
      imagePath: map['imagePath'],
      isRecommended: map['isRecommended'] == 1,
      isFavorite: map['isFavorite'] == 1,
    );
  }
}