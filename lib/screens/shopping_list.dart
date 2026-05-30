import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/pantry_item.dart';
import '../providers/app_state.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final nameController = TextEditingController();
  final quantityController = TextEditingController();
  
  // 1. LA VARIABILE DI STATO PER LA TENDINA
  String selectedUnit = 'pz';

  // 2. LE UNITÀ CONSENTITE
  static const allowedUnits = [
    'g', 'kg', 'ml', 'L', 'pz', 'oz', 'lb', 
    'cucchiaio', 'tazza', 'bustina', 'a piacere', 'Altro'
  ];

  void addItem(AppState app) {
    final name = nameController.text.trim();
    if (name.isEmpty) return;

    final quantity = double.tryParse(
          quantityController.text.trim().replaceAll(',', '.'),
        ) ??
        0;

    // 3. SALVATAGGIO USANDO IL VALORE DELLA TENDINA
    app.addShoppingItem(name, quantity: quantity, unit: selectedUnit);

    nameController.clear();
    quantityController.clear();
    setState(() {
      selectedUnit = 'pz'; // Reset della tendina dopo l'invio
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    quantityController.dispose();
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
              crossAxisAlignment: CrossAxisAlignment.start, // Allineamento per il dropdown
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
                
                // 4. IL MENU A TENDINA (Sostituisce il TextField)
                SizedBox(
                  width: 90,
                  child: DropdownButtonFormField<String>(
                    value: selectedUnit,
                    decoration: const InputDecoration(
                      labelText: 'Unità',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    ),
                    isExpanded: true,
                    items: allowedUnits.map((String u) {
                      return DropdownMenuItem<String>(
                        value: u,
                        child: Text(u, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedUnit = newValue;
                        });
                      }
                    },
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
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: app.shoppingList.isEmpty
                        ? null
                        : app.selectAllShoppingItems,
                    icon: const Icon(Icons.select_all),
                    label: const Text('Seleziona tutti'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: app.shoppingList.any((item) => item.purchased)
                        ? app.deleteSelectedShoppingItems
                        : null,
                    icon: const Icon(Icons.delete_sweep),
                    label: const Text('Elimina selezionati'),
                  ),
                ),
              ],
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
                          icon: const Icon(Icons.delete, color: Color.fromARGB(255, 29, 102, 34),),
                          onPressed: () {
                            showAddToPantryDialog(
                              context,
                              app,
                              item,
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> showAddToPantryDialog(
    BuildContext context,
    AppState app,
    dynamic item, // ShoppingItem
  ) async {
    final categoryController = TextEditingController();
    final notesController = TextEditingController();

    final dialogQuantityController = TextEditingController(
      text: item.quantity > 0 ? item.quantity.toString() : '1'
    );
    
    String dialogSelectedUnit = allowedUnits.contains(item.unit) ? item.unit : 'pz';

    DateTime? expiryDate; 

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Aggiungere in dispensa?'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 18),
                    
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: dialogQuantityController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                            decoration: const InputDecoration(
                              labelText: 'Qtà',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<String>(
                            value: dialogSelectedUnit,
                            decoration: const InputDecoration(
                              labelText: 'Unità',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                            ),
                            isExpanded: true,
                            items: allowedUnits.map((String u) {
                              return DropdownMenuItem<String>(
                                value: u,
                                child: Text(u, overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setDialogState(() {
                                  dialogSelectedUnit = newValue;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: categoryController,
                      decoration: const InputDecoration(
                        labelText: 'Categoria',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Note',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Data di scadenza'),
                      subtitle: Text(
                        expiryDate != null 
                            ? '${expiryDate!.day}/${expiryDate!.month}/${expiryDate!.year}'
                            : 'Nessuna scadenza impostata',
                        style: TextStyle(
                          color: expiryDate != null ? Colors.black87 : Colors.grey[600],
                          fontWeight: expiryDate != null ? FontWeight.normal : FontWeight.w500,
                        ),
                      ),
                      trailing: Icon(
                        Icons.calendar_month, 
                        color: expiryDate != null ? Theme.of(context).colorScheme.primary : Colors.grey
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                          initialDate: expiryDate ?? DateTime.now(),
                        );

                        if (picked != null) {
                          setDialogState(() {
                            expiryDate = picked;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    app.deleteShoppingItem(item.id);
                    Navigator.pop(context);
                  },
                  child: const Text('Solo elimina'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final finalQuantity = double.tryParse(
                      dialogQuantityController.text.trim().replaceAll(',', '.')
                    ) ?? 1.0;

                    app.addPantryItem(
                      PantryItem(
                        id: DateTime.now().microsecondsSinceEpoch.toString(),
                        name: item.name,
                        category: categoryController.text.trim().isEmpty
                            ? 'Altro'
                            : categoryController.text.trim(),
                        quantity: finalQuantity, 
                        unit: dialogSelectedUnit, 
                        expiryDate: expiryDate, 
                        notes: notesController.text.trim(),
                      ),
                    );

                    app.deleteShoppingItem(item.id);
                    Navigator.pop(context);
                  },
                  child: const Text('Aggiungi'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}