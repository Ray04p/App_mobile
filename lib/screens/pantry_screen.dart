import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/app_state.dart';
import 'pantry_form_screen.dart';

// 1. Convertito in StatefulWidget per gestire lo stato della barra di ricerca
class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  // Variabile che memorizza il testo inserito dall'utente
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppState>(context);

    // Filtro
    final filteredPantry = app.pantry.where((item) { //uso di una funzione anonima
      final query = _searchQuery.toLowerCase();
      final nameMatches = item.name.toLowerCase().contains(query);
      return nameMatches;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Dispensa')),

      body: Column(
        children: <Widget>{
          // Il TextField per la ricerca
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Cerca prodotto',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
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
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PantryFormScreen()),
                    );
                  },
                ),
              ],
            ),
          ),

          Expanded(
            child: app.pantry.isEmpty
                ? const Center(child: Text('Nessun prodotto in dispensa'))
                : filteredPantry.isEmpty
                    ? const Center(child: Text('Nessun prodotto trovato per questa ricerca'))
                    : ReorderableListView.builder(
                        itemCount: filteredPantry.length,
                        buildDefaultDragHandles: false,
                        onReorder: (oldIndex, newIndex) {
                          // Si può riordinare solo se non stiamo filtrando
                          if (_searchQuery.isEmpty) {
                            app.reorderPantryItems(oldIndex, newIndex);
                          }
                        },
                        itemBuilder: (context, index) {
                          // Usiamo .elementAt(index) sulla lista filtrata
                          final item = filteredPantry.elementAt(index);
                          
                          return Card(
                            key: ValueKey(item.id),
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: ListTile(
                              title: Text(item.name),
                              subtitle: Text(
                                '${item.quantity} ${item.unit} • ${item.category}'
                                '${item.expiryDate != null ? ' • ${item.isExpired ? 'Scaduto' : 'Scade'}: ${DateFormat('dd/MM/yyyy').format(item.expiryDate!)}' : ''}',
                              ),
                              leading: Icon(
                                item.isExpired
                                    ? Icons.dangerous 
                                    : item.isExpiringSoon
                                        ? Icons.warning 
                                        : Icons.remove_circle_outline,
                                color: item.isExpired
                                    ? Colors.red
                                    : item.isExpiringSoon
                                        ? Colors.orange
                                        : null,
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>{

                                  if (_searchQuery.isEmpty)
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
                                }.toList(),
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
          ),
        }.toList(), //widget vuole una rista come ritorno
      ),
    );
  }
}