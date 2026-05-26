class RecipeIngredient {
  final int? id;
  final int? recipeId;
  final String name;
  final double quantity;
  final String unit;

  RecipeIngredient({
    this.id,
    this.recipeId,
    required this.name,
    required this.quantity,
    required this.unit,
  });

  String get displayText {

    String formattedQuantity = quantity == quantity.truncateToDouble()
        ? quantity.toInt().toString()
        : quantity.toString();

    if (quantity <= 0) {
      return '$name $unit'.trim();
    }

    return '$formattedQuantity $unit $name'.trim();
  }

  // Converte una riga del database in un oggetto Dart
  factory RecipeIngredient.fromMap(Map<String, dynamic> map) {
    return RecipeIngredient(
      id: map['id'],
      recipeId: map['recipeId'],
      name: map['name'],
      quantity: (map['quantity'] as num).toDouble(),
      unit: map['unit'],
    );
  }

  // Converte l'oggetto Dart in una Mappa per il database
  Map<String, dynamic> toMap(int attachedRecipeId) {
    return {
      if (id != null) 'id': id,
      'recipeId': attachedRecipeId,
      'name': name.trim(),
      'quantity': quantity,
      'unit': unit.trim(),
    };
  }
}