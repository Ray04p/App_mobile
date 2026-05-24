class RecipeIngredient {
  String name;
  double quantity;
  String unit;

  RecipeIngredient({
    required this.name,
    required this.quantity,
    required this.unit,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'unit': unit,
    };
  }

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      name: json['name'],
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'],
    );
  }

  String get displayText {
    final quantityText = quantity % 1 == 0
        ? quantity.toInt().toString()
        : quantity.toString();

    return '$quantityText $unit $name';
  }
}