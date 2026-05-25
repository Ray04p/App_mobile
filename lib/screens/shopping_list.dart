import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final nameController = TextEditingController();
  final quantityController = TextEditingController();
  final unitController = TextEditingController();

  void addItem(AppState app) {
    final name = nameController.text.trim();
    if (name.isEmpty) return;

    final quantity = double.tryParse(
          quantityController.text.trim().replaceAll(',', '.'),
        ) ??
        0;
    final unit = unitController.text.trim();

    app.addShoppingItem(name, quantity: quantity, unit: unit);

    nameController.clear();
    quantityController.clear();
    unitController.clear();
  }

  @override
  void dispose() {
    nameController.dispose();
    quantityController.dispose();
    unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppState>(context);
    final sortedList = app.shoppingList.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lista della spesa',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 29, 102, 34),
            fontFamily: 'serif',
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: Row(
              children: [
                SizedBox(
                  width: 64,
                  child: TextField(
                    controller: quantityController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      labelText: 'Qtà',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 72,
                  child: TextField(
                    controller: unitController,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      labelText: 'Unità',
                      hintText: 'g, ml…',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: nameController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Prodotto',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    onSubmitted: (_) => addItem(app),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                  ),
                  icon: const Icon(Icons.add),
                  onPressed: () => addItem(app),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ElevatedButton.icon(
              onPressed: app.generateShoppingListFromMealPlan,
              icon: const Icon(Icons.auto_fix_high),
              label: const Text('Genera dal meal plan'),
            ),
          ),
          Expanded(
            child: sortedList.isEmpty
                ? const Center(child: Text('Lista vuota'))
                : ListView.builder(
                    itemCount: sortedList.length,
                    itemBuilder: (context, index) {
                      final item = sortedList[index];

                      return CheckboxListTile(
                        title: Text(
                          item.displayText,
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
