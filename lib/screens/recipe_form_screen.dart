import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/recipe.dart';
import '../providers/app_state.dart';

class RecipeFormScreen extends StatefulWidget {
  final Recipe? recipe;

  const RecipeFormScreen({super.key, this.recipe});

  @override
  State<RecipeFormScreen> createState() => _RecipeFormScreenState();
}

class _RecipeFormScreenState extends State<RecipeFormScreen> {
  final formKey = GlobalKey<FormState>();

  late TextEditingController name;
  late TextEditingController description;
  late TextEditingController category;
  late TextEditingController time;
  late TextEditingController difficulty;
  late TextEditingController portions;
  late TextEditingController ingredients;
  late TextEditingController notes;

  @override
  void initState() {
    super.initState();

    final r = widget.recipe;

    name = TextEditingController(text: r?.name ?? '');
    description = TextEditingController(text: r?.description ?? '');
    category = TextEditingController(text: r?.category ?? '');
    time = TextEditingController(text: r?.preparationTime.toString() ?? '');
    difficulty = TextEditingController(text: r?.difficulty ?? '');
    portions = TextEditingController(text: r?.portions.toString() ?? '');
    ingredients = TextEditingController(text: r?.ingredients.join(', ') ?? '');
    notes = TextEditingController(text: r?.notes ?? '');
  }

  void save() {
    if (!formKey.currentState!.validate()) return;

    final recipe = Recipe(
      id: widget.recipe?.id,
      name: name.text,
      description: description.text,
      category: category.text,
      preparationTime: int.tryParse(time.text) ?? 0,
      difficulty: difficulty.text,
      portions: int.tryParse(portions.text) ?? 1,
      ingredients: ingredients.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      notes: notes.text,
    );

    final app = Provider.of<AppState>(context, listen: false);

    if (widget.recipe == null) {
      app.addRecipe(recipe);
    } else {
      app.updateRecipe(recipe);
    }

    Navigator.pop(context);
  }

  Widget field(String label, TextEditingController controller,
      {TextInputType type = TextInputType.text, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        maxLines: maxLines,
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
    final isEdit = widget.recipe != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Modifica ricetta' : 'Nuova ricetta'),
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            field('Nome', name),
            field('Descrizione / procedimento', description, maxLines: 4),
            field('Categoria', category),
            field('Tempo preparazione', time, type: TextInputType.number),
            field('Difficoltà', difficulty),
            field('Porzioni', portions, type: TextInputType.number),
            field('Ingredienti separati da virgola', ingredients, maxLines: 3),
            field('Note', notes, maxLines: 2),
            const SizedBox(height: 8),
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