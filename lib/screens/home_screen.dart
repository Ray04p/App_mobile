import 'package:flutter/material.dart';
import 'main_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      ['Ricette', Icons.restaurant_menu, 0],
      ['Dispensa', Icons.kitchen, 1],
      ['Meal Plan', Icons.calendar_month, 2],
      ['Lista Spesa', Icons.shopping_cart, 3],
      ['Statistiche', Icons.bar_chart, 4],
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
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MainScreen(
                        initialIndex: items[index][2] as int,
                      ),
                    ),
                  );
                },
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