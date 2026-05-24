import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/pantry_item.dart';
import '../providers/app_state.dart';
import 'pantry_form_screen.dart';

class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppState>(context);

    final filteredPantry = app.pantry.where((item) {
      final query = _searchQuery.toLowerCase();
      return item.name.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query);
    }).toList();

    final expired = filteredPantry.where((e) => e.isExpired).toList();

    final expiring = filteredPantry.where(
      (e) => e.isExpiringSoon && !e.isExpired,
    ).toList();

    final others = filteredPantry.where(
      (e) => !e.isExpired && !e.isExpiringSoon,
    ).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Dispensa')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Cerca prodotto o categoria',
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
                      MaterialPageRoute(
                        builder: (_) => const PantryFormScreen(),
                      ),
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
                    ? const Center(
                        child: Text('Nessun prodotto trovato per questa ricerca'),
                      )
                    : ListView(
                        padding: const EdgeInsets.only(bottom: 16),
                        children: [
                          if (expired.isNotEmpty)
                            pantrySection(
                              title: 'Prodotti scaduti',
                              color: Colors.red,
                              icon: Icons.dangerous,
                              items: expired,
                              app: app,
                            ),
                          if (expiring.isNotEmpty)
                            pantrySection(
                              title: 'Prodotti in scadenza',
                              color: Colors.orange,
                              icon: Icons.warning,
                              items: expiring,
                              app: app,
                            ),
                          if (others.isNotEmpty)
                            pantrySection(
                              title: 'Altri prodotti',
                              color: Colors.green,
                              icon: Icons.inventory_2,
                              items: others,
                              app: app,
                            ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget pantrySection({
    required String title,
    required Color color,
    required IconData icon,
    required List<PantryItem> items,
    required AppState app,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...items.map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.name),
                  subtitle: Text(
                    '${item.quantity} ${item.unit} • ${item.category}'
                    '${item.expiryDate != null ? ' • ${item.isExpired ? 'Scaduto' : 'Scade'}: ${DateFormat('dd/MM/yyyy').format(item.expiryDate!)}' : ''}',
                  ),
                  leading: CircleAvatar(
                    backgroundColor: color,
                    child: Icon(icon, color: color),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => app.deletePantryItem(item.id),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}