import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import '../models/recipe.dart';
import '../models/recipe_ingredient.dart';
import '../providers/app_state.dart';

// Classe di supporto per gestire i controller di ogni singola riga
class IngredientRow {
  final TextEditingController nameController;
  final TextEditingController quantityController;
  String selectedUnit; // Non è più un controller, ma una stringa fissa

  // La lista delle unità consentite come costante statica
  static const allowedUnits = [
    'g', 'kg', 'ml', 'L', 'pz', 'oz', 'lb', 
    'cucchiaio', 'tazza', 'bustina', 'a piacere', 'Altro'
  ];

  IngredientRow({String name = '', String quantity = '', String unit = ''})
      : nameController = TextEditingController(text: name),
        quantityController = TextEditingController(text: quantity),
        // Programmazione difensiva: se modifichiamo una vecchia ricetta con
        // un'unità non valida (es. "grammi"), impostiamo di default "Altro" o "g"
        // per evitare il crash del Dropdown.
        selectedUnit = allowedUnits.contains(unit) 
            ? unit 
            : (unit.isEmpty ? 'g' : 'Altro');

  void dispose() {
    nameController.dispose();
    quantityController.dispose();
  }
}

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
  late TextEditingController notes;
  String? imagePath;
  int selectedHours = 0;
  int selectedMinutes = 0;

  final List<IngredientRow> _ingredientRows = [];



  @override
  void initState() {
    super.initState();

    final r = widget.recipe;

    name = TextEditingController(text: r?.name ?? '');
    description = TextEditingController(text: r?.description ?? '');
    category = TextEditingController(text: r?.category ?? '');
    final totalMinutes = r?.preparationTime ?? 0;
    selectedHours = totalMinutes ~/ 60;
    selectedMinutes = totalMinutes % 60;
    time = TextEditingController(text: totalMinutes.toString());
    difficulty = TextEditingController(text: r?.difficulty ?? 'Facile');
    portions = TextEditingController(text: r?.portions.toString() ?? '');
    notes = TextEditingController(text: r?.notes ?? '');
    imagePath = r?.imagePath;

    // POPOLAMENTO DEGLI INGREDIENTI
    if (r != null && r.ingredients.isNotEmpty) {
      for (var ing in r.ingredients) {
        _ingredientRows.add(IngredientRow(
          name: ing.name,
          quantity: ing.quantity > 0 ? ing.quantity.toString() : '',
          unit: ing.unit,
        ));
      }
    } else {
      // Inizia con una riga vuota se è una nuova ricetta
      _addIngredientRow();
    }
  }

  @override
  void dispose() {
    for (var row in _ingredientRows) {
      row.dispose();
    }
    super.dispose();
  }

  void _addIngredientRow() {
    setState(() {
      _ingredientRows.add(IngredientRow());
    });
  }

  void _removeIngredientRow(int index) {
    setState(() {
      if (_ingredientRows.length > 1) {
        _ingredientRows[index].dispose();
        _ingredientRows.removeAt(index);
      }
    });
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        imagePath = image.path;
      });
    }
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;

    // Estrazione dei dati strutturati dalle righe dinamiche
    List<RecipeIngredient> parsedIngredients = [];
    for (var row in _ingredientRows) {
      final ingName = row.nameController.text.trim();
      if (ingName.isNotEmpty) {
        parsedIngredients.add(RecipeIngredient(
          name: ingName,
          quantity: double.tryParse(row.quantityController.text.trim()) ?? 0.0,
          unit: row.selectedUnit,
        ));
      }
    }

    final recipe = Recipe(
      id: widget.recipe?.id,
      name: name.text.trim(),
      description: description.text.trim(),
      category: category.text.trim(),
      preparationTime: (selectedHours * 60) + selectedMinutes,
      difficulty: difficulty.text.trim(),
      portions: int.tryParse(portions.text.trim()) ?? 1,
      ingredients: parsedIngredients, // IL DATO PULITO
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
        SnackBar(content: Text('Errore salvataggio: $e')),
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
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        inputFormatters: type == TextInputType.number
        ? [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))] // Permette i decimali
        : null,
        textInputAction: action,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: type == TextInputType.number ? 'Es: 100' : null,
          labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          floatingLabelStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
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
        title: Text(isEdit ? 'Modifica ricetta' : 'Nuova ricetta',
          style: const TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 29, 102, 34),
            fontFamily: 'serif'
          ),
        ),
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            field('Nome', name),
            field('Descrizione / procedimento', description, maxLines: 4),
            field('Categoria', category),

            const SizedBox(height: 10),
            const Text('Tempo di preparazione', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: selectedHours,
                    decoration: const InputDecoration(labelText: 'Ore', border: OutlineInputBorder()),
                    items: List.generate(13, (index) => DropdownMenuItem(value: index, child: Text('$index h'))),
                    onChanged: (value) => setState(() => selectedHours = value ?? 0),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: selectedMinutes,
                    decoration: const InputDecoration(labelText: 'Minuti', border: OutlineInputBorder()),
                    items: [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55]
                        .map((m) => DropdownMenuItem(value: m, child: Text('$m min')))
                        .toList(),
                    onChanged: (value) => setState(() => selectedMinutes = value ?? 0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),

            const Text('Difficoltà', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: ['Facile', 'Media', 'Difficile'].map((diff) {
                return ChoiceChip(
                  label: Text(diff),
                  selected: difficulty.text == diff,
                  onSelected: (_) => setState(() => difficulty.text = diff),
                );
              }).toList(),
            ),
            const SizedBox(height: 30),

            field('Porzioni', portions, type: TextInputType.number),

            
            const Text("Ingredienti", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ..._ingredientRows.asMap().entries.map((entry) {
              int index = entry.key;
              IngredientRow row = entry.value;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: field('Nome', row.nameController),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: field('Qtà', row.quantityController, type: TextInputType.number, validator: (v) => null), // Validatore disattivato qui per flessibilità
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: DropdownButtonFormField<String>(
                        initialValue: row.selectedUnit,
                        decoration: InputDecoration(
                          labelText: 'Unità',
                          labelStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 18,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        isExpanded: true, // Evita errori di rendering se il testo è lungo
                        items: IngredientRow.allowedUnits.map((String u) {
                          return DropdownMenuItem<String>(
                            value: u,
                            child: Text(u, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              row.selectedUnit = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () => _removeIngredientRow(index),
                  ),
                ],
              );
            }),
            TextButton.icon(
              onPressed: _addIngredientRow,
              icon: const Icon(Icons.add),
              label: const Text("Aggiungi Ingrediente"),
            ),

            const SizedBox(height: 12),
            field('Note', notes, maxLines: 2, validator: (value) => null),

            OutlinedButton.icon(
              onPressed: pickImage,
              icon: const Icon(Icons.image),
              label: Text(imagePath == null ? 'Aggiungi foto ricetta' : 'Cambia foto'),
            ),
            
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async => await save(),
              icon: const Icon(Icons.save),
              label: const Text('Salva'),
            ),
          ],
        ),
      ),
    );
  }
}