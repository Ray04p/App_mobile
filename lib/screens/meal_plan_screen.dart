import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/meal_plan_item.dart';
import '../providers/app_state.dart';

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  String selectedDay = 'Lunedì';
  String selectedMeal = 'Pranzo';
  String? selectedRecipeId;

  final days = [
    'Lunedì',
    'Martedì',
    'Mercoledì',
    'Giovedì',
    'Venerdì',
    'Sabato',
    'Domenica',
  ];

  final meals = [
    'Colazione',
    'Pranzo',
    'Cena',
    'Spuntino',
  ];

  void addMeal(AppState app) {
    if (selectedRecipeId == null) return;

    app.addMealPlanItem(
      MealPlanItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        day: selectedDay,
        mealType: selectedMeal,
        recipeId: selectedRecipeId!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppState>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF2),

      appBar: AppBar(
        title: const Text(
          'Meal Plan',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 29, 102, 34),
            fontFamily: 'serif',
          ),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                ),
              ],
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aggiungi un pasto',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[900],
                    fontFamily: 'serif',
                  ),
                ),

                const SizedBox(height: 18),

                DropdownButtonFormField<String>(
                  initialValue: selectedDay,
                  decoration: InputDecoration(
                    labelText: 'Giorno',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  items: days
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(e),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedDay = value!;
                    });
                  },
                ),

                const SizedBox(height: 14),

                DropdownButtonFormField<String>(
                  initialValue: selectedMeal,
                  decoration: InputDecoration(
                    labelText: 'Pasto',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  items: meals
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(e),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedMeal = value!;
                    });
                  },
                ),

                const SizedBox(height: 14),

                DropdownButtonFormField<String>(
                  initialValue: selectedRecipeId,
                  decoration: InputDecoration(
                    labelText: 'Ricetta',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  items: app.recipes
                      .map(
                        (r) => DropdownMenuItem(
                          value: r.id.toString(),
                          child: Text(r.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedRecipeId = value;
                    });
                  },
                ),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => addMeal(app),
                    icon: const Icon(Icons.add),
                    label: const Text('Aggiungi al piano'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          Text(
            'La tua settimana',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.green[900],
              fontFamily: 'serif',
            ),
          ),

          const SizedBox(height: 18),

          
          ...days.map((day) {
            final dayMeals = app.mealPlan.where((item) => item.day == day).toList();

            return Card(
              margin: const EdgeInsets.only(bottom: 26),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                title: Text(
                  day,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[900],
                    fontFamily: 'serif',
                  ),
                ),
                subtitle: Text(
                  '${dayMeals.length} pasti pianificati',
                ),
                children: [
                  ...meals.map((mealType) {
                    final meal = dayMeals.where((m) => m.mealType == mealType);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mealType,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[800],
                            ),
                          ),
                          const SizedBox(height: 8),

                          if (meal.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 202, 227, 202),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Text('Nessun pasto pianificato'),
                            )
                          else
                            ...meal.map((item) {
                              final recipe = app.recipeById(item.recipeId);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF6F8F1),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.green.shade100,
                                    child: Icon(
                                      Icons.restaurant,
                                      color: Colors.green[900],
                                    ),
                                  ),
                                  title: Text(
                                    recipe?.name ?? 'Ricetta eliminata',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () {
                                      app.deleteMealPlanItem(item.id);
                                    },
                                  ),
                                ),
                              );
                            }),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}