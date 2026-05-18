import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'recipes_screen.dart';
import '../providers/app_state.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppState>(context);
    final expiring = app.expiringItems();
    final expired = app.expiredItems();

    final avgTime = app.recipes.isEmpty
        ? 0
        : app.recipes.map((e) => e.preparationTime).reduce((a, b) => a + b) ~/
              app.recipes.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Statistiche')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          statCard('Ricette salvate', app.recipes.length.toString()),
          statCard('Prodotti in dispensa', app.pantry.length.toString()),
          statCard('Pasti pianificati', app.mealPlan.length.toString()),
          statCard('Elementi lista spesa', app.shoppingList.length.toString()),
          statCard('Tempo medio preparazione', '$avgTime min'),
          statCard('Prodotti vicini alla scadenza', expiring.length.toString()),
          statCard('Prodotti scaduti', expired.length.toString()),

          const SizedBox(height: 16),
          const Text(
            'Prodotti in scadenza',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          ...expiring.map(
            (item) => ListTile(
              leading: const Icon(Icons.warning, color: Colors.orange),
              title: Text(item.name),
              subtitle: Text('${item.quantity} ${item.unit}'),
            ),
          ),

          Card(
            color: Colors.red.shade50,
            child: ListTile(
              leading: const Icon(Icons.favorite, color: Colors.red),
              title: const Text(
                'Ricette preferite',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${app.favoriteRecipes().length} ricette salvate come preferite',
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RecipesScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget statCard(String title, String value) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
