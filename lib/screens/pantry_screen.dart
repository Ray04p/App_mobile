import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/app_state.dart';
import 'pantry_form_screen.dart';

class PantryScreen extends StatelessWidget {
  const PantryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Dispensa')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PantryFormScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: app.pantry.isEmpty
          ? const Center(child: Text('Nessun prodotto in dispensa'))
          //  Uso del ReorderableListView invece di ListView
          : ReorderableListView.builder(
              itemCount: app.pantry.length,

              buildDefaultDragHandles:
                  false, //per gestire manulmente il posizionamento
              onReorder: (oldIndex, newIndex) {
                app.reorderPantryItems(oldIndex, newIndex);
              },

              itemBuilder: (context, index) {
                final item = app.pantry[index];

                return Card(
                  key: ValueKey(
                    item.id,
                  ), //uso della chiave per gestire lo scambio di posizione
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    title: Text(item.name),
                    subtitle: Text(
                      '${item.quantity} ${item.unit} • ${item.category}'
                      '${item.expiryDate != null ? ' • Scade: ${DateFormat('dd/MM/yyyy').format(item.expiryDate!)}' : ''}',
                    ),
                    leading: Icon(
                      item.isExpiringSoon
                          ? Icons.warning
                          : item.isLowStock
                          ? Icons.remove_circle_outline
                          : Icons.inventory,
                      color: item.isExpiringSoon ? Colors.orange : null,
                    ),

                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icona per spostare gli elementi
                        ReorderableDragStartListener(
                          index: index,
                          child: const Padding(
                            padding: EdgeInsets.only(right: 8.0),
                            child: Icon(Icons.drag_handle, color: Colors.grey),
                          ),
                        ),

                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => app.deletePantryItem(item.id),
                        ),
                      ],
                    ),

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PantryFormScreen(item: item),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
