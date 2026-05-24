import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../models/recipe.dart';
import '../models/ingredients.dart';
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
  String? imagePath;

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
    ingredients = TextEditingController(
      text: r?.ingredients.map((e) => e.displayText).join(', ') ?? '',
    );
    notes = TextEditingController(text: r?.notes ?? '');
    imagePath = r?.imagePath;
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();

    final image = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (image != null) {
      setState(() {
        imagePath = image.path;
      });
    }
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;

    final recipe = Recipe(
      id: widget.recipe?.id,
      name: name.text.trim(),
      description: description.text.trim(),
      category: category.text.trim(),
      preparationTime: int.tryParse(time.text.trim()) ?? 0,
      difficulty: difficulty.text.trim(),
      portions: int.tryParse(portions.text.trim()) ?? 1,
      ingredients: ingredients.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .map((e) {
          final parts = e.split(' ');

          if (parts.length >= 3) {
            final quantity = double.tryParse(parts[0]) ?? 1;
            final unit = parts[1];
            final name = parts.sublist(2).join(' ');

            return RecipeIngredient(
              name: name,
              quantity: quantity,
              unit: unit,
            );
          }

          return RecipeIngredient(
            name: e,
            quantity: 1,
            unit: 'pz',
          );
        })
        .toList(),
          notes: notes.text.trim(),
          imagePath: imagePath,
          isRecommended: widget.recipe?.isRecommended ?? false,
          isFavorite: widget.recipe?.isFavorite ?? false,
        );

    final app = Provider.of<AppState>(context, listen: false);

    try {
      if (widget.recipe == null) {
        await app.addRecipe(recipe);
      } else {
        await app.updateRecipe(recipe);
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore salvataggio: $e'),
        ),
      );
    }
  }

  Widget field(
    String label, 
    TextEditingController controller,{
    TextInputType type = TextInputType.text, int maxLines = 1,
    TextInputAction action = TextInputAction.next,
    String? Function(String?)? validator}) {
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        textInputAction: action, //per andare da capo
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: validator ?? (value) {
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
            field('Ingredienti: es. 200 g pasta, 2 pz uova',
              ingredients,
              maxLines: 3,
            ),
            field('Note', notes, maxLines: 2,
              validator: (value) => null,),

           

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: pickImage,
              icon: const Icon(Icons.image),
              label: Text(
                imagePath == null ? 'Aggiungi foto ricetta' : 'Cambia foto',
              ),
            ),
            
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async {
                await save();
              },
              icon: const Icon(Icons.save),
              label: const Text('Salva'),
            ),
          ],
        ),
      ),
    );
  }
}