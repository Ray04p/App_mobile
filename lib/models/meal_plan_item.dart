class MealPlanItem {
  final String id;
  String day;
  String mealType;
  String recipeId;

  MealPlanItem({
    required this.id,
    required this.day,
    required this.mealType,
    required this.recipeId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'day': day,
        'mealType': mealType,
        'recipeId': recipeId,
      };

  factory MealPlanItem.fromJson(Map<String, dynamic> json) {
    return MealPlanItem(
      id: json['id'],
      day: json['day'],
      mealType: json['mealType'],
      recipeId: json['recipeId'],
    );
  }
}