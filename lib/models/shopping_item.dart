class ShoppingItem {
  final String id;
  String name;
  double quantity;
  String unit;
  bool purchased;

  ShoppingItem({
    required this.id,
    required this.name,
    this.quantity = 0,
    this.unit = '',
    this.purchased = false,
  });

  String get displayText {
    if (quantity <= 0 && unit.isEmpty) return name;
    final qText = quantity % 1 == 0
        ? quantity.toInt().toString()
        : quantity.toString();
    if (unit.isEmpty) return '$qText $name';
    return '$qText $unit $name';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'quantity': quantity,
        'unit': unit,
        'purchased': purchased,
      };

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      id: json['id'],
      name: json['name'],
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      unit: json['unit'] ?? '',
      purchased: json['purchased'] ?? false,
    );
  }
}
