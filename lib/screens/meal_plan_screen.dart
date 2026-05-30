import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

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
  late DateTime currentWeekStart;

  final days = ['Lunedì','Martedì','Mercoledì','Giovedì','Venerdì','Sabato','Domenica'];
  final meals = ['Colazione','Pranzo','Cena','Spuntino'];

  @override
  void initState() {
    super.initState();
    currentWeekStart = _getMonday(DateTime.now());
  }

  DateTime _getMonday(DateTime date) =>
      date.subtract(Duration(days: date.weekday - 1));

  String _formatWeekStart(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _weekLabel(DateTime monday) {
    final sunday = monday.add(const Duration(days: 6));
    final fmt = DateFormat('d MMM', 'it');
    final fmtYear = DateFormat('d MMM yyyy', 'it');
    return '${fmt.format(monday)} - ${fmtYear.format(sunday)}';
  }

  void _previousWeek() =>
      setState(() => currentWeekStart = currentWeekStart.subtract(const Duration(days: 7)));

  void _nextWeek() =>
      setState(() => currentWeekStart = currentWeekStart.add(const Duration(days: 7)));

  void _goToCurrentWeek() =>
      setState(() => currentWeekStart = _getMonday(DateTime.now()));

  void _doAddMeal(AppState app) {
    app.addMealPlanItem(
      MealPlanItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        weekStart: _formatWeekStart(currentWeekStart),
        day: selectedDay,
        mealType: selectedMeal,
        recipeId: selectedRecipeId!,
      ),
    );
  }

  void addMeal(AppState app) {
    if (selectedRecipeId == null) return;

    final isDuplicate = app.mealPlan.any(
      (item) =>
          item.weekStart == _formatWeekStart(currentWeekStart) &&
          item.day == selectedDay &&
          item.mealType == selectedMeal &&
          item.recipeId == selectedRecipeId,
    );

    if (isDuplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Questa ricetta è già presente in questo pasto.')),
      );
      return;
    }

    final recipe = app.recipeById(selectedRecipeId!);
    if (recipe != null) {
      final missingIngredients = recipe.ingredients.where((ingredient) {
        return !app.pantry.any(
          (item) => item.name.toLowerCase().trim() == ingredient.name.toLowerCase().trim(),
        );
      }).toList();

      if (missingIngredients.isNotEmpty) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange),
                SizedBox(width: 8),
                Text('Ingredienti mancanti'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Non hai in dispensa:'),
                const SizedBox(height: 10),
                ...missingIngredients.map(
                  (ing) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, size: 8, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(ing.displayText),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annulla', style: TextStyle(color: Colors.grey)),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.shopping_cart, size: 18),
                label: const Text('Aggiungi alla lista spesa'),
                onPressed: () {
                  for (final ing in missingIngredients) {
                    app.addShoppingItem(ing.name, quantity: ing.quantity, unit: ing.unit);
                  }
                  Navigator.pop(ctx);
                  _doAddMeal(app);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ingredienti aggiunti alla lista spesa.')),
                  );
                },
              ),
              ElevatedButton(
                onPressed: () { Navigator.pop(ctx); _doAddMeal(app); },
                child: const Text('Aggiungi comunque'),
              ),
            ],
          ),
        );
        return;
      }
    }

    _doAddMeal(app);
  }


  void editMeal(AppState app, MealPlanItem item) {
    String tempDay = item.day;
    String tempMeal = item.mealType;
    String? tempRecipeId = item.recipeId;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Modifica pasto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: tempDay,
              decoration: const InputDecoration(labelText: 'Giorno'),
              items: days
                  .map((day) => DropdownMenuItem(value: day, child: Text(day)))
                  .toList(),
              onChanged: (value) => tempDay = value!,
            ),
            DropdownButtonFormField<String>(
              initialValue: tempMeal,
              decoration: const InputDecoration(labelText: 'Pasto'),
              items: meals
                  .map((meal) => DropdownMenuItem(value: meal, child: Text(meal)))
                  .toList(),
              onChanged: (value) => tempMeal = value!,
            ),
            DropdownButtonFormField<String>(
              initialValue: tempRecipeId,
              decoration: const InputDecoration(labelText: 'Ricetta'),
              items: app.recipes
                  .map((r) => DropdownMenuItem(
                        value: r.id.toString(),
                        child: Text(r.name),
                      ))
                  .toList(),
              onChanged: (value) => tempRecipeId = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              if (tempRecipeId == null) return;

              app.updateMealPlanItem(
                MealPlanItem(
                  id: item.id,
                  weekStart: item.weekStart,
                  day: tempDay,
                  mealType: tempMeal,
                  recipeId: tempRecipeId!,
                ),
              );

              Navigator.pop(ctx);
            },
            child: const Text('Salva'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppState>(context);

    if (selectedRecipeId != null &&
        !app.recipes.any((r) => r.id.toString() == selectedRecipeId)) {
      selectedRecipeId = null;
    }

    final currentWeekKey = _formatWeekStart(currentWeekStart);
    final weekMealPlan = app.mealPlan.where((item) => item.weekStart == currentWeekKey).toList();
    final isCurrentWeek = currentWeekKey == _formatWeekStart(_getMonday(DateTime.now()));

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

          // Navigazione settimane
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: const Icon(Icons.chevron_left), onPressed: _previousWeek),
                Column(
                  children: [
                    Text(
                      _weekLabel(currentWeekStart),
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.green[900]),
                    ),
                    if (!isCurrentWeek) ...[
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: _goToCurrentWeek,
                        child: Text(
                          'Torna alla settimana corrente',
                          style: TextStyle(fontSize: 12, color: Colors.green[700], decoration: TextDecoration.underline),
                        ),
                      ),
                    ],
                  ],
                ),
                IconButton(icon: const Icon(Icons.chevron_right), onPressed: _nextWeek),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Form aggiunta pasto
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aggiungi un pasto',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green[900], fontFamily: 'serif'),
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  initialValue: selectedDay,
                  decoration: InputDecoration(labelText: 'Giorno', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
                  items: days.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (value) => setState(() => selectedDay = value!),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: selectedMeal,
                  decoration: InputDecoration(labelText: 'Pasto', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
                  items: meals.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (value) => setState(() => selectedMeal = value!),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: selectedRecipeId,
                  decoration: InputDecoration(labelText: 'Ricetta', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
                  items: app.recipes.map((r) => DropdownMenuItem(value: r.id.toString(), child: Text(r.name))).toList(),
                  onChanged: (value) => setState(() => selectedRecipeId = value),
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
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green[900], fontFamily: 'serif'),
          ),
          const SizedBox(height: 18),

          ...days.map((day) {
            final dayMeals = weekMealPlan.where((item) => item.day == day).toList();

            return Card(
              margin: const EdgeInsets.only(bottom: 26),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                title: Text(
                  day,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green[900], fontFamily: 'serif'),
                ),
                subtitle: Text('${dayMeals.length} pasti pianificati'),
                children: [
                  ...meals.map((mealType) {
                    final meal = dayMeals.where((m) => m.mealType == mealType);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(mealType, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange[800])),
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
                                decoration: BoxDecoration(color: const Color(0xFFF6F8F1), borderRadius: BorderRadius.circular(18)),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.green.shade100,
                                    child: Icon(Icons.restaurant, color: Colors.green[900]),
                                  ),
                                  title: Text(recipe?.name ?? 'Ricetta eliminata', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () => editMeal(app, item),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () => app.deleteMealPlanItem(item.id),
                                      ),
                                    ],
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