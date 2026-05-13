import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final controller = TextEditingController();

  void addItem(AppState app) {
    if (controller.text.trim().isEmpty) return;
    app.addShoppingItem(controller.text.trim());
    controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Lista Spesa')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: 'Nuovo elemento',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => addItem(app),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ElevatedButton.icon(
              onPressed: app.generateShoppingListFromMealPlan,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Genera dal meal plan'),
            ),
          ),
          Expanded(
            child: app.shoppingList.isEmpty
                ? const Center(child: Text('Lista vuota'))
                : ListView.builder(
                    itemCount: app.shoppingList.length,
                    itemBuilder: (context, index) {
                      final item = app.shoppingList[index];

                      return CheckboxListTile(
                        title: Text(
                          item.name,
                          style: TextStyle(
                            decoration: item.purchased
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        value: item.purchased,
                        onChanged: (_) => app.toggleShoppingItem(item.id),
                        secondary: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => app.deleteShoppingItem(item.id),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}