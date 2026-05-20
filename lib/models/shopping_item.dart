class ShoppingItem {
  final String id;
  String name;
  bool purchased;

  ShoppingItem({
    required this.id,
    required this.name,
    this.purchased = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'purchased': purchased,
      };

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      id: json['id'],
      name: json['name'],
      purchased: json['purchased'] ?? false,
    );
  }
}