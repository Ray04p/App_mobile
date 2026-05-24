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

  final meals = ['Colazione', 'Pranzo', 'Cena', 'Spuntino'];

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
      appBar: AppBar(
        title: const Text('Piano Alimentare',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 29, 102, 34),
            fontFamily: 'serif'
          ),
        ),
      ),
      body: ReorderableListView(
        buildDefaultDragHandles: false,
        onReorder: (oldIndex, newIndex) {
          app.reorderMealPlanItems(oldIndex, newIndex);
        },

        header: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedDay,
                decoration: const InputDecoration(
                  labelText: 'Giorno',
                  border: OutlineInputBorder(),
                ),
                items: days
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) => setState(() => selectedDay = value!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedMeal,
                decoration: const InputDecoration(
                  labelText: 'Pasto',
                  border: OutlineInputBorder(),
                ),
                items: meals
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) => setState(() => selectedMeal = value!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedRecipeId,
                decoration: const InputDecoration(
                  labelText: 'Ricetta',
                  border: OutlineInputBorder(),
                ),
                items: app.recipes
                    .map(
                      (r) => DropdownMenuItem(
                        value: r.id.toString(),
                        child: Text(r.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => selectedRecipeId = value),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => addMeal(app),
                icon: const Icon(Icons.add),
                label: const Text('Aggiungi al piano'),
              ),
              const SizedBox(height: 24),
              const Text(
                'Pasti pianificati',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),

        //parte modificabile 
        children: [
          for (int i = 0; i < app.mealPlan.length; i++)
            Card(
              key: ValueKey(
                app.mealPlan[i].id,
              ), // La chiave univoca vitale per Flutter
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                title: Text(
                  '${app.mealPlan[i].day} - ${app.mealPlan[i].mealType}',
                ),
                subtitle: Text(
                  app.recipeById(app.mealPlan[i].recipeId)?.name ??
                      'Ricetta eliminata',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ReorderableDragStartListener(
                      index: i, // L'indice esatto della riga
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Icon(Icons.drag_handle, color: Colors.grey),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () =>
                          app.deleteMealPlanItem(app.mealPlan[i].id),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
