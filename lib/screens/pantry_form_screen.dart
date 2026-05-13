import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/pantry_item.dart';
import '../providers/app_state.dart';

class PantryFormScreen extends StatefulWidget {
  final PantryItem? item;

  const PantryFormScreen({super.key, this.item});

  @override
  State<PantryFormScreen> createState() => _PantryFormScreenState();
}

class _PantryFormScreenState extends State<PantryFormScreen> {
  final formKey = GlobalKey<FormState>();

  late TextEditingController name;
  late TextEditingController category;
  late TextEditingController quantity;
  late TextEditingController unit;
  late TextEditingController notes;

  DateTime? expiryDate;

  @override
  void initState() {
    super.initState();

    final item = widget.item;

    name = TextEditingController(text: item?.name ?? '');
    category = TextEditingController(text: item?.category ?? '');
    quantity = TextEditingController(text: item?.quantity.toString() ?? '');
    unit = TextEditingController(text: item?.unit ?? '');
    notes = TextEditingController(text: item?.notes ?? '');
    expiryDate = item?.expiryDate;
  }

  Future<void> pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2035),
      initialDate: expiryDate ?? DateTime.now(),
    );

    if (date != null) {
      setState(() => expiryDate = date);
    }
  }

  void save() {
    if (!formKey.currentState!.validate()) return;

    final item = PantryItem(
      id: widget.item?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.text,
      category: category.text,
      quantity: double.tryParse(quantity.text) ?? 0,
      unit: unit.text,
      expiryDate: expiryDate,
      notes: notes.text,
    );

    final app = Provider.of<AppState>(context, listen: false);

    if (widget.item == null) {
      app.addPantryItem(item);
    } else {
      app.updatePantryItem(item);
    }

    Navigator.pop(context);
  }

  Widget field(String label, TextEditingController controller,
      {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Campo obbligatorio';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.item != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Modifica prodotto' : 'Nuovo prodotto'),
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            field('Nome prodotto', name),
            field('Categoria', category),
            field('Quantità', quantity, type: TextInputType.number),
            field('Unità di misura', unit),
            field('Note', notes),
            OutlinedButton.icon(
              onPressed: pickDate,
              icon: const Icon(Icons.calendar_month),
              label: Text(
                expiryDate == null
                    ? 'Scegli data di scadenza'
                    : 'Scadenza selezionata',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: save,
              icon: const Icon(Icons.save),
              label: const Text('Salva'),
            ),
          ],
        ),
      ),
    );
  }
}