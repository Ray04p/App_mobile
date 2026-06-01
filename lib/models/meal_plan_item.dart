class MealPlanItem {
  final String id;
  String weekStart;
  String day;
  String mealType;
  String recipeId;

  MealPlanItem({
    required this.id,
    required this.weekStart, // Data del lunedì della settimana in formato 'yyyy-MM-dd'
    required this.day,
    required this.mealType,
    required this.recipeId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'weekStart': weekStart,
        'day': day,
        'mealType': mealType,
        'recipeId': recipeId,
      };

  factory MealPlanItem.fromJson(Map<String, dynamic> json) {
    return MealPlanItem(
      id: json['id'],
      // Compatibilità con dati vecchi senza weekStart
      weekStart: json['weekStart'] ?? currentWeekStart(),
      day: json['day'],
      mealType: json['mealType'],
      recipeId: json['recipeId'],
    );
  }

   // Calcola il lunedì della settimana corrente
  static String currentWeekStart() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
  }
}