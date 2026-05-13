import 'package:flutter/material.dart';
import 'recipes_screen.dart';
import 'pantry_screen.dart';
import 'meal_plan_screen.dart';
import 'shopping_list.dart';
import 'stats.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void open(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      ['Ricette', Icons.restaurant_menu, const RecipesScreen()],
      ['Dispensa', Icons.kitchen, const PantryScreen()],
      ['Meal Plan', Icons.calendar_month, const MealPlanScreen()],
      ['Lista Spesa', Icons.shopping_cart, const ShoppingListScreen()],
      ['Statistiche', Icons.bar_chart, const StatsScreen()],
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('MealMate')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
          ),
          itemBuilder: (context, index) {
            return Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => open(context, items[index][2] as Widget),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(items[index][1] as IconData, size: 42),
                    const SizedBox(height: 10),
                    Text(
                      items[index][0] as String,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}